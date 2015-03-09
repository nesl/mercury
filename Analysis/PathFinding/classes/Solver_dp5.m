classdef Solver_dp5 < handle
    % This class does the following thing:
    %   1. This solver no longer depends on the pre-assigned pressure
    %      parameter. Technically It tries to list all the possible ones.
    %      But we still need to give it a range of possible parameters.
    %   2. Based on DTW information, it performs search/DP algorithm to find
    %      the most likely n paths
    %   3. This solver also prune the search space based on turns
    %   4. It allows to solve arbitrary path / oracle path and put into the
    %      trajectory result list. Oracle path is a path extracted from gps
    %      data.
    %   5. It provides the function to compare with the ground-truth path.
    %   6. Parallelly solves different case (if map is small or ram is big)
    %
    % This solver list all the possible start points and perform DP
    % algorithm. It focus on exploring early pruning strategies. It
    % introduces the feature of computing on demand, so it shouldn't take
    % too much time on (all sub-segments of) DTW tasks as already being pruned.
    %
    % Summary of pruning strategies:
    %   - (time) pruning by dp score over time to time (early time has
    %         tighter pruning condition)
    %   - (correctness) Forbid go-back case
    %   - (correctness) Remove similar paths in the result
    %
    % Difference with the previous version:
    %   - Everything is the same except try to loop over different pressure
    %     parameter settings
    %   - Support parallel solving
    
    properties (SetAccess = public)
        % input uncertainty
        uncertain_meter = 5;  % correct elevation +/- this unterainty
        
        % solver looping option
        looping_elevation_step = 1.3;  % meters
        scheduler_random_start = 0;  % 0 means the first pressure setting always equal to the smallest possible offset,
                                     % whereas 1 means it shifts. All other numbers just return an exception
        use_turn_assistance = 0;  % no turn assist by default
                                     
        % about scheduler
        pressure_parameters;  % an n-by-2 array, each row is [scalar, offset]
                              % the setting is assigned when solve() is triggered only.
        num_pressure_parameters;
                            
        % associated objects
        map_data;
        sensor_data;
        
        % about the map
        map_elevs;
        map_latlngs;
        map_neighbors;
        
        % elevations from barometer; continuous turn
        elev_series_from_baro; % a cell of arrays since it's pressure parameter dependent
        driving_angle_max;  % an array
        driving_angle_min;  % an array
        
        % dtw cost functions
        dtw_cost_function = @(x) (x .^ 2);
        
        % output result / performance
        final_res_traces;  % which is always sorted
                           % a trace includes .rawPath (Nx2 matrix, which is [time nodeIdx])
                           %                  .latlng (Nx2, N equals the length of baromtere data)
                           %                  .pressureParamIdx
                           %                  .dtwScore
                           %                  .numMistakeTurns
                           %                  .finalScore (the traces are sorted based on this score, see the def. in the code)
        processing_time;
        overall_pruning_ratio_of_dtw_query;
        overall_pruning_ratio_of_dtw_elements;
                     
        % output settings
        max_results = 40;
        outputFilePath;
        
        % output assistance
        evaluator;
        
        % parameter for turn detections
        TURN_EVENT_DELAY = 5;  % barometer index, +/- slots
        
        % pruning constants
        INITIAL_ELEVATION_DIFFERENCE_SCREEN = 2; % meter
        RAW_PATH_SIMILARITY_THRESHOLD = 0.6;
        ACCEPTED_TURN_ANGLE_DIFFERENCE = 90;  % degree
        
        % pruning constants/functions
        %HARD_ELEVATION_THRESHOLD = 5; % meter, consider the nodes as check points and apply the threshold.
        global_pruning_function = @(x) (200 + 3 * x)  % during accessing x-th barometer element in the dynamic programming,
                                                       % what is the cutting threshold for corresponding column
        allowed_num_turn_mistakes = @(x) (2 + 0.34 * x)  % x is number of segments which have been visited.
        maximum_candidate_node_ratio = 0.1;
        %destropy_by_no_reason_probability = 0.5;
        group_search_across_range = 400;  % meter;
        
        % parameters for finding the oracle path
        NUM_GPS_SAMPLES_TO_ASSURE_NODE_IS_VISITED = 2;
        DISTANCE_THRESHOLD_TO_BE_CONSIDERED_AS_VISITED = 20; % meter, this constraint is very important to avoid false path
        
    end
    
    methods
        % CONSTRUCTOR
        function obj = Solver_dp5(mapData, sensorData, scheduleRandomStart)  % expected MapData and SensorData. they are passed by reference
            obj.map_data = mapData;
            obj.sensor_data = sensorData;
            obj.scheduler_random_start = scheduleRandomStart;
            obj.evaluator = Evaluator(sensorData, mapData);
        end
        
        % SEARCH PARAMETER
        function setUncertaintyRange(obj, meter)
            obj.uncertain_meter = abs(meter);
        end
        
        function useTurns(obj, varargin)
            if numel(varargin) == 0
                obj.use_turn_assistance = 1;
            elseif varargin{1}
                obj.use_turn_assistance = 1;
            else
                obj.use_turn_assistance = 0;
            end
        end
        
        % OUTPUT SETTINGS
        function obj = setOutputFilePath(obj, path)
            obj.outputFilePath = path;
        end
        
        function obj = setNumPathsToKeep(obj, num)
            obj.max_results = num;
        end
        
        % FIND THE LIKELY PATHS
        function solve(obj)
            tic
            
            if isa(obj.sensor_data, 'SensorData')
                % get possible pressure parameters
                obj.private_schedulePressureParameters();

                % initialize all the possible pressure parameters
                obj.elev_series_from_baro = cell(obj.num_pressure_parameters, 1);
                for i = 1:obj.num_pressure_parameters
                    obj.sensor_data.setPressureScalar( obj.pressure_parameters(i,1) );
                    obj.sensor_data.setSeaPressure( obj.pressure_parameters(i,2) );
                    obj.elev_series_from_baro{i} = obj.sensor_data.getElevationTimeWindow();
                end
            else
                startOffset = -obj.uncertain_meter + sum(find(obj.scheduler_random_start)) * rand() * min(obj.looping_elevation_step, 2 * obj.uncertain_meter);
                allOffset = (startOffset):(obj.looping_elevation_step):(obj.uncertain_meter);
                obj.num_pressure_parameters = numel(allOffset);
                obj.pressure_parameters = repmat(allOffset', 1, 2);
                obj.elev_series_from_baro = cell(obj.num_pressure_parameters, 1);
                for i = 1:obj.num_pressure_parameters
                    obj.elev_series_from_baro{i} = obj.sensor_data.getElevationTimeWindow() + obj.pressure_parameters(i,1);  %1st and 2nd column are the same
                end
            end
            fprintf('pressure parameters scheduled and related stuff initialized\n');
            
            numJointNodes = obj.map_data.getNumNodes();
            numElevBaro = size(obj.elev_series_from_baro{1}, 1);  % every series has the same length
            
            [obj.map_elevs, obj.map_latlngs, obj.map_neighbors] = obj.map_data.getHomogeneousMap();
            numTotalNodes = numel(obj.map_elevs);
            
            %{
            numel(obj.map_latlngs)
            clf
            hold on
            %}
            %{
            for i = 1:size(obj.map_latlngs, 1)
                plot(obj.map_latlngs(i,2), obj.map_latlngs(i,1), '.');
            end
            %}
            %{
            for i = 1:size(obj.map_neighbors, 1)
                for j = 1:numel(obj.map_neighbors{i})
                    idx = [i obj.map_neighbors{i}];
                    plot(obj.map_latlngs(idx,2), obj.map_latlngs(idx,1), '-');
                end
            end
            pause
            %}
            
            
            obj.driving_angle_max = inf(numElevBaro, 1);
            obj.driving_angle_min = -inf(numElevBaro, 1);
            if obj.use_turn_assistance
                % take turns
                turnVector = obj.sensor_data.spanTurnEventsToVector();
                obj.driving_angle_max = zeros(numElevBaro, 1);
                obj.driving_angle_min = zeros(numElevBaro, 1);

                % then, we want to specify the possible max and min angles at
                % each time points. We use sliding window approach
                for i = 1:numElevBaro
                    sidx = max(i - obj.TURN_EVENT_DELAY, 1);
                    eidx = min(i + obj.TURN_EVENT_DELAY, numElevBaro);
                    obj.driving_angle_max(i) = max( turnVector(sidx:eidx, 2) ) + obj.ACCEPTED_TURN_ANGLE_DIFFERENCE;
                    obj.driving_angle_min(i) = min( turnVector(sidx:eidx, 2) ) - obj.ACCEPTED_TURN_ANGLE_DIFFERENCE;
                end
            end
            
            candidateSetSizeThreshold = numTotalNodes * obj.maximum_candidate_node_ratio;
            
            tmpResTracesForAllPressureParameters = cell(obj.num_pressure_parameters, 1);
            for preIdx = 1:obj.num_pressure_parameters  % pressure index
                % find the possible starting points
                curTimeElevFromBaro = obj.elev_series_from_baro{preIdx};
                curElevFromBaro = curTimeElevFromBaro(:,2);
                beginElev = curElevFromBaro(1);
                tmpElevDiff = beginElev - obj.map_data.getNodeIdxsElev(1:obj.map_data.num_nodes);
                startingNodeCandidates = find( abs(tmpElevDiff) <= obj.INITIAL_ELEVATION_DIFFERENCE_SCREEN );
                remainingNodes = startingNodeCandidates;
                seedNodeIdxs = [];
                
                % group algorithm:
                %    1. Select seeds which are not within a certain range
                %    2. cluster all candidate nodes to the closest seeds
                while numel(remainingNodes) > 0
                    seedIdx = ceil(rand() * numel(remainingNodes));
                    seed = remainingNodes(seedIdx);
                    seedNodeIdxs(end+1) = seed;
                    dis = latlng2m( obj.map_latlngs(remainingNodes,:), obj.map_latlngs(seed,:) );
                    outRangeIdx = (dis > obj.group_search_across_range);
                    remainingNodes = remainingNodes(outRangeIdx);
                end
                
                dis = latlng2m( obj.map_latlngs(seedNodeIdxs,:), obj.map_latlngs(startingNodeCandidates,:) );
                [~, seedIdx] = min(dis);
                
                startGroups = cell(numel(seedNodeIdxs), 1);
                for i = 1:numel(seedNodeIdxs)
                    startGroups{i} = startingNodeCandidates( seedIdx == i );
                end
                
                fprintf('%d nodes -> %d groups\n', numel(startingNodeCandidates), numel(startGroups));
                
                tmpResTraces = [];
                for groupIdx = 1:numel(startGroups)  % for start point
                    
                    % dynamic programming
                    dp = inf(numTotalNodes, numElevBaro+1);  % dp(node idx, baro elev step)
                    dp( startGroups{groupIdx} ,1) = 0;
                    from = zeros(numTotalNodes, numElevBaro+1, 4);  % from(a, b) = [last node idx, forbid idx ,# segs visited, # of turn mistakes]
                
                    % GUIDELINE: think about we start from
                    %     dp(nIdxStart, bIdxStart) -------- consume baro data (bIdxStart:(bIdxEnd-1)) --------> dp(nIdxEnd, bIdxEnd)
                    %
                    % abbreviation: initial n stands for node, b stands for (from) barometer
                    % nIdxStart and nIdxEnd are neighbors
                    % the traveling time, or more precisely, consumption of barometer data, is (bIdxEnd - bIdxStart + 1)

                    for bIdxStart = 1:numElevBaro  % starting barometer index
                        bIdxEnd = bIdxStart+1;
                        earlyDPPruningScore = obj.global_pruning_function(bIdxStart);
                        candidateStartIdxs = find(dp(:, bIdxStart) <= earlyDPPruningScore)';  % make sure it's a row
                        if numel(candidateStartIdxs) > candidateSetSizeThreshold
                            maxScore = max(dp(candidateStartIdxs, bIdxStart));
                            minScore = min(dp(candidateStartIdxs, bIdxStart));
                            threshold = (maxScore + minScore) / 2;
                            candidateStartIdxs = candidateStartIdxs(dp(candidateStartIdxs, bIdxStart) < threshold);
                            fprintf('cut\n');
                            %pause
                        end
                        for nIdxStart = candidateStartIdxs  % starting node index
                            %[bIdxStart nIdxStart obj.elevFromBaro(bIdxStart) obj.map_data.getNodeIdxsElev(nIdxStart)]
                            %if dp(nIdxStart, bIdxStart) < earlyDPPruningScore ...     % global pruning. 
                            %        && abs(obj.elev_series_from_baro{preIdx}(bIdxStart, 2) - obj.map_data.getNodeIdxsElev(nIdxStart)) < obj.HARD_ELEVATION_THRESHOLD
                            
                            prevNodeIdx = from(nIdxStart, bIdxStart, 2);
                            
                            % self
                            nextScore = dp(nIdxStart, bIdxStart) + (obj.map_elevs(nIdxStart) - curElevFromBaro(bIdxStart)) ^ 2;
                            if nextScore < dp(nIdxStart, bIdxEnd)
                                dp(nIdxStart, bIdxEnd) = nextScore;
                                %from(nIdxEnd, bIdxEnd, :) = [nIdxStart bIdxStart, pastNumSegments+1, curNumTurnMistakes];
                                from(nIdxStart, bIdxEnd, :) = [nIdxStart  prevNodeIdx  0  0];
                            end
                            
                            % neighbors
                            for nIdxEnd = obj.map_neighbors{nIdxStart}
                                if prevNodeIdx == nIdxEnd  % next node is not previous node   <prevNodeIdx> -- <nIdxStart> -- <nIdxEnd>
                                    continue;
                                end

                                %{
                                % not sure how to integrate turns
                                % impose the turn mistake penalty
                                if prevNodeIdx ~= 0 % means we can find out the previous node
                                    % then we try to exam the turn from sensor is valid, i.e., meet the
                                    % accpeted angles reported from the map. since we need to consider
                                    % the angle space is continuous, i.e., -180 = 180 degrees,
                                    % we calculate 3 equivalent angles (i.e, -360, +0, +360)
                                    jointAngleFromMapSet = obj.map_data.getAdjacentSegmentsAngle([prevNodeIdx nIdxStart nIdxEnd]) + 360 * (-1:1);
                                    if sum(obj.driving_angle_min(bIdxStart) <= jointAngleFromMapSet & jointAngleFromMapSet <= obj.driving_angle_max(bIdxStart)) == 0 % means that all the angles are mismatched
                                        curNumTurnMistakes = curNumTurnMistakes + 1;
                                    end
                                end
                                %}
                                %if curNumTurnMistakes <= obj.allowed_num_turn_mistakes(pastNumSegments)
                                %earliestPossibleBaroIdxEnd = bIdxStart + numElementOfSeg;
                                
                                nextScore = dp(nIdxStart, bIdxStart) + (obj.map_elevs(nIdxEnd) - curElevFromBaro(bIdxStart)) ^ 2;
                                if nextScore < dp(nIdxEnd, bIdxEnd)
                                    dp(nIdxEnd, bIdxEnd) = nextScore;
                                    %from(nIdxEnd, bIdxEnd, :) = [nIdxStart bIdxStart, pastNumSegments+1, curNumTurnMistakes];
                                    from(nIdxEnd, bIdxEnd, :) = [nIdxStart  nIdxStart  0  0];
                                end
                                %end
                            end
                        end
                        fprintf('pressureParam=%.2f,%.2f group=%d/%d, time=%d\n', ...
                            obj.pressure_parameters(preIdx, 1), obj.pressure_parameters(preIdx, 2), groupIdx, numel(startGroups), bIdxStart)
                    end
            
                    % back tracking
                    for i = 1:numJointNodes
                        if dp(i, numElevBaro+1) < inf
                            tmpTrace = [];
                            tmpTrace.pressureParamIdx = preIdx;
                            tmpTrace.dtwScore = dp(i, numElevBaro+1);
                            tmpTrace.numMistakeTurns = from(i, numElevBaro+1, 3);
                            %tmpTrace.finalScore = tmpTrace.dtwScore * tmpTrace.numMistakeTurns;
                            tmpTrace.finalScore = tmpTrace.dtwScore;
                            cNodeIdx = i;  % current node index
                            cElevStep = numElevBaro+1;  % current elevation step
                            pointIds = zeros(numElevBaro, 1);
                            while cElevStep ~= 1
                                pNodeIdx = from(cNodeIdx, cElevStep, 1);  % previous node index
                                pElevStep = cElevStep - 1;  % previous elevation step
                                pointIds(pElevStep) = pNodeIdx;
                                cNodeIdx = pNodeIdx;
                                cElevStep = pElevStep;
                            end
                            tmpTrace.latlng = obj.map_latlngs(pointIds, :);
                            jointPointIdIdx = find(pointIds <= numJointNodes);
                            jointPointId = pointIds(jointPointIdIdx);
                            tmpRawPath = [ jointPointIdIdx  jointPointId ; [numElevBaro+1 i] ];
                            nonDuplicatedIdx = [true ; tmpRawPath(2:end-1,2) ~= tmpRawPath(1:end-2,2) ; true];
                            tmpTrace.rawPath = tmpRawPath(nonDuplicatedIdx, :);
                            tmpResTraces = [tmpResTraces tmpTrace];
                        end
                    end
                end
                if numel(tmpResTraces) > 0
                    tmpResTraces = nestedSortStruct(tmpResTraces, {'finalScore'});
                    numTracesToKeep = min(numel(tmpResTraces), obj.max_results);
                    tmpResTracesForAllPressureParameters{preIdx} = tmpResTraces(1:numTracesToKeep);
                end
            end
            fprintf('Finish searching. Summarize the result....\n');
            
            % join the answers
            obj.final_res_traces = [];
            for i = 1:obj.num_pressure_parameters
                obj.final_res_traces = [obj.final_res_traces tmpResTracesForAllPressureParameters{i}];
            end
            
            if numel(obj.final_res_traces) == 0
                warning('Solver didn''t find any possible path... try to relax the pruning condition');
                return;
            end
            
            obj.final_res_traces = nestedSortStruct(obj.final_res_traces, {'finalScore'});
            
            % remove similar traces
            keptTraces = [];
            for i = 1:numel(obj.final_res_traces)
                findSimilarPath = 0;
                for j = 1:numel(keptTraces)
                    if obj.private_similarityOfTwoRawPaths( ...
                            obj.final_res_traces(i).rawPath, keptTraces(j).rawPath ) >= obj.RAW_PATH_SIMILARITY_THRESHOLD
                        findSimilarPath = 1;
                        break
                    end
                end
                if findSimilarPath == 0
                    keptTraces = [keptTraces obj.final_res_traces(i)];
                end
                if i >= obj.max_results
                    break;
                end
            end
            obj.final_res_traces = keptTraces;
            
            % summarize performance
            obj.processing_time = toc;
        end
        
        function forceInsertingAPath(obj, path)  % an row vector of nodeIdxs
            error('need to update, remember try every possible parameter and pick the best one')
            % this method force the agent to walk along the specified path.
            % if there already are some result in the res_traces, the new
            % path is gauranteed to be inserted into res_traces with
            % replacing one of them.
            
            % we need to create a new dtw_helper, since we don't want to
            % involve any pruning mechanism
            dtwHelperForce = SubSegmentDTWHelper(obj.map_data, obj.elevFromBaro(:,2), obj.dtw_cost_function, @(x) (inf) );
            
            numVisitedNodes = length(path);
            numElevBaro = size(obj.elevFromBaro, 1);
            dp = inf(numVisitedNodes, numElevBaro+1);  % dp(a, b) = score of [last node_idx in sub-path, last step]
            dp(1, 1) = 0;
            from = zeros(numVisitedNodes, numElevBaro+1);  % from(a, b) = last step @ previous node_idx
            for i = 1:(numVisitedNodes-1)
                for j = 1:numElevBaro
                    for k = (j+1):(numElevBaro+1)
                        t = dtwHelperForce.query(path(i), path(i+1), j, k-1);
                        if dp(i, j) + t < dp(i+1, k)
                            dp(i+1, k) = dp(i, j) + t;
                            from(i+1, k) = j;
                        end
                    end
                end
                fprintf('pass %d-th of specified node\n', i);
            end
            
            clear tmp_trace
            tmp_trace.dtwScore = dp(end, end);
            cElevStep = numElevBaro+1;  % current elevation step
            tmp_trace.rawPath = [numElevBaro+1 path(end)];
            for i = (numVisitedNodes-1):-1:1
                cElevStep = from(i+1, cElevStep);
                tmp_trace.rawPath = [ [cElevStep path(i)] ; tmp_trace.rawPath ];
                %[cElevStep i]
            end
            if numel(obj.res_traces) >= obj.max_results
                obj.res_traces = obj.res_traces(1:(obj.max_results-1));
            end
            obj.res_traces = [obj.res_traces tmp_trace];
            obj.res_traces = nestedSortStruct(obj.res_traces, {'dtwScore'});
            for i = 1:numel(obj.res_traces)
                if size( obj.res_traces(i).rawPath, 1) == size(tmp_trace.rawPath, 1)
                    if all( obj.res_traces(i).rawPath(:,2) == tmp_trace.rawPath(:,2) )
                        fprintf('the path is inserted at rank %d\n', i);
                    end
                end
            end
        end
        
        function forceInsertingOraclePath(obj)
            gpsData = obj.sensor_data.getGps();
            numRows = size(gpsData, 1);
            closestNodeIdxs = [];
            for i = 1:numRows
                tmpNodeIdx = obj.map_data.getNearestNodeIdx( gpsData(i, 2:3) );
                tmpDis = obj.map_data.distanceToNodeIdx( gpsData(i, 2:3), tmpNodeIdx );
                if tmpDis < obj.DISTANCE_THRESHOLD_TO_BE_CONSIDERED_AS_VISITED
                    closestNodeIdxs = [closestNodeIdxs tmpNodeIdx];
                end
            end
            compactPath = [];  % an array of nodes which we are very certain we've visited
            curNodeIdx = 0;
            curCnt = 0;
            for i = 1:length(closestNodeIdxs)
                if closestNodeIdxs(i) ~= curNodeIdx
                    curNodeIdx = closestNodeIdxs(i);
                    curCnt = 0;
                end
                curCnt = curCnt + 1;
                if curCnt == obj.NUM_GPS_SAMPLES_TO_ASSURE_NODE_IS_VISITED  % not >=, as it'll be inserted multiple times
                    compactPath = [ compactPath curNodeIdx ];
                end
            end
            finalPath = obj.map_data.findApproximatePathOverMapByNodeIdxs(compactPath); 
            obj.forceInsertingAPath(finalPath);
        end
        
        % GET SCHEDULE INFORMATION
        function params = getTestedPressueParameters(obj)
            params = obj.pressure_parameters;
        end
        
        % RETRIEVE PATHS
        function num = getNumResults(obj)
            num = numel( obj.final_res_traces );
        end
        
        function rawPath = getRawPath(obj, traceIdx)
            rawPath = obj.final_res_traces(traceIdx).rawPath;
        end
        
        function dtwScore = getDTWScore(obj, traceIdx)
            dtwScore = obj.final_res_traces(traceIdx).dtwScore;
        end
        
        
        function timeLatLngs = getTimeLatLngPath(obj, traceIdx)
            tmpElevFromBaro = obj.elev_series_from_baro{1};  % we only care about time column. every series have the same timestamps
            timeLatLngs = [ tmpElevFromBaro(:,1)  obj.final_res_traces(traceIdx).latlng ];
        end
        
        % see time_gps_series_compare.m for more information
        % [ row vector ] = getPathSimilarityConsideringTime(obj)  // get up to <max_result> results
        % [ row vector ] = getPathSimilarityConsideringTime(obj, traceIdxs)
        function rmsInMeter = getPathSimilarityConsideringTime(obj, varargin) 
            indxs = 1:numel(obj.final_res_traces);
            if numel(varargin) >= 1
                indxs = varargin{1};
            end
            
            groundTruthTimeLatLngs = obj.sensor_data.getGps();
            groundTruthTimeLatLngs = groundTruthTimeLatLngs(:, 1:3);
                
            rmsInMeter = zeros(numel(indxs), 1);
            for i = indxs
                traceIdx = indxs(i);
                estimatedTimeLatLngs = obj.getTimeLatLngPath(traceIdx);
                rmsInMeter(i) = time_gps_series_compare(groundTruthTimeLatLngs, estimatedTimeLatLngs);
            end
        end
        
        % see gps_series_compare.m for more information
        % [ row vector ] = getPathShapeSimilarity(obj)  // get up to <max_result> results
        % [ row vector ] = getPathShapeSimilarity(obj, traceIdxs)
        function rmsInMeter = getPathShapeSimilarity(obj, varargin) 
            indxs = 1:min(obj.max_results, numel(obj.final_res_traces));
            if numel(varargin) >= 1
                indxs = varargin{1};
            end
            
            groundTruthTimeLatLngs = obj.sensor_data.getGps();
            groundTruthLatLngs = groundTruthTimeLatLngs(:, 2:3);
                
            rmsInMeter = zeros(numel(indxs), 1);
            for i = indxs
                traceIdx = indxs(i);
                rmsInMeter(i) = gps_series_compare(groundTruthLatLngs, obj.final_res_traces(traceIdx).latlng);
            end
        end
        
        % [ row vector ] = getPathShapeSimilarity(obj)  // get up to <max_result> results
        % [ row vector ] = getPathShapeSimilarity(obj, traceIdxs)
        function rmsInMeter = getPathShapeSimilarityBiDirection(obj, varargin) 
            indxs = 1:min(obj.max_results, numel(obj.final_res_traces));
            if numel(varargin) >= 1
                indxs = varargin{1};
            end
            
            groundTruthTimeLatLngs = obj.sensor_data.getGps();
            groundTruthLatLngs = groundTruthTimeLatLngs(:, 2:3);
                
            rmsInMeter = zeros(numel(indxs), 1);
            for i = indxs
                traceIdx = indxs(i);
                scoreGndEsti = gps_series_compare(groundTruthLatLngs, obj.final_res_traces(traceIdx).latlng);
                scoreEstiGnd = gps_series_compare(obj.final_res_traces(traceIdx).latlng, groundTruthLatLngs);
                rmsInMeter(i) = rms([scoreGndEsti scoreEstiGnd]);
            end
        end
        
        % arguments should be passed as strings, including
        % 'index', 'dtwScore' and 'squareError'
        function res = summarizeResult(obj, varargin)
            % ('pathError',  'shapeError',  'dtwScore', 'numMistakeTurns',    'seaPressure')
            numRow = numel(obj.final_res_traces);
            res = zeros(numRow, 0);
            for i = 1:numel(varargin)
                if strcmp(varargin{i}, 'index') == 1
                    res = [res (1:numRow)'];
                elseif strcmp(varargin{i}, 'dtwScore') == 1
                    tmp = zeros(numRow, 1);
                    for j = 1:numRow
                        tmp(j) = obj.final_res_traces(j).dtwScore;
                    end
                    res = [res tmp];
                elseif strcmp(varargin{i}, 'numMistakeTurns') == 1
                    tmp = zeros(numRow, 1);
                    for j = 1:numRow
                        tmp(j) = obj.final_res_traces(j).numMistakeTurns;
                    end
                    res = [res tmp];
                elseif strcmp(varargin{i}, 'seaPressure') == 1
                    tmp = zeros(numRow, 1);
                    for j = 1:numRow
                        preIdx = obj.final_res_traces(j).pressureParamIdx;
                        tmp(j) = obj.pressure_parameters(preIdx, 2);
                    end
                    res = [res tmp];
                elseif strcmp(varargin{i}, 'pathError') == 1
                    res = [ res obj.getPathSimilarityConsideringTime() ];
                elseif strcmp(varargin{i}, 'shapeError') == 1
                    res = [ res obj.getPathShapeSimilarity() ];
                elseif strcmp(varargin{i}, 'biShapeError') == 1
                    res = [ res obj.getPathShapeSimilarityBiDirection() ];
                else
                    error(['unrecognized column name ' varargin{i} ' (in resultSummarize())']);
                end
            end
        end
        
        % QUERY PERFORMANCE
        function sec = getProcessingTime(obj)
            sec = obj.processing_time;
        end
        
        function [ratioDTWQuery, ratioDTWElement] = queryPruningRatio(obj)
            ratioDTWQuery = obj.overall_pruning_ratio_of_dtw_query;
            ratioDTWElement = obj.overall_pruning_ratio_of_dtw_elements;
        end
        
        % VISUALIZATION
        function plotPathComparison(obj, tracesIdxList)
            gpsData = obj.sensor_data.getGps();  % 2:lat, 3:lon
            clf
            hold on
            plot( gpsData(:,3), gpsData(:,2), 'k*' );
            legendTexts = {'Ground'};
            for i = tracesIdxList
                estiLatLng = obj.final_res_traces(i).latlng;
                color = hsv2rgb([ rand() , 1, 0.7 ]);
                plot( estiLatLng(:,2), estiLatLng(:,1), '-', 'Color', color );
                legendTexts = { legendTexts{:} ['Rank ' num2str(i)] };
            end
            legend(legendTexts);
        end
        
        function plotElevationComparison(obj, tracesIdxList)
            error('need to be upgraded');
            % TODO: if traces are from different pressure parameters, then
            % just return an error
            clf
            hold on
            legendTexts = {};
            gps2ele = obj.sensor_data.getGps2Ele();
            if size(gps2ele, 1) == 0
                %text(0, 0, 'Sorry, but gps2ele file has not been generated');
                xlabel('Sorry, but gps2ele file has not been generated');
            else
                plot( 1:length(gps2ele(:,1)), gps2ele(:,4), 'k-');
                legendTexts = { legendTexts{:} 'from GPS traj' };
            end
            
            plot(1:length(obj.elevFromBaro(:,1)), obj.elevFromBaro(:,2), 'b-');
            legendTexts = { legendTexts{:} 'from baro' };
            
            for i = tracesIdxList
                rawPath = obj.getRawPath(i);
                tmpElev = obj.map_data.getPathElev( rawPath(:,2) );
                color = hsl2rgb([ rand() * 0.5 , 1, 0.4 ]);
                plot(1:length(tmpElev), tmpElev, '-', 'Color', color);
                legendTexts = { legendTexts{:} ['Rank ' num2str(i)] };
            end
            
            legend(legendTexts);
        end
        
        % given a trace id, show the dtw score over time
        function plotPathDTWScore(obj, traceIdx)
            error('need to be upgraded');
            % TODO: if traces are from different pressure parameters, then
            % just return an error
            clf
            
            ax1 = subplot(2, 1, 1);
            hold on
            tmpNodeIdxs = obj.getRawPath(traceIdx);
            tmpNodeIdxs = tmpNodeIdxs(:,2);
            elevFromEstPath = obj.map_data.getPathElev(tmpNodeIdxs);
            plot(1:length(elevFromEstPath), elevFromEstPath, 'b-');
            plot(1:length(obj.elevFromBaro(:,1)), obj.elevFromBaro(:,2), 'r-');
            legend('from esti traj', 'from baro');
            
            ax2 = subplot(2, 1, 2);
            [~, ~, scoreSeries] = dtw_basic(elevFromEstPath, obj.elevFromBaro(:,2), obj.dtw_cost_function, @(x) (inf));
            plot(1:length(scoreSeries), scoreSeries, 'k-');
            
            linkaxes([ax1,ax2], 'x')
        end
        
        % TO WEB
        function toWeb(obj, varargin)
            flagBeautiful = 1;
            if numel(varargin) == 1 && ~varargin{1}
                flagBeautiful = 0;
            end
            
            if isempty(obj.outputFilePath)
                error('set output file path to the solver first (in toWeb())');
            end
            
            %attributes, attributeValues, paths
            attributes      =                    {'Path error', 'Shape error', 'Bi shape error', 'DTW',      '# of mistake turns', 'Sea pressure'};
            attributeValues = obj.summarizeResult('pathError',  'shapeError',  'biShapeError',   'dtwScore', 'numMistakeTurns',    'seaPressure');
            
            numPaths = numel(obj.final_res_traces);
            paths = cell(numPaths, 1);
            for i = 1:numPaths
                paths{i} = obj.final_res_traces(i).latlng;
            end
            
            obj.evaluator.toWeb(obj.outputFilePath, flagBeautiful, attributes, attributeValues, paths);
        end
        
        
        % +-----------------+
        % | PRIVATE METHODS |
        % +-----------------+
        
        % generate pressure parameters to test
        function private_schedulePressureParameters(obj)
            % get min and max baro
            baro = obj.sensor_data.getBaro();
            
            baroScaleCandidate = -8.38; % magic number from analysis
            
            % get first baro value and elevation as calibration center
            firstBaro = mean(baro(1:15, 2));  % average the first 15 samples which is equivalent to 0.5 second
            gps2elev = obj.sensor_data.getGps2Ele();
            firstGps2elev = gps2elev(1, 4);
            minPossibleFirstElev = firstGps2elev - obj.uncertain_meter;
            maxPossibleFirstElev = firstGps2elev + obj.uncertain_meter;
            
            % loop and generate possible settings
            obj.pressure_parameters = [];
            for i = 1:numel(baroScaleCandidate)
                curBaroScale = baroScaleCandidate(i);
                targetElev = minPossibleFirstElev;
                if obj.scheduler_random_start
                    targetElev = targetElev + rand() * min(obj.looping_elevation_step, obj.uncertain_meter * 2);
                end
                while targetElev <= maxPossibleFirstElev
                    pressureOffset = firstBaro - targetElev / curBaroScale;
                    obj.pressure_parameters = [ obj.pressure_parameters ; [ curBaroScale pressureOffset ] ];
                    targetElev = targetElev + obj.looping_elevation_step;
                end
            end
            obj.num_pressure_parameters = size(obj.pressure_parameters, 1);
        end
            
        % compute the similarity two rawPaths
        function score = private_similarityOfTwoRawPaths(obj, rawPathA, rawPathB)
            lenA = size(rawPathA, 1);
            lenB = size(rawPathB, 1);
            dp = zeros(lenA+1, lenB+1);
            dp(1, 1) = 1;
            for i = 1:lenA
                for j = 1:lenB
                    dp(i+1, j+1) = max( [ dp(i,j+1) dp(i+1, j) (dp(i,j) + (rawPathA(i,2)==rawPathB(j,2))) ] );
                end
            end
            lcs = dp(end, end);
            score = lcs * lcs / lenA / lenB;
        end
    end
    
end

