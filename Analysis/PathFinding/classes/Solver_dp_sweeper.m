classdef Solver_dp_sweeper < handle
    % WARNING: This code is obselete and put it for the reference. Unless
    %          we decide to switch back and try to solve the bottleneck,
    %          any further algorithm shouldn't based on this file.
    %
    % History: This class is derived from Solver_dp2.m
    % 
    % This class does the following thing:
    %   1. Based on DTW information, it performs search/DP algorithm to find
    %      the most likely n paths
    %   2. It allows to solve arbitrary path / oracle path and put into the
    %      trajectory result list. Oracle path is a path extracted from gps
    %      data.
    %   3. It provides the function to compare with the ground-truth path
    %
    % This solver list all the possible start points and perform DP
    % algorithm. It focus on exploring early pruning strategies. It
    % introduces the feature of computing on demand, so it shouldn't take
    % too much time on computing (all sub-segments of) DTW.
    %
    % Summary of pruning strategies:
    %   - (time) pruning by dp score over time to time (early time has
    %         tighter pruning condition)
    %   - (correctness) Forbid go-back case
    %   - (correctness) Remove similar paths in the result
    %
    % CONSIDERATION:
    %   - Instead of just forbidding the go-back case, maybe we can put in
    %     more general way: When a turn is making, then a penality is
    %     introduced. Integrating turn detection will definitely help.
    %     Another direction is to give a score based on how reasonable is
    %     the shape of the path.
    
    properties (SetAccess = public)
        % associated objects
        map_data;
        sensor_data;
        
        % elevations from barometer
        elevFromBaro;
        
        % output result
        res_traces;  % which is always sorted
                     % a trace includes .rawPath (step; node_idx columns)
                     %                  .dtwScore (sorted by this)
                     
        % output settings
        max_results = 20;
        outputFilePath;
        
        % DTW processing
        subSegmentHandlers;  % this have to be 2-dim cell, each element is a SubSegmentDTWHandler
        
        % constants for removing similar output paths
        RAW_PATH_SIMILARITY_THRESHOLD = 0.6;
        
        % parameters for finding the oracle path
        NUM_GPS_SAMPLES_TO_ASSURE_NODE_IS_VISITED = 2;
        DISTANCE_THRESHOLD_TO_BE_CONSIDERED_AS_VISITED = 20; % meter, this constraint is very important to avoid false path
    end
    
    methods
        % CONSTRUCTOR
        function obj = Solver_dp_sweeper(map_data, sensor_data)  % expected MapDataNoDTW and SensorData. they are passed by reference
            obj.map_data = map_data;
            obj.sensor_data = sensor_data;
        end
        
        % EARLY PRUNING SETTINGS (consider obselete)
        %function obj = setHardDTWScoreThreshold(obj, score)
        %    obj.HARD_DTW_SCORE_THRESHOLD = score;
        %end
        
        % OUTPUT SETTINGS
        function obj = setOutputFilePath(obj, path)
            obj.outputFilePath = path;
        end
        
        function obj = setNumPathsToKeep(obj, num)
            obj.max_results = num;
        end
        
        % FIND THE LIKELY PATHS
        function solve(obj)
            % all pair DTW
            obj.elevFromBaro = obj.sensor_data.getElevationTimeWindow();
            obj.subSegmentHandlers = obj.map_data.generateAllSubSegmentDTWHandlers(obj.elevFromBaro(:,2), 'pruningFunction' , @(x) (12 + 6*x));
            fprintf('finish generating all sub-segment handlers\n');

            numMapNodes = obj.map_data.getNumNodes();
            numElevBaro = size(obj.elevFromBaro, 1);
            obj.res_traces = [];
            
            for initStartNodeIdx = 1:numMapNodes  % for start point
                % REMOVE: suppose not to be here as it should be handled by
                % other pruning strategy in dp3, but that's temporary put
                % in here and see the performance.
                tmpElevDiff = abs( obj.elevFromBaro(1,2) - obj.map_data.getNodeIdxElev(initStartNodeIdx) );
                if tmpElevDiff > 2
                	continue
                end

                % dp
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
                    for nIdxStart = 1:numMapNodes  % starting node index
                        if dp(nIdxStart, bIdxStart) ~= inf
                            for nIdxEnd = obj.map_data.getNeighbors(nIdxStart);
                                targetSubSegHandler = obj.subSegmentHandlers{nIdxStart, nIdxEnd};
                                earliestPossibleBaroIdxEnd = bIdxStart + targetSubSegHandler.getNumElementOfSeg();
                                prevNodeIdx = from(nIdxStart, bIdxStart, 1);
                                if prevNodeIdx ~= nIdxEnd  % next node is not previous node   <prevNodeIdx> -- <nIdxStart> -- <nIdxEnd>
                                    for bIdxEnd = earliestPossibleBaroIdxEnd:(numElevBaro+1)
                                        tmpScore = dp(nIdxStart, bIdxStart) + targetSubSegHandler.query(bIdxStart, bIdxEnd-1);
                                        
                                        % purning: if tmpScore is inf, meaning that it is pruned by the
                                        % pruning score when performing DTW. no need to continue anymore
                                        if tmpScore == inf
                                            %fprintf('pruned by DTWSweeper nIdxStart=%d, bIdxStart=%d, nIdxEnd=%d, bIdxEnd=%d, segLength=%d\n', nIdxStart, bIdxStart, nIdxEnd, bIdxEnd, targetSubSegHandler.getNumElementOfSeg());
                                            %fprintf('oriScore=%f\n', dp(nIdxStart, bIdxStart));
                                            %pause
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
                    fprintf('sp=%d, time=%d\n', initStartNodeIdx, bIdxStart)
                end

                % back tracking
                for i = 1:numMapNodes
                    if dp(i, numElevBaro+1) ~= inf
                        clear tmp_trace
                        tmp_trace.dtwScore = dp(i, numElevBaro+1);
                        cNodeIdx = i;  % current node index
                        cElevStep = numElevBaro+1;  % current elevation step
                        tmp_trace.rawPath = [numElevBaro+1 i];
                        while cElevStep ~= 1
                            pNodeIdx = from(cNodeIdx, cElevStep, 1);  % previous node index
                            pElevStep = from(cNodeIdx, cElevStep, 2);  % previous elevation step
                            cNodeIdx = pNodeIdx;
                            cElevStep = pElevStep;
                            tmp_trace.rawPath = [ [ pElevStep pNodeIdx ] ; tmp_trace.rawPath];
                        end
                        obj.res_traces = [obj.res_traces tmp_trace];
                    end
                end
            end
            
            fprintf('find out # of paths: ');
            numel(obj.res_traces)
            obj.res_traces = nestedSortStruct(obj.res_traces, {'dtwScore'});
            
            % remove similar traces
            keptTraces = [];
            for i = 1:numel(obj.res_traces)
                findSimilarPath = 0;
                for j = 1:numel(keptTraces)
                    if obj.private_similarityOfTwoRawPaths( ...
                            obj.res_traces(i).rawPath, keptTraces(j).rawPath ) >= obj.RAW_PATH_SIMILARITY_THRESHOLD
                        findSimilarPath = 1;
                        break
                    end
                end
                if findSimilarPath == 0
                    keptTraces = [keptTraces obj.res_traces(i)];
                end
            end
            obj.res_traces = keptTraces;
            
            % TODO: suppose to truncate the # of res_traces into
            % max_results, but for development and debugging purposes, we
            % didn't do that
        end
        
        function forceInsertAPath(obj, path)  % an row vector of nodeIdxs
            % this method force the agent to walk along the specified path.
            % if there already are some result in the res_traces, the new
            % path is gauranteed to be inserted into res_traces with
            % replacing one of them.
            
            obj.elevFromBaro = obj.sensor_data.getElevationTimeWindow();
            obj.subSegmentHandlers = obj.map_data.generateAllSubSegmentDTWHandlers(obj.elevFromBaro(:,2), 'disablePruning');
            fprintf('finish generating all sub-segment handlers\n');
            
            numVisitedNodes = length(path);
            numElevBaro = size(obj.elevFromBaro, 1);
            dp = inf(numVisitedNodes, numElevBaro+1);  % dp(a, b) = score of [last node_idx in sub-path, last step]
            dp(1, 1) = 0;
            from = zeros(numVisitedNodes, numElevBaro+1);  % from(a, b) = last step @ previous node_idx
            for i = 1:(numVisitedNodes-1)
                for j = 1:numElevBaro
                    for k = (j+1):(numElevBaro+1)
                        targetHandler = obj.subSegmentHandlers{ path(i), path(i+1) };
                        t = targetHandler.query(j, k-1);
                        if dp(i, j) + t < dp(i+1, k)
                            dp(i+1, k) = dp(i, j) + t;
                            from(i+1, k) = j;
                        end
                        fprintf('inner %d-%d-%d\n', i, j, k);
                    end
                    fprintf('baro %d\n', j);
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
        
        function forceInsertOraclePath(obj)
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
            
            fprintf('finish generating final path\n');
            obj.forceInsertAPath(finalPath);
        end
        
        % RETRIEVE PATHS
        function rawPath = getRawPath(obj, traceIdx)
            rawPath = obj.res_traces(traceIdx).rawPath;
        end
        
        function dtwScore = getDTWScore(obj, traceIdx)
            dtwScore = obj.res_traces(traceIdx).dtwScore;
        end
        
        function latlngs = getPathLatLng(obj, traceIdx)
            rawPath = obj.res_traces(traceIdx).rawPath;
            latlngs = [];
            for i = 1:length(rawPath)-1
                elevMapSeg = obj.map_data.getSegElev( rawPath(i:i+1, 2) );
                latlngMapSeg = obj.map_data.getSegLatLng( rawPath(i:i+1, 2) );
                a = rawPath(i  , 1);
                b = rawPath(i+1, 1) - 1;
                elevBaroSeg = obj.elevFromBaro(a:b, 2);
                dtwIdxBaro2Map = dtw_find_path( elevMapSeg, elevBaroSeg );
                latlngs = [latlngs ; latlngMapSeg(dtwIdxBaro2Map,:)];
            end

            %latlngs = [ latlngs; obj.map_data.nodeIdxToLatLng( rawPath(end, 2) ) ];
        end
        
        function timeLatLngs = getTimeLatLngPath(obj, traceIdx)
            timeLatLngs = [ obj.elevFromBaro(:,1)  obj.getPathLatLng(traceIdx) ];
        end
        
        % [ row vector ] = getSquareErrors(obj)  // get up to <max_result> results
        % [single value] = getSquareErrors(obj, traceIdx)
        function squareErrors = getSquareErrors(obj, varargin) 
            indxs = 1:min(obj.max_results, numel(obj.res_traces));
            if numel(varargin) >= 1
                indxs = varargin{1}:varargin{1};
            end
            squareErrors = [];
            for i = indxs
                estimatedTimeLatLngs = obj.getTimeLatLngPath(i);
                groundTruthTimeLatLngs = obj.sensor_data.getGps();
                groundTruthTimeLatLngs = groundTruthTimeLatLngs(:, 1:3);
                squareErrors = [squareErrors; ...
                    gpsSeriesCompare(groundTruthTimeLatLngs, estimatedTimeLatLngs)];
            end
        end
        
        % arguments should be passed as strings, including
        % 'index', 'dtwScore' and 'squareError'
        function res = summarizeResult(obj, varargin)
            numRow = min(obj.max_results, numel(obj.res_traces));
            res = zeros(numRow, 0);
            for i = 1:numel(varargin)
                if strcmp(varargin{i}, 'index') == 1
                    res = [res (1:numRow)'];
                elseif strcmp(varargin{i}, 'dtwScore') == 1
                    tmp = zeros(numRow, 1);
                    for j = 1:numRow
                        tmp(j) = obj.res_traces(j).dtwScore;
                    end
                    res = [res roundn(tmp, -8)];
                elseif strcmp(varargin{i}, 'squareError') == 1
                    res = [ res roundn(obj.getSquareErrors(), -8) ];
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
                color = hsl2rgb([ rand() * 0.5 , 1, 0.7 ]);
                plot(1:length(tmpElev), tmpElev, '-', 'Color', color);
                legendTexts = { legendTexts{:} ['Rank ' num2str(i)] };
            end
            
            legend(legendTexts);
        end
        
        % TO WEB
        function toWeb(obj)
            if length(obj.outputFilePath) == 0
                error('set output file path to the solver first (in toWeb())');
            end
            fid = fopen(obj.outputFilePath, 'w');
            gpsData = obj.sensor_data.getGps();
            for i = 1:size(gpsData, 1)
                fprintf(fid, '%f,%f,', gpsData(i,2), gpsData(i,3) );
            end
            fprintf(fid, '-1\n');
            
            numRes = min(obj.max_results, numel(obj.res_traces));
            fprintf(fid, '%d\n', numRes);
            for i = 1:numRes
                squareError = obj.getSquareErrors(i);
                fprintf(fid, '%f,%f,', obj.res_traces(i).dtwScore, squareError);
                rawPath = obj.getRawPath(i);
                for j=1:size(rawPath, 1)
                    latlngs = obj.map_data.getNodeIdxLatLng( rawPath(j,2) );
                    fprintf(fid, '%f,%f,', latlngs(1), latlngs(2));
                end
                fprintf(fid,'-1\n');
            end
            fprintf(['File created. Please check file "' obj.outputFilePath '"\n']);
            fclose(fid);
        end
        
        
        % +-----------------+
        % | PRIVATE METHODS |
        % +-----------------+
        
        % compute the similarity two rawPaths
        function score = private_similarityOfTwoRawPaths(obj, rawPathA, rawPathB)
            % score = (LCS * LCS) / (length(A) + length(B))
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

