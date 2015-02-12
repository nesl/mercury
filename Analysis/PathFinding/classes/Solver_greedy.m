classdef Solver_greedy < handle
    %SOLVER does the following thing:
    %  1. Based on DTW information, it performs search/DP algorithm to find
    %     the most likely n paths
    %  2. It provides the function to compare with the ground-truth path
    
    properties (SetAccess = public)
        % associated objects
        map_data;
        sensor_data;
        
        % output settings
        max_results = 20;
        outputFilePath;
        
        % solver objects
        use_absolute_elevation = false;
        graph_explorers = {};
        
        % pruning rules
        PRUNE_RATE = 75;
        
        % debugging options
        DBG = false;
        
    end
    
    methods
        % CONSTRUCTOR
        function obj = Solver_greedy(map_data, sensor_data, debug)
            obj.map_data = map_data;
            obj.sensor_data = sensor_data;
            obj.DBG = debug;
            
        end
        
        % ABSOLUTE ELEVATION OR RELATIVE
        function useAbsoluteElevation(obj)
            obj.use_absolute_elevation = true;
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
            
            if obj.DBG
                figure();
            end
            
            % --- for each node, create a GraphExplorer ---
            num_nodes = obj.map_data.getNumNodes();
            for n=1:num_nodes
                obj.graph_explorers = [obj.graph_explorers;
                    {GraphExplorer(obj.map_data, obj.sensor_data, n, 0.5)}];
                
                % absolute or relative elvations
                if obj.use_absolute_elevation
                    obj.graph_explorers{n}.useAbsoluteElevation();
                end
            end
            
            % --- search for realistic paths and prune ---
            PRUNE_DELAY = 1;
            time_till_prune = PRUNE_DELAY;
            
            for iter=1:100
                fprintf('Iteration %d\n', iter);
                
                % --- explore and get path costs ---
                all_path_costs = [];
                for e=1:length(obj.graph_explorers)
                    fprintf('Explorer %d/%d\n', e, length(obj.graph_explorers));
                    % explore new nodes
                    obj.graph_explorers{e}.exploreNewNodes();
                    costs = obj.graph_explorers{e}.getPathCosts();
                    all_path_costs = [all_path_costs; costs];
                end
                
                fprintf(' ------------ SUMMARY ----------- \n');
                fprintf('    Explorers: %d \t Paths: %d\n', length(obj.graph_explorers), length(all_path_costs));

                
                % --- get threshold path cost ---
                cost_thresh = prctile(all_path_costs, 100 - obj.PRUNE_RATE);
                
                % --- prune paths above the threshold ---
                explorers_to_prune = [];
                for e=1:length(obj.graph_explorers)
                    % if the best cost of this explorer doesn't meet the
                    % threshold, prune the whole thing.
                    if obj.graph_explorers{e}.getBestCost() > cost_thresh
                        explorers_to_prune = [explorers_to_prune; e];
                    else
                        obj.graph_explorers{e}.prunePathsWorseThan(cost_thresh);
                    end
                end
                obj.graph_explorers(explorers_to_prune) = [];
                
                % --- finish if less than max outputs ---
                if length(all_path_costs)*(100 - obj.PRUNE_RATE) < obj.max_results
                    fprintf(' SOLVER DONE!\n');
                    return;
                end
                    
                
                % PLOT DEBUGGING
                if obj.DBG
                    % clear plot
                    hold off;
                    
                    % plot map
                    map_lines = obj.map_data.getAllSegLatLng();
                    for s=1:length(map_lines)
                        latlng = map_lines{s};
                        plot(latlng(:,2), latlng(:,1), 'Color', [0.8 0.8 0.8]);
                        hold on;
                    end
                    
                    % plot everything
                    for e=1:length(obj.graph_explorers)
                        [paths,scores] = obj.graph_explorers{e}.getAllPathLatLng();
                        for p=1:length(paths);
                            path = paths{p};
                            score = scores(p);

                            % long, lat
                            plot(path(:,2), path(:,1), 'Color', obj.graph_explorers{e}.color, 'LineWidth',2);
                            hold on;
                        end
                    end
                    
                    
                end
                
                % pause so we can see plot
                pause(0.5);
                
                
                
                
            end
            
            
            
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

