classdef Solver_dp < handle
    % SOLVER does the following thing:
    %   1. Based on DTW information, it performs search/DP algorithm to find
    %      the most likely n paths
    %   2. It provides the function to compare with the ground-truth path
    %
    % This solver uses the basic DP algorithm.
    
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
    end
    
    methods
        % CONSTRUCTOR
        function obj = Solver_dp(map_data, sensor_data)  % they are passed by reference
            obj.map_data = map_data;
            obj.sensor_data = sensor_data;
        end
        
        % OUTPUT SETTINGS
        function setOutputFilePath(obj, path)
            obj.outputFilePath = path;
        end
        
        function setNumPathsToKeep(obj, num)
            obj.max_results = num;
        end
        
        % FIND THE LIKELY PATHS
        function solve(obj)
            % all pair DTW
            obj.elevFromBaro = obj.sensor_data.getElevationTimeWindow();
            obj.map_data.preProcessAllPairDTW(obj.elevFromBaro(:,2));
            fprintf('finish calculating all pairs of dtw\n');

            % dp
            numMapNodes = obj.map_data.getNumNodes();
            numElevBaro = size(obj.elevFromBaro, 1);
            dp = ones(numMapNodes, numElevBaro+1) * inf;  % dp(node idx, elev step)
            dp(:,1) = 0;
            from = zeros(numMapNodes, numElevBaro+1, 2);  % from(a, b) = [last node, last step]
            for i = 1:numElevBaro
                for j = 1:numMapNodes
                    neighbors = obj.map_data.getNeighbors(j);
                    for k = 1:numel(neighbors)
                        nn = neighbors(k);  % neighbor node
                        dtwArr = obj.map_data.queryAllPairDTW(j, nn, i);  % all pair DTW from (i,i) to (i,end)
                        ind = find( dp(j, i) + dtwArr < dp(nn, (i+1):end) );
                        % ind spans the same range as <i to numElevBaro>
                        % (ind + i) maps to range (i+1):(numElevBaro+1), 
                        dp(nn, i+ind) = dp(j, i) + dtwArr(ind);
                        from(nn, i+ind, :) = repmat([j i], length(ind), 1);
                    end
                end
                fprintf('%d\n', i)
            end
            
            % back tracking
            obj.res_traces = [];
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
            
            % TODO: suppose to truncate the # of res_traces into
            % max_results, but for development and debugging purposes, we
            % didn't do that
            obj.res_traces = nestedSortStruct(obj.res_traces, {'dtwScore'});
        end
        
        function forceInsertAPath(obj, path)  % an row vector of nodeIdxs
            % this method force the agent to walk along the specified path.
            % if there already are some result in the res_traces, the new
            % path is gauranteed to be inserted into res_traces with
            % replacing one of them.
            
            pathElev = obj.getPathElev(path);
            tmp = all_pair_dtw(path, obj.elevFromBaro);
            % in this approach how to compute rawPath?
            % essentially you need basic 
            % score
            % Don't have the motivation to continue... work on the other
            % day.... TODO
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
        function squareErrors = getSquareErrors(obj, varargin)  % UNTESTED
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
        function res = resultSummarize(obj, varargin)
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
    end
    
end

