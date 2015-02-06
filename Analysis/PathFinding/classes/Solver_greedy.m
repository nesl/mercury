classdef Solver_greedy < handle
    %SOLVER does the following thing:
    %  1. Based on DTW information, it performs search/DP algorithm to find
    %     the most likely n paths
    %  2. It provides the function to compare with the ground-truth path
    
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
        
        % greedy solver parameters;
        % trees will prune branches not in the X'th percentile, and the
        % entire solver will prune trees not within the Y'th percentile.
        PRUNE_PERCENTILE_TREE   = 0.90;
        PRUNE_PERCENTILE_BRANCH = 0.90;
    end
    
    methods
        % CONSTRUCTOR
        function obj = Solver_greedy(map_data, sensor_data) 
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
            % TODO!!!!!
            
            
        end
        
        % RETRIEVE PATHS
        function rawPath = getRawPath(obj, traceIdx)
            rawPath = obj.res_traces(traceIdx).rawPath;
        end
        
        function dtwScore = getDTWScore(obj, traceIdx)
            dtwScore = obj.res_traces(traceIdx).dtwScore;
        end
        
        function latlngs = getLatLngPath(obj, traceIdx)
            rawPath = obj.res_traces(traceIdx).rawPath;
            latlngs = [];
            for i = 1:length(rawPath)-1
                elevMapSeg = obj.map_data.getSegElevation( rawPath(i:i+1, 2) );
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
            timeLatLngs = [ obj.elevFromBaro(:,1)  obj.getLatLngPath(traceIdx) ];
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
                    'index'
                    res = [res (1:numRow)'];
                elseif strcmp(varargin{i}, 'dtwScore') == 1
                    'dtwScore'
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
            plot( gpsData(:,2), gpsData(:,3), 'k*' );
            legendTexts = {'Ground'};
            for i = tracesIdxList
                estiLatLng = obj.getLatLngPath(i);
                color = hsv2rgb([ rand() , 1, 0.7 ]);
                plot( estiLatLng(:,1), estiLatLng(:,2), '-', 'Color', color );
                legendTexts = { legendTexts{:} ['Rank ' num2str(i)] };
            end
            
            rawPath = obj.getRawPath(tracesIdxList(1));
            for i = 1:size(rawPath, 1)
                latlng = obj.map_data.nodeIdxToLatLng(rawPath(i,2));
                plot(latlng(1), latlng(2), 'ob');
                latlng
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
                tmpElev = obj.map_data.nodesToElev( rawPath(:,2) );
                color = hsl2rgb([ rand() * 0.5 , 1, 0.7 ]);
                plot(1:length(tmpElev), tmpElev, '-', 'Color', color);
                legendTexts = { legendTexts{:} ['Rank ' num2str(i)] };
            end
            
            legend(legendTexts);
        end
    end
    
end

