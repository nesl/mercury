classdef Solver_dp4 < handle
    % This class does the following thing:
    %   1. This solver no longer depends on the pre-assigned pressure
    %      parameter. Technically It tries to list all the possible ones.
    %      But we still need to give it a range of possible parameters.
    %   2. Based on DTW information, it performs search/DP algorithm to find
    %      the most likely n paths
    %   3. It allows to solve arbitrary path / oracle path and put into the
    %      trajectory result list. Oracle path is a path extracted from gps
    %      data.
    %   4. It provides the function to compare with the ground-truth path.
    %   5. Parallelly solves different case (if map is small or ram is big)
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
        looping_elevation_step = 2;  % meters
        scheduler_random_start = 0;  % 0 means the first pressure setting always equal to the smallest possible offset,
                                     % whereas 1 means it shifts. All other numbers just return an exception
        
        % about scheduler
        pressure_parameters;  % an n-by-2 array, each row is [scalar, offset]
                              % the setting is assigned when solve() is triggered only.
        num_pressure_parameters;
                            
        % associated objects
        map_data;
        sensor_data;
        
        % elevations from barometer
        elev_series_from_baro;  % TODO: integrate into the solver
        
        % dtw cost functions
        dtw_cost_function = @(x) (x .^ 2);
        
        % output result
        final_res_traces;  % which is always sorted
                           % a trace includes .rawPath (step; node_idx columns)
                           %                  .dtwScore (sorted by this)
                           %                  .pressureParamIdx
                     
        
        % output settings
        max_results = 30;
        outputFilePath;
        
        % pruning constants
        INITIAL_ELEVATION_DIFFERENCE_SCREEN = 2; % meter
        RAW_PATH_SIMILARITY_THRESHOLD = 0.6;
        
        % pruning constants/functions
        HARD_ELEVATION_THRESHOLD = 6; % meter, consider the nodes as check points and apply the threshold.
        dtw_pruning_function = @(x) (27 + 10 * x);  % during accessing x-th barometer element in the dtw,
                                                    % what is the cutting threshold for corresponding column
        global_pruning_function = @(x) (200 + 10 * x)  % during accessing x-th barometer element in the dynamic programming,
                                                       % what is the cutting threshold for corresponding column
        
                                                       
        % parameters for finding the oracle path
        NUM_GPS_SAMPLES_TO_ASSURE_NODE_IS_VISITED = 2;
        DISTANCE_THRESHOLD_TO_BE_CONSIDERED_AS_VISITED = 20; % meter, this constraint is very important to avoid false path
        
    end
    
    methods
        % CONSTRUCTOR
        function obj = Solver_dp4(mapData, sensorData, scheduleRandomStart)  % expected MapData and SensorData. they are passed by reference
            obj.map_data = mapData;
            obj.sensor_data = sensorData;
            obj.scheduler_random_start = scheduleRandomStart;
        end
        
        % EARLY PRUNING SETTINGS
        function obj = setHardDTWScoreThreshold(obj, score)
            obj.HARD_DTW_SCORE_THRESHOLD = score;
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
            % get possible pressure parameters
            obj.private_schedulePressureParameters();
            
            % initialize all the possible pressure parameters
            obj.elev_series_from_baro = cell(obj.num_pressure_parameters, 1);
            for i = 1:obj.num_pressure_parameters
                obj.sensor_data.setPressureScalar( obj.pressure_parameters(i,1) );
                obj.sensor_data.setSeaPressure( obj.pressure_parameters(i,2) );
                obj.elev_series_from_baro{i} = obj.sensor_data.getElevationTimeWindow();
            end
            fprintf('pressure parameters scheduled and related stuff initialized\n');
            
            tmpResTracesForAllPressureParameters = cell(obj.num_pressure_parameters, 1);
            for preIdx = 1:obj.num_pressure_parameters  % pressure index
                numMapNodes = obj.map_data.getNumNodes();
                numElevBaro = size(obj.elev_series_from_baro{preIdx}, 1);
                curDtwHelper = SubSegmentDTWHelper(obj.map_data, obj.elev_series_from_baro{preIdx}(:,2), obj.dtw_cost_function, obj.dtw_pruning_function);
                
                % find the possible starting points
                beginElev = obj.elev_series_from_baro{preIdx}(1,2);
                tmpElevDiff = beginElev - obj.map_data.getNodeIdxsElev(1:obj.map_data.num_nodes);
                startingNodeSet = find( abs(tmpElevDiff) <= obj.INITIAL_ELEVATION_DIFFERENCE_SCREEN );  
                startingNodeSet = startingNodeSet';  % transpose to make sure it's a row vector.
                
                tmpResTraces = [];
                for initStartNodeIdx = startingNodeSet  % for start point
                    % dynamic programming
                    dp = inf(numMapNodes, numElevBaro+1);  % dp(node idx, baro elev step)
                    dp(initStartNodeIdx,1) = 0;
                    from = zeros(numMapNodes, numElevBaro+1, 2);  % from(a, b) = [last node idx, last baro elev step]

                    % GUIDELINE: think about we start from
                    %     dp(nIdxStart, bIdxStart) -------- consume baro data (bIdxStart:(bIdxEnd-1)) --------> dp(nIdxEnd, bIdxEnd)
                    %
                    % abbreviation: initial n stands for node, b stands for (from) barometer
                    % nIdxStart and nIdxEnd are neighbors
                    % the traveling time, or more precisely, consumption of barometer data, is (bIdxEnd - bIdxStart + 1)

                    for bIdxStart = 1:numElevBaro  % starting barometer index
                        earlyDPPruningScore = obj.global_pruning_function(bIdxStart);
                        for nIdxStart = 1:numMapNodes  % starting node index
                            %[bIdxStart nIdxStart obj.elevFromBaro(bIdxStart) obj.map_data.getNodeIdxsElev(nIdxStart)]
                            if dp(nIdxStart, bIdxStart) < earlyDPPruningScore ...     % global pruning. 
                                    && abs(obj.elev_series_from_baro{preIdx}(bIdxStart, 2) - obj.map_data.getNodeIdxsElev(nIdxStart)) < obj.HARD_ELEVATION_THRESHOLD
                                for nIdxEnd = obj.map_data.getNeighbors(nIdxStart);
                                    numElementOfSeg = obj.map_data.getSegNumElement( [nIdxStart, nIdxEnd] );
                                    prevNodeIdx = from(nIdxStart, bIdxStart, 1);
                                    if prevNodeIdx ~= nIdxEnd  % next node is not previous node   <prevNodeIdx> -- <nIdxStart> -- <nIdxEnd>
                                        earliestPossibleBaroIdxEnd = bIdxStart + numElementOfSeg;
                                        for bIdxEnd = earliestPossibleBaroIdxEnd:(numElevBaro+1)
                                            tmpScore = dp(nIdxStart, bIdxStart) + curDtwHelper.query(nIdxStart, nIdxEnd, bIdxStart, bIdxEnd-1);

                                            % purning: if tmpScore is inf, meaning that it is pruned by the
                                            % pruning score when performing DTW. no need to continue anymore
                                            if tmpScore == inf
                                                break
                                            end

                                            if tmpScore < dp(nIdxEnd, bIdxEnd)
                                                dp(nIdxEnd, bIdxEnd) = tmpScore;
                                                from(nIdxEnd, bIdxEnd, :) = [nIdxStart bIdxStart];
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        fprintf('pressureParam=%.2f,%.2f sp=%d, time=%d\n', ...
                            obj.pressure_parameters(preIdx, 1), obj.pressure_parameters(preIdx, 2), initStartNodeIdx, bIdxStart)
                    end
            
                    % back tracking
                    for i = 1:numMapNodes
                        if dp(i, numElevBaro+1) < inf
                            tmpTrace = [];
                            tmpTrace.pressureParamIdx = preIdx;
                            tmpTrace.dtwScore = dp(i, numElevBaro+1);
                            cNodeIdx = i;  % current node index
                            cElevStep = numElevBaro+1;  % current elevation step
                            tmpTrace.rawPath = [numElevBaro+1 i];
                            while cElevStep ~= 1
                                pNodeIdx = from(cNodeIdx, cElevStep, 1);  % previous node index
                                pElevStep = from(cNodeIdx, cElevStep, 2);  % previous elevation step
                                cNodeIdx = pNodeIdx;
                                cElevStep = pElevStep;
                                tmpTrace.rawPath = [ [ pElevStep pNodeIdx ] ; tmpTrace.rawPath];
                            end
                            tmpResTraces = [tmpResTraces tmpTrace];
                        end
                    end
                end
                tmpResTracesForAllPressureParameters{preIdx} = tmpResTraces;
            end
            
            % join the answers
            obj.final_res_traces = [];
            for i = 1:obj.num_pressure_parameters
                obj.final_res_traces = [obj.final_res_traces tmpResTracesForAllPressureParameters{i}];
            end
            
            if numel(obj.final_res_traces) == 0
                warning('Solver didn''t find any possible path... try to relax the pruning condition');
                return;
            end
            
            obj.final_res_traces = nestedSortStruct(obj.final_res_traces, {'dtwScore'});
            
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
                if i >= 1000
                    break;
                end
            end
            obj.final_res_traces = keptTraces;
            
            % TODO: suppose to truncate the # of res_traces into
            % max_results, but for development and debugging purposes, we
            % didn't do that
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
        function rawPath = getRawPath(obj, traceIdx)
            rawPath = obj.final_res_traces(traceIdx).rawPath;
        end
        
        function dtwScore = getDTWScore(obj, traceIdx)
            dtwScore = obj.final_res_traces(traceIdx).dtwScore;
        end
        
        function latlngs = getPathLatLng(obj, traceIdx)
            preIdx = obj.final_res_traces(traceIdx).pressureParamIdx;
            rawPath = obj.final_res_traces(traceIdx).rawPath;
            latlngs = [];
            for i = 1:length(rawPath)-1
                elevMapSeg = obj.map_data.getSegElev( rawPath(i:i+1, 2) );
                latlngMapSeg = obj.map_data.getSegLatLng( rawPath(i:i+1, 2) );
                a = rawPath(i  , 1);
                b = rawPath(i+1, 1) - 1;
                elevBaroSeg = obj.elev_series_from_baro{preIdx}(a:b, 2);
                [~, dtwIdxBaro2Map, ~] = dtw_basic( elevMapSeg, elevBaroSeg, obj.dtw_cost_function, @(x) (inf) );
                latlngs = [latlngs ; latlngMapSeg(dtwIdxBaro2Map,:)];
            end

            %latlngs = [ latlngs; obj.map_data.nodeIdxToLatLng( rawPath(end, 2) ) ];
        end
        
        function timeLatLngs = getTimeLatLngPath(obj, traceIdx)
            tmpElevFromBaro = obj.elev_series_from_baro{1};  % we only care about time column. every series have the same timestamps
            timeLatLngs = [ tmpElevFromBaro(:,1)  obj.getPathLatLng(traceIdx) ];
        end
        
        % see time_gps_series_compare.m for more information
        % [ row vector ] = getPathSimilarityConsideringTime(obj)  // get up to <max_result> results
        % [ row vector ] = getPathSimilarityConsideringTime(obj, traceIdxs)
        function rmsInMeter = getPathSimilarityConsideringTime(obj, varargin) 
            indxs = 1:min(obj.max_results, numel(obj.final_res_traces));
            if numel(varargin) >= 1
                indxs = varargin{1};
            end
            rmsInMeter = [];
            for i = indxs
                estimatedTimeLatLngs = obj.getTimeLatLngPath(i);
                groundTruthTimeLatLngs = obj.sensor_data.getGps();
                groundTruthTimeLatLngs = groundTruthTimeLatLngs(:, 1:3);
                rmsInMeter = [rmsInMeter; ...
                    time_gps_series_compare(groundTruthTimeLatLngs, estimatedTimeLatLngs)];
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
            rmsInMeter = [];
            for i = indxs
                estimatedTimeLatLngs = obj.getTimeLatLngPath(i);
                groundTruthTimeLatLngs = obj.sensor_data.getGps();
                groundTruthTimeLatLngs = groundTruthTimeLatLngs(:, 1:3);
                rmsInMeter = [rmsInMeter; ...
                    gps_series_compare(groundTruthTimeLatLngs, estimatedTimeLatLngs)];
            end
        end
        
        % arguments should be passed as strings, including
        % 'index', 'dtwScore' and 'squareError'
        function res = summarizeResult(obj, varargin)
            error('need to be upgraded (and also get parameters)');
            numRow = min(obj.max_results, numel(obj.final_res_traces));
            res = zeros(numRow, 0);
            for i = 1:numel(varargin)
                if strcmp(varargin{i}, 'index') == 1
                    res = [res (1:numRow)'];
                elseif strcmp(varargin{i}, 'dtwScore') == 1
                    tmp = zeros(numRow, 1);
                    for j = 1:numRow
                        tmp(j) = obj.final_res_traces(j).dtwScore;
                    end
                    res = [res roundn(tmp, -8)];
                elseif strcmp(varargin{i}, 'path') == 1
                    res = [ res roundn(obj.getPathSimilarityConsideringTime(), -8) ];
                elseif strcmp(varargin{i}, 'pathShape') == 1
                    res = [ res roundn(obj.getPathShapeSimilarity(), -8) ];
                else
                    error(['unrecognized column name ' varargin{i} ' (in resultSummarize())']);
                end
            end
        end
        
        % VISUALIZATION
        function plotPathComparison(obj, tracesIdxList)
            gpsData = obj.sensor_data.getGps();  % 2:lat, 3:lon
            clf
            hold on
            plot( gpsData(:,3), gpsData(:,2), 'k*' );
            legendTexts = {'Ground'};
            for i = tracesIdxList
                estiLatLng = obj.getPathLatLng(i);
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
        function toWeb(obj)
            obj.private_toWeb(0);
        end
        
        function toWebBeautiful(obj)
            obj.private_toWeb(1);
        end
        
        
        % +-----------------+
        % | PRIVATE METHODS |
        % +-----------------+
        
        % generate pressure parameters to test
        function private_schedulePressureParameters(obj)
            % get min and max baro
            baro = obj.sensor_data.getBaro();
            minBaro = min(baro(:,2));
            maxBaro = max(baro(:,2));
            baroDiff = maxBaro - minBaro;
            baroStep = 1 / baroDiff;
            scaleNum = ceil(0.4 / baroStep);
            scaleDelta = 0.4 / scaleNum;
            scaleTotalRange = scaleDelta * (scaleNum - 1);
            baroScaleCandidate = -linspace(8.0 - scaleTotalRange / 2, 8.0 + scaleTotalRange / 2, scaleNum);
            
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
                    targetElev = targetElev + obj.uncertain_meter * rand();
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
        
        % help for generating results to the web
        function private_toWeb(obj, flagBeautiful)
            if isempty(obj.outputFilePath)
                error('set output file path to the solver first (in toWeb())');
            end
            
            fid = fopen([ obj.outputFilePath ], 'w');
            gpsData = obj.sensor_data.getGps();
            for i = 1:size(gpsData, 1)
                fprintf(fid, '%f,%f,', gpsData(i,2), gpsData(i,3) );
            end
            fprintf(fid, '-1\n');
            
            numRes = min(obj.max_results, numel(obj.final_res_traces));
            fprintf(fid, '%d\n', numRes);
            for i = 1:numRes
                rmsErrorPath = obj.getPathSimilarityConsideringTime(i);
                rmsErrorPathShape = obj.getPathShapeSimilarity(i);
                fprintf(fid, '%f,%f,%f', obj.final_res_traces(i).dtwScore, rmsErrorPath, rmsErrorPathShape);
                
                if flagBeautiful == 0
                    rawPath = obj.getRawPath(i);
                    for j=1:size(rawPath, 1)
                        latlngs = obj.map_data.getNodeIdxLatLng( rawPath(j,2) );
                        fprintf(fid, ',%f,%f', latlngs(1), latlngs(2));
                    end
                    fprintf(fid,'-1\n');
                elseif flagBeautiful == 1
                    estiLatLng = obj.getPathLatLng(i);
                    for j=1:size(estiLatLng, 1)
                        fprintf(fid, ',%f,%f', estiLatLng(j,1), estiLatLng(j,2));
                    end
                else
                    error('Unsupported mode of generating result (in private_toWeb())');
                end
                
                fprintf(fid, '\n');
            end
            fprintf(['File created. Please check file "' obj.outputFilePath '"\n']);
            fclose(fid);
        end
    end
    
end

