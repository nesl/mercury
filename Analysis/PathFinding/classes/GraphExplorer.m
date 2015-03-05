classdef GraphExplorer < handle
    %GRAPHEXPLORER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % "parent" map object
        map;
        % sensor data object
        sensor;
        % pre-fetch for speed:
        sensor_elevation; 
        % branch pruning, 0-1
        PRUNE_FACTOR_BRANCH = 0;
        % branch loop reduction
        MIN_BRANCH_LOOP_LENGTH = 5;
        % minimum number of leaves to keep
        MAX_LEAVES = 4;
        % do we use turns for pruning?
        use_turns = false;
        sensor_turns = [];
        % score of best branch
        cost = inf;
        % root node
        root;
        % elevation offset
        use_absolute_elevation = false;
        elevation_offset = 0;
        % keep track of nodes
        all_nodes = {};
        % color for plotting and debugging
        color = [];
    end
    
    methods
        % CONSTRUCTOR
        function obj = GraphExplorer(map, sensor, root_idx)
            obj.map = map;
            obj.sensor = sensor;
            
            % create root node (empty parent)
            obj.root = GraphNode([], root_idx);
            obj.all_nodes = [obj.all_nodes; {obj.root}];
            
            % calculate the elevation offset required to make the map and
            % estimated elevations begin at the same height.
            obj.elevation_offset = obj.map.getNodeIdxElev(root_idx) - obj.sensor.getElevationStart();
            
            % pre-fetch sensor elevation for speed
            obj.sensor_elevation = obj.sensor.getElevationTimeWindow();
            
            % random color for plotting :)
            obj.color = rand(1,3);
        end
        
        % USE ABSOLUTE ELEVATION
        function useAbsoluteElevation(obj)
            obj.use_absolute_elevation = true;
        end
        
        % PRUNE WITH TURNS
        function useTurns(obj, turnVector)
            obj.use_turns = true;
            obj.sensor_turns = turnVector;
        end
        
        % EXPLORING NEW NODES
        function exploreNewNodes(obj)
            
            for n=1:length(obj.all_nodes)
                node = obj.all_nodes{n};
                % explore from all leaves in this graph
                if node.isLeaf() && ~node.isDeadend()
                    % get neighbors
                    N = obj.map.getNeighbors(node.node_idx);
                    % loop through all neighbors
                    nodeIsDeadend = true;
                    
                    for i=1:length(N)
                        % if this is already a child of this "leaf" node,
                        % ignore it
                        %fprintf('%d has children: \n', node.node_idx);
                        %for q=1:length(node.children)
                        %    fprintf('    > child: %d (%d)\n', node.children{q}.node_idx, node.hasChild(N(q)));
                        %end

                        if node.hasChild(N(i))
                            continue;
                        end
                        
                        % if this is a blacklisted neigbor, ignore it
                        if node.isChildBlacklisted(N(i))
                            continue;
                        end
                        nodeIsDeadend = false;
                        % have we visited this node recently?
                        neighbor_idx = N(i);
                        visited = node.findUpstreamNode(neighbor_idx,...
                            obj.MIN_BRANCH_LOOP_LENGTH);
                        % if not, let's add it as a child
                        if ~visited

                            % create a new child node
                            child_node = GraphNode(node, neighbor_idx);
                            node.addChild(child_node);
                            % and calculate the cost of traveling to this
                            % new leaf node
                            new_path_cost = obj.calculatePathCost(child_node);
                            child_node.path_cost = new_path_cost;
                            % add to list of all nodes
                            obj.all_nodes = [obj.all_nodes; {child_node}];
                        end
                    end
                    
                    % if 'nodeIsDeadend' was never set to true, all node
                    % children have been blacklisted and we can ignore this
                    % node in the future
                    if nodeIsDeadend
                        node.setDeadend();
                    end
                end
            end
            
        end
        
        % DETERMINE THE COST OF A GIVEN PATH
        function cost = calculatePathCost(obj, leaf_node)
            path_nodes = leaf_node.path;
            
            % get elevation
            mapElevations = obj.map.getPathElev(path_nodes);
            estElevations = obj.sensor_elevation;
            % ignore timestamps and add offset
            if obj.use_absolute_elevation
                estElevations = estElevations(:,2);
            else
                estElevations = estElevations(:,2) + obj.elevation_offset;
            end
            
            
            % get greedy elevation cost (template, partial)
            cost_elev = DTW_greedy(estElevations, mapElevations);
            
            if obj.use_turns
                
                % get segment turns
                mapTurns = obj.map.getPathTurnVector(path_nodes);
                cost_turns = DTW_greedy_turns(obj.sensor_turns(:,2), mapTurns);
            end
            
            % combine costs
            if obj.use_turns
                % -1 used because both are negative, don't want a large
                % positive cost!
                cost = cost_elev*-1*cost_turns;
            else
                cost = cost_elev;
            end
        end
                    
        
        % get explorer's best cost
        function cost = getBestCost(obj)
            costs = [];
            
            for n=1:length(obj.all_nodes)
                if obj.all_nodes{n}.isLeaf()
                    
                    costs = [costs; obj.all_nodes{n}.path_cost];
                    
                end
            end
            
            cost = min(costs);
        end
        
        % get all path costs
        function costs = getPathCosts(obj)
            costs = [];
            
            for n=1:length(obj.all_nodes)
                if obj.all_nodes{n}.isLeaf()
                    
                    costs = [costs; obj.all_nodes{n}.path_cost];
                    
                end
            end
            
        end
        
        % get all paths
        function [paths,costs] = getPaths(obj)
            costs = [];
            paths = {};
            
            for n=1:length(obj.all_nodes)
                if obj.all_nodes{n}.isLeaf()
                    
                    costs = [costs; obj.all_nodes{n}.path_cost];
                    paths = [paths; obj.all_nodes{n}.path];
                    
                end
            end
            
        end
        
        % if the solver object wants to prune everything worse than a
        % global threshold (not local as in auto), they'll use this
        % function.
        function prunePathsWorseThan(obj, thresh)
            % array of leaves to be pruned
            leaves_to_prune = [];
            
            for n=1:length(obj.all_nodes)
                if obj.all_nodes{n}.isLeaf()
                    
                    % if it's too big, throw it out!
                    if obj.all_nodes{n}.path_cost > thresh
                        leaves_to_prune = [leaves_to_prune; n];
                    end
                    
                end
            end
            
            % prune leaves
            obj.pruneLeaves(leaves_to_prune);
        end
         
