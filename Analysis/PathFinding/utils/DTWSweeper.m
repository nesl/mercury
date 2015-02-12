classdef DTWSweeper < handle
    % Differ from former DTW function, DTWSweeper only process one number
    % in the second series, which suppose to be height from barometer, at
    % one time, which equivalent to process only one column of the dp
    % table.
    %
    % DTWSweeper provides two compuatation mode: cacheable or non-cacheable.
    % Since DTW algorithm itself uses bottom-up dynamic programming, the
    % it only needs the previous column to generate the new column. Thus in
    % non-cacheable mode (by default), it always keep 2 columns only. The
    % cacheable mode is equivalent to the former DTW version.
    %
    % DTWSweeper also provides back-tracking functionaility, but only
    % applies on cacheable mode.
    %
    % By default, DTWSweeper doesn't allow gps-only transition when
    % computing DTW. Though not recommended, DTWSweeper provides an option
    % to add this transition back.
    
    
    % About the transition:  (follows the matlab array directions)
    %
    %                         2nd dim, barometer (b / bIdx)
    %               =======================================>>
    %             ||
    %             ||           2nd        *3rd*
    %             ||           (s, b)     (s, b+1)
    %   1st dim,  ||                 \       .
    %   segment   ||                  \      .
    %  (s / sIdx) ||                   \     .
    %             ||      1st           v    v
    %             ||      (s+1, b) ----> (s+1, b+1)
    %             ||            
    %             \/
    %                      at the state your comparing seg(s) with baro(b)
    %
    %  The dot arrow is the gps-only transition.
    %
    
    
    % About the pruningFunction: Assume we are processing ith element of
    % barometer series. If we are on the right path, then the minimum value
    % of this column should be bound below pruningFunction(i). Once it
    % exceeds the pruning threshold, any processNext() will have no
    % function (returns inf only).
    
    properties (SetAccess = public, GetAccess = public)
        % NOTE: as usual, the access is open for debugging purpose. As
        % usual, in regular case all the variables shouldn't be accessed
        % directly.
        
        % first series and related attribute
        height_from_seg;   % should take this variable as constant. don't change it and we'll avoid memory copying.
        num_elements_seg;
        
        % parameters
        cost_function;
        pruning_function;
        is_cacheable;
        gps_only_transition_allowed;
        
        % processing
        dp;  % it will be allocated on demand, as the testing result shows it's just 2x slower then pre-allocation
        from;  % so does from
        baro_element_cnt = 0;
        already_pruned = 0;
    end
    
    methods
        % CONSTRUCTOR
        function obj = DTWSweeper(height_from_seg, costFunction, pruningFunction, isCacheable, gpsOnlyTransition)
            obj.height_from_seg = height_from_seg;
            obj.num_elements_seg = numel(height_from_seg);
            obj.cost_function = costFunction;
            obj.pruning_function = pruningFunction;
            obj.is_cacheable = isCacheable;
            obj.gps_only_transition_allowed = gpsOnlyTransition;
            obj.dp = inf(obj.num_elements_seg+1, 2);
            obj.dp(1, 1) = 0;
            obj.from = inf(obj.num_elements_seg+1, 2);
        end
        
        % PROCESSING
        % process one value at a time
        function lastScoreInColumn = processNext(obj, nextHeightBaro)
            % if is already pruned, then sorry just return
            if obj.already_pruned
                return;
            end
            
            obj.baro_element_cnt = obj.baro_element_cnt + 1;
            
            % decide the index of barometer dimension in dp table (since non-cacheable mode doesn't keep the whole thing)
            if obj.is_cacheable == 0
                bIdx = 1;
            else
                bIdx = obj.baro_element_cnt + 1;
            end
            obj.dp(1, bIdx) = inf;
            
            % fast pruning, don't step on unnecessary cells
            if obj.gps_only_transition_allowed == 1
                lastSegIdx = obj.num_elements_seg;
            else
                lastSegIdx = min(obj.num_elements_seg, obj.baro_element_cnt);
            end
                
            for sIdx = 1:lastSegIdx
                candidates = [ obj.dp(sIdx+1, bIdx) obj.dp(sIdx, bIdx) inf ];
                if obj.gps_only_transition_allowed == 1
                    candidates(3) = obj.dp(sIdx, bIdx+1);
                end
                [obj.dp(sIdx, bIdx), obj.from(sIdx, bIdx)] = min(candidates);
                obj.dp(sIdx, bIdx) = obj.dp(sIdx, bIdx) + obj.cost_function( obj.height_from_seg(sIdx) - nextHeightBaro);
            end
            lastScoreInColumn = obj.dp(end, end);
            
            % pruning checking
            if min(obj.dp(:,bIdx)) > obj.pruning_function(obj.baro_element_cnt)
                obj.already_pruned = 1;
                lastScoreInColumn = inf;
            end
            
            % housekeeping for non-cacheable mode
            if obj.is_cacheable == 0
                obj.dp(:,1) = obj(:,2);
            end
        end
        
        % process several values in order
        function lastScores = processBatch(obj, nextHeightsBaro)
            numElements = numel(nextHeightsBaro);
            lastScores = zeros(1, numElements);
            for i = 1:numElements
                lastScores(i) = obj.processnext(nextHieghtsBaro(i));
            end
        end

        % BACK-TRACKING
        % remember we're interested to map barometer index (2nd dimension)
        % to segment index (1st dimension only)
        function path = backTracking(obj)
            if obj.is_cacheable == 0
                error('backTracking() is only possible under cacheable mode');
            end
            
            % if is pruned already, then return
            if obj.already_pruned
                path = [];
                return;
            end
            
            % each barometer index can map to one or more segment indices
            maxMappedIdx = zeros(1, obj.baro_element_cnt);  % upper simply means 
            minMappedIdx = ones(1, obj.baro_element_cnt) * obj.num_elements_seg;

            % back-tracking steps
            backSteps = [
                0  -1
               -1  -1
            ];
            if obj.gps_only_transition_allowed == 1
                backSteps(3, :) = [-1, 0];
            end
        
            sIdx = obj.num_elements_seg + 1;
            bIdx = obj.baro_element_cnt + 1;
            %[eind bind]
            while sIdx > 1 || bIdx > 1
                maxMappedIdx(bIdx-1) = max(maxMappedIdx(bIdx-1), sIdx-1);
                minMappedIdx(bIdx-1) = min(minMappedIdx(bIdx-1), sIdx-1);
                tmpFrom = obj.from(sIdx, bIdx);
                sIdx = sIdx + backSteps(tmpFrom, 1);
                bIdx = bIdx + backSteps(tmpFrom, 2);
                %[eind bind]
            end
            path = round( (maxMappedIdx(1:end) + minMappedIdx(1:end)) / 2 );
        end
    end
    
end

