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
        PRUNE_RATE = 0.50;
        
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
            old_cost = 0;
            
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
               
                
                % --- get threshold path cost ---
                %cost_thresh = prctile(all_path_costs, 100*(1 - obj.PRUNE_RATE));
                sorted_costs = sort(all_path_costs);
                prune_goal = round( length(sorted_costs)*(1-obj.PRUNE_RATE) );
                prune_cost_idx = max(obj.max_results, prune_goal);
                
                if prune_cost_idx > length(sorted_costs)
                    % no need to prune!
                    continue;
                end
                
                cost_thresh = sorted_costs( prune_cost_idx );
                
                fprintf(' ------------ SUMMARY ----------- \n');
                fprintf('    Explorers: %d \t Paths: %d, thresh:%.2f\n', length(obj.graph_explorers), length(all_path_costs), cost_thresh);
                
                % --- prune paths above the threshold ---
                explorers_to_prune = [];
                for e=1:length(obj.graph_explorers)
                    % if the best cost of this explorer doesn't meet the
                    % threshold, prune the whole thing.
                    if obj.graph_explorers{e}.getBestCost() > cost_thresh
                        explorers_to_prune = [explorers_to_prune; e];
                    else
                        obj.graph_explorers{e}.prunePathsWorseThan(cost_thresh);
                        obj.graph_explorers{e}.pruneUntilMaxPaths();
                    end
                end
                obj.graph_explorers(explorers_to_prune) = [];
                
                % --- finish if overall cost has converged ---
                if iter > 3
                    delta = sorted_costs(1) - old_cost;
                    if abs(delta) < 300;
                        fprintf('SOLVER DONE!\n');
                        return;
                    end
                    old_cost = sorted_costs(1);
                    fprintf('    Solver Delta:%.2f\n', delta);
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
                        [paths,scores,latlngs,leaves] = obj.graph_explorers{e}.getAllPaths();
                        for p=1:length(latlngs);
                            latlng = latlngs{p};
                            score = scores(p);

                            % long, lat
                            plot(latlng(:,2), latlng(:,1), 'Color', obj.graph_explorers{e}.color, 'LineWidth',2);
                            hold on;
                        end
                    end
                    
                    
                end
                
                % pause so we can see plot
                pause(0.1);
  
            end
      
        end
        
        % RETRIEVE PATHS
        function [scores,paths] = getResults(obj)
            % --- explore and get path costs ---
            all_path_costs = [];
            all_paths = {};
            for e=1:length(obj.graph_explorers)
                [paths,costs] = obj.graph_explorers{e}.getPaths();
                all_path_costs = [all_path_costs; costs];
                all_paths = [all_paths; paths];
            end
            [sorted_costs, sorted_idxs] = sort(all_path_costs);

            scores = sorted_costs(1:obj.max_results);
            paths = all_paths(sorted_idxs);
            
        end
        
    end
    
end

