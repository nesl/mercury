classdef SubSegmentDTWHandler < handle
    % This is an extension of former all_pair_dtw_baro.m function. It has
    % all the functionality of the former function, but integrate the
    % pruning mechanism. Also, it's provides the flexibility to specify the
    % cost function.
    %
    % Each SubSegmentDTWHandler handles one segment in the map. It allows
    % to query from any sub-segment of 2nd series, which supposes to be
    % elevation series from barometer.
    %
    % Features in this class:
    %   - calculate on demand
    %   - allow to specify to enable/disable cache (see constructor)
    %   - allow to change cost function
    %   - provide
    
    properties (SetAccess = public, GetAccess = public)
        % NOTE: as usual, the access is open for debugging purpose. As
        % usual, in regular case all the variables shouldn't be accessed
        % directly.
        
        % naming tip: suffix seg refers to data extracted from elevation from google API or related.
        %             suffix baro refers to data extracted from barometer sensor pr related.
        
        % The two series to be compared
        height_from_seg;    % don't change values of these two variables as they'll become passing-by-reference
        height_from_baro;
        
        % attributes of two series
        num_elements_seg;
        num_elements_baro;
        
        % cost function and pruning function
        cost_function;      % please see DTWSweeper.m to see precise definition of cost_function / pruning_function
        pruning_function;
        
        % dtw options
        cacheable = 0;
        gps_only_transition_allowed = 0;
        
        % processing and result
        last_query_start_idx = 0;  % mark as haven't received any query before
        result;  % cache enabled  => a cell, each element is an array
                 % cache disabled => an array
                 % remember either case, all the result shift to index 1
                 % e.g., for start index = 3:
                 %       result(1) or result{3}(1) is DTW(seg, baro(3:3))
                 %       result(2) or result{3}(2) is DTW(seg, baro(3:4))
                 %       result(3) or result{3}(3) is DTW(seg, baro(3:5))
        
        % magic numbers for performance
        ONE_DIM_ARRAY_REALLOCATE_GROWTH_SIZE = 20;  % a trade-off between time and memory.
                                                    % for time, it reduces to 20% of no pre-allocating
                                                    % approach.
        
        % sweeper objects to handle each possible starting position of
        % baro-series.
        sweepers;  % cache enabled  => a cell of sweepers
                   % cache disabled => only one sweeper
        sweepers_visited_idx;  % cache enabled  => a cell of scalars
                               % cache disabled => a scalar
    end
    
    methods
        % CONSTRUCTOR
        function obj = SubSegmentDTWHandler(height_from_seg, height_from_baro, varargin)
            % possible options:
            %    for cost function
            %       'costFunction', funcDef => define your own cost function
            %
            %    for pruning function
            %       'pruningFunction', funcDef => define your own pruning function
            %       'disablePruning'           => never pruning by cost
            %
            %    for cost function and pruning function package
            %       'square'      => see code below. this is default option
            %       'cube'        => see code below
            %       'exponential' => see code below
            %       'exp'         => short hand of 'exponential'
            %
            %    to enable cache option
            %       'cacheable' => if this is specified, all the computed
            %                      results of sub-segments will be cached.
            %                      the default bahavior is that it only
            %                      keeps all the sub-segments share with
            %                      the same starting point. if new
            %                      sub-segment with different starting
            %                      point is queried, then it wipes out the
            %                      previous result.
            %
            %    to enable gps-only transistion in DTW
            %        'gpsOnlyTransitionAllowed' => the default transisions forbid the a barometer
            %                                      windowed-sample match to two or more locations
            %                                      in segment. specify this option provides the flexibility
            %                                      to remove this constraint, but makes the final result
            %                                      less physically realistic. use on your own risk
            
            obj.cost_function = @(x) (x .^ 2);
            obj.pruning_function = @(x) (x + 4);
            obj.height_from_seg  = height_from_seg;
            obj.height_from_baro = height_from_baro;
            obj.num_elements_seg  = numel(height_from_seg);
            obj.num_elements_baro = numel(height_from_baro);
            obj.sweepers = cell(obj.num_elements_baro, 1);  % sparse and create on demand
            
           
            for i = 1:numel(varargin)
                if strcmp(varargin{i}, 'costFunction') == 1
                    obj.cost_function = varargin{i+1};
                    i = i + 1;
                elseif strcmp(varargin{i}, 'pruningFunction') == 1
                    obj.pruning_function = varargin{i+1};
                    i = i + 1;
                elseif strcmp(varargin{i}, 'disablePruning') == 1
                    obj.pruning_function = @(x) (inf);
                elseif strcmp(varargin{i}, 'linear') == 1
                    obj.cost_function = @(x) ( abs(x) );
                    obj.pruning_function = @(x) (x + 2);
                elseif strcmp(varargin{i}, 'square') == 1
                    obj.cost_function = @(x) (x .^ 2);
                    obj.pruning_function = @(x) (x + 4);
                elseif strcmp(varargin{i}, 'cube') == 1
                    obj.cost_function = @(x) ( abs(x) .^ 3 );
                    obj.pruning_function = @(x) (x + 8);
                elseif strcmp(varargin{i}, 'exponential') == 1 || strcmp(varargin{i}, 'exp') == 1
                    obj.cost_function = @(x) ( abs(x) .^ 3);
                    obj.pruning_function = @(x) ( 0.5 * x + 7 );
                elseif strcmp(varargin{i}, 'cacheable') ==1
                    obj.cacheable = 1;
                elseif strcmp(varargin{i}, 'gpsOnlyTransitionAllowed') ==1
                    obj.gps_only_transition_allowed = 1;
                else
                    error('unrecorgnize parameter in constructor of SubSegmentDTWHandler');
                end
            end
            
            if obj.cacheable == 0   % cache disabled
                % lazy initialization on obj.result and obj.sweepers
            else
                obj.result = cell(obj.height_from_baro, 1);
                obj.sweepers = cell(obj.height_from_baro, 1);
                obj.sweepers_visited_idx = cell(obj.height_from_baro, 1);
            end
        end
        
        % QUERY
        function score = query(obj, baroStartIdx, baroEndIdx)
            % fast pruning by gps-only transition
            if obj.gps_only_transition_allowed == 0 && baroEndIdx - baroStartIdx + 1 < obj.num_elements_seg
                score = inf;
                return;
            end
            
            
            if obj.cacheable == 0 % if it is cache disabled
                if obj.last_query_start_idx ~= baroStartIdx  % the worst case, previous data is completely useless
                    fprintf('sweeper renewed %d-%d\n', baroStartIdx, baroEndIdx);
                    obj.sweepers = DTWSweeper(obj.height_from_seg, obj.cost_function, obj.pruning_function, 0, obj.gps_only_transition_allowed);
                    obj.sweepers_visited_idx = baroStartIdx - 1; % indicate that we even haven't begun to sweep
                    obj.result = zeros(obj.num_elements_seg + obj.ONE_DIM_ARRAY_REALLOCATE_GROWTH_SIZE, 1);
                end
                
                % there's some data but may need to work hard to get the target index like phd... (sweeper may haven't gone that far)
                while obj.sweepers_visited_idx < baroEndIdx
                    obj.sweepers_visited_idx = obj.sweepers_visited_idx + 1;
                    resultIdx = obj.sweepers_visited_idx - baroStartIdx + 1;
                    if numel(obj.result) < resultIdx  % if the result array short on space, allocate more
                        obj.result( resultIdx + obj.ONE_DIM_ARRAY_REALLOCATE_GROWTH_SIZE ) = 0;
                    end
                    %[resultIdx obj.sweepers_visited_idx baroStartIdx baroEndIdx obj.num_elements_baro]
                    obj.result(resultIdx) = obj.sweepers.processNext( obj.height_from_baro(obj.sweepers_visited_idx) );
                end
                
                score = obj.result(baroEndIdx - baroStartIdx + 1);
            else % if it is cache enabled
                if numel( obj.sweepers{baroStartIdx} ) == 0  % if there's no sweeper at that index
                    obj.sweepers{baroStartIdx} = DTWSweeper(obj.height_from_seg, obj.cost_function, obj.pruning_function, 0, obj.gps_only_transition_allowed);
                    obj.sweepers_visited_idx{baroStartIdx} = baroStartIdx - 1;
                    obj.result{baroStartIdx} = zeros(obj.num_elements_seg + obj.ONE_DIM_ARRAY_REALLOCATE_GROWTH_SIZE, 1);
                end
                while obj.sweepers_visited_idx{baroEndIdx} < baroEndIdx
                    obj.sweepers_visited_idx{baroEndIdx} = obj.sweepers_visited_idx{baroEndIdx} + 1;
                    resultIdx = obj.sweepers_visited_idx{baroEndIdx} - baroStartIdx + 1;
                    if numel(obj.result{baroEndIdx}) < resultIdx  % if the result array short on space, allocate more
                        obj.result{baroEndIdx}( resultIdx + obj.ONE_DIM_ARRAY_REALLOCATE_GROWTH_SIZE ) = 0;
                    end
                    obj.result{baroEndIdx}(resultIdx) = obj.sweepers{baroEndIdx}.processNext( ...
                        obj.height_from_baro( obj.sweepers_visited_idx{baroEndIdx} ) );
                end
                
                score = obj.result{baroEndIdx}(baroEndIdx - baroStartIdx + 1);
            end
            
            obj.last_query_start_idx = baroStartIdx;
        end
        
        % BACK-TRACKING
        function path = backTracking(obj, baroStartIdx, baroEndIdx)
            tmpSweeper = DTWSweeper(obj.height_from_seg, obj.cost_function, obj.pruning_function, 1, obj.gps_only_transition_allowed);
            for i = baroStartIdx:baroEndIdx
                tmpSweeper(obj.height_from_baro(i));
            end
            path = tmpSweeper.backTracking();
        end
        
        % ASSISTANCE FUNCTION
        function len = getNumElementOfSeg(obj)
            len = numel(obj.height_from_seg);
        end
    end
    
end

