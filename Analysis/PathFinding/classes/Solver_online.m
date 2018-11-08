classdef Solver_online < handle
    %SOLVER does the following thing:
    %  1. Based on DTW information, it performs search/DP algorithm to find
    %     the most likely n paths
    %  2. It provides the function to compare with the ground-truth path
    
    properties (SetAccess = public)
        % associated objects
        map_data;
        sensor_data;
        gt_path;
        gt_t;
        
        % output settings
        max_results = 20;
        outputFilePath;
        
        % solver objects
        graph_explorer;
        
        % pruning rules
        %    0 --> 1
        PRUNE_RATE = 0.700;
        MAX_SPEED = 40; % 40 m/s = 90 mph
        
        % debugging options
        DBG = false;

        process_time;
    end
    
    methods
        % CONSTRUCTOR
        function obj = Solver_online(map_data, sensor_data, gt_path, gt_t)
            obj.map_data = map_data;
            obj.sensor_data = sensor_data;
            obj.DBG = true;
            obj.gt_path = gt_path;
            obj.gt_t = gt_t;
            
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
            tic
            
            if obj.DBG
                figure();
            end
            
            % -- create graph explorer for only the starting node --
            obj.graph_explorer = GraphExplorerOnline(obj.map_data, obj.sensor_data, obj.gt_path(1));
            
            % --- search for realistic paths and prune ---
            hist_len = 10;
            cost_history = zeros(hist_len,1);
            
            for iter=1:100
                fprintf('Iteration %d\n', iter);
                
                % --- explore and get path costs ---
                obj.graph_explorer.exploreNewNodes();
                costs = obj.graph_explorer.getPathCosts();               
                
                % --- get threshold path cost ---
                %cost_thresh = prctile(all_path_costs, 100*(1 - obj.PRUNE_RATE));
                sorted_costs = sort(costs);
                prune_goal = round( length(sorted_costs)*(1-obj.PRUNE_RATE) );
                prune_cost_idx = max(obj.max_results, prune_goal);
                                
                if prune_cost_idx <= length(sorted_costs)
                    % we need to prune!
                    cost_thresh = sorted_costs( prune_cost_idx );
                    
                    % --- prune paths above the threshold ---
                    fprintf('    Pruning paths...');
                    obj.graph_explorer.prunePathsWorseThan(cost_thresh);
                    obj.graph_explorer.pruneUntilMaxPaths();
                    fprintf('DONE\n');
                end
                
                % --- prune paths that are unrealistically long ---
                length_thresh = obj.MAX_SPEED*obj.gt_t;
                obj.graph_explorer.prunePathsLongerThan( length_thresh );
                
                % --- finish if overall cost has converged ---
                deltaPerc = min(1, abs((sorted_costs(1) - cost_history(1))/cost_history(1)) );
                fprintf('    Solver Delta: %.3f\n', deltaPerc);
                if deltaPerc < 0.01;
                   fprintf('SOLVER DONE!\n');
                   obj.process_time = toc;
                   return;
                end
                % rotate window
                cost_history = [cost_history(2:end); sorted_costs(1)];
                
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
                    
                    % plot true path
                    latlng = obj.map_data.getPathLatLng(obj.gt_path);
                    % long, lat
                    plot(latlng(:,2), latlng(:,1), 'Color', 'g', 'LineWidth',3);
                    hold on;
                    
                    % plot solver
                    [paths,scores,latlngs,leaves] = obj.graph_explorer.getAllPaths();
                    for p=1:length(latlngs);
                        latlng = latlngs{p};
                        score = scores(p);
                        % long, lat
                        plot(latlng(:,2), latlng(:,1), 'Color', 'r', 'LineWidth',2);
                        hold on;
                    end
                    
                    % pause so we can see plot
                    pause(0.1);
                    
                end
                
            end
            
        end
        
        % RETRIEVE PATHS
        function [scores,paths] = getResults(obj)
            % --- explore and get path costs ---
            [all_paths,all_path_costs] = obj.graph_explorer.getPaths();
            [sorted_costs, sorted_idxs] = sort(all_path_costs);

            scores = sorted_costs(1:end);
            paths = all_paths(sorted_idxs);
            
            % --- prune paths that are too similar to paths that are ---
            %               performing better anyways
            similarity_thresh = 0.90;
            idxs_to_remove = [];
            for startpath=1:(length(paths)-1)
                for testpath = (startpath+1):length(paths)
                    if getPathSimilarity( paths{startpath}, paths{testpath} ) > similarity_thresh
                        fprintf('removing index: %d\n', testpath);
                        % schedule this path for removal
                        idxs_to_remove = [idxs_to_remove; testpath];
                    end
                end
            end
            % remove too similar paths
            paths(idxs_to_remove) = [];
            scores(idxs_to_remove) = [];
        end
        
    end
    
end