%         % prune any paths that look too similar to a provided path
%         function pruneSimilarPaths(obj, test_path, thresh)
%             for n=1:length(obj.all_nodes)
%                 if obj.all_nodes{n}.isLeaf()
%                     % get similarity score
%                     path = obj.all_nodes{n}.path;
%                     similarity = getPathSimilarity(test_path, path);
%                     
%                     % prune if it's too similar
%                     while similarity > thresh
%                         % store the parent's path
%                         path = obj.all_nodes{n}.parent.path;
%                         % prune the child
%                         obj.pruneLeaves(n);
%                         % get new similarity
%                         similarity = getPathSimilarity(test_path, 
%                     end
%                     
%                     
%                 end
%             end
%         end
        
        % prune paths by looking at costs relative to this explorer,
        % keeping at most MAX_LEAVES.
        function pruneUntilMaxPaths(obj)
            % if we don't have to prune any, skip this.
            while obj.numLeaves() > obj.MAX_LEAVES
                
                % what are our candidate path costs right now?
                path_costs = [];
                path_idxs = [];
                for n=1:length(obj.all_nodes)
                    if obj.all_nodes{n}.isLeaf()
                        path_costs = [path_costs; obj.all_nodes{n}.path_cost];
                        path_idxs = [path_idxs; n];
                    end
                end
                
                % how many leaves can we keep? log2( # leaves ), no fewer than 4
                sorted_costs = sort(path_costs);
                
                % what's our threshold for tossing out bad paths?
                % throw away any path that exceeds (1-factor)*min_cost
                obj.cost = sorted_costs(1);
                
                % array of leaves to be pruned
                leaves_to_prune = [];
                
                for n=1:length(obj.all_nodes)
                    if obj.all_nodes{n}.isLeaf()
                        
                        % if it's too big, throw it out!
                        if obj.all_nodes{n}.path_cost >= sorted_costs(obj.MAX_LEAVES)
                            leaves_to_prune = [leaves_to_prune; n];
                        end
                        
                    end
                end
                
                % prune leaves
                obj.pruneLeaves(leaves_to_prune);
            end            
        end
        
        % prune a batch of leaves
        function pruneLeaves(obj, leaf_idxs)
            % prune leaf
            for i=1:length(leaf_idxs)
                %fprintf('   pruning %d from %d\n', obj.all_nodes{leaf_idxs(i)}.node_idx, obj.all_nodes{leaf_idxs(i)}.parent.node_idx);
                obj.all_nodes{ leaf_idxs(i) }.prune();
            end
            % remove leaf from object list
            obj.all_nodes(leaf_idxs) = [];
        end
        
        % how many leaves are there?
        function num = numLeaves(obj)
           num = 0;
           for n=1:length(obj.all_nodes)
               if obj.all_nodes{n}.isLeaf()
                   num = num + 1;
               end
           end
        end
        
        % PLOTTING
        function [paths,scores,latlngs,leaves] = getAllPaths(obj)
            latlngs = {};
            scores = [];
            leaves = [];
            paths = {};
            % add paths to all leaves
            for n=1:length(obj.all_nodes)
                if obj.all_nodes{n}.isLeaf()
                    % keep track of leaves
                    leaves = [leaves; obj.all_nodes{n}.node_idx];
                    % get path of indices
                    path_idxs = obj.all_nodes{n}.getPath();
                    paths = [paths; {path_idxs}];
                    % convert indices to lat/lng
                    path_latlng = obj.map.getPathLatLng(path_idxs);
                    % append to array
                    latlngs = [latlngs; path_latlng];
                    scores = [scores; obj.all_nodes{n}.path_cost];
                end
            end
        end
        
        
    end
    
end














