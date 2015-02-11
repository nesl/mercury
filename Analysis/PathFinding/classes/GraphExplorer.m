classdef GraphExplorer < handle
    %GRAPHEXPLORER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % "parent" map object
        map;
        % sensor data object
        sensor;
        % branch pruning, 0-1
        PRUNE_FACTOR_BRANCH = 0;
        % branch loop reduction
        MIN_BRANCH_LOOP_LENGTH = 5;
        % minimum number of leaves to keep
        MIN_LEAVES = 4;
        % score of best branch
        cost = inf;
        % root node
        root;
        % elevation offset
        elevation_offset = 0;
        % keep track of nodes
        all_nodes = {};
        % color for plotting and debugging
        color = [];
    end
    
    methods
        % CONSTRUCTOR
        function obj = GraphExplorer(map, sensor, root_idx, pruning)
            obj.map = map;
            obj.sensor = sensor;
            if pruning < 0 || pruning >= 1
                error('prune factor bust be >=0 and < 1');
            end
            obj.PRUNE_FACTOR_BRANCH = pruning;
            
            % create root node (empty parent)
            obj.root = GraphNode([], root_idx);
            obj.all_nodes = [obj.all_nodes; {obj.root}];
            
            % calculate the elevation offset required to make the map and
            % estimated elevations begin at the same height.
            obj.elevation_offset = obj.map.getNodeIdxElev(root_idx) - obj.sensor.getElevationStart();
            
            % random color for plotting :)
            obj.color = rand(1,3);
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
                        node.setDeadend()
                    end
                end
            end
        end
        
        % DETERMINE THE COST OF A GIVEN PATH
        function cost = calculatePathCost(obj, leaf_node)
            path_nodes = leaf_node.path;
            
            % get elevation
            mapElevations = obj.map.getPathElev(path_nodes);
            estElevations = obj.sensor.getElevation();
            % ignore timestamps and add offset
            estElevations = estElevations(:,2) + obj.elevation_offset;
            
            % get greedy elevation cost (template, partial)
            cost_elev = DTW_greedy(estElevations, mapElevations);
            
            % get turn cost
            % TODO: Currently I'm not going to add turns, so that I can see
            % how well it does without them.  I'll add turns later, because
            % they won't work w/ the walking in Case 1 anyways :)
            
            % get turns
            %mapTurns = obj.map.getPathTurns(path_nodes);
            %estTurns = obj.sensor.get
            
            % combine costs
            cost = cost_elev;
        end
        
        
        function prunePaths(obj)
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
            num_leaves_kept = max( obj.MIN_LEAVES, ceil(log2(length(path_costs))) );
            sorted_costs = sort(path_costs);
            
            % what's our threshold for tossing out bad paths?
            % throw away any path that exceeds (1-factor)*min_cost
            obj.cost = sorted_costs(1);
            
            % do we have to prune? do we have more than we're keeping?
            if length(path_costs) > num_leaves_kept
                
                % array of leaves to be pruned
                leaves_to_prune = [];
                
                for n=1:length(obj.all_nodes)
                    if obj.all_nodes{n}.isLeaf()
                        
                        % if it's too big, throw it out!
                        if obj.all_nodes{n}.path_cost > sorted_costs(num_leaves_kept)
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
                obj.all_nodes{ leaf_idxs(i) }.prune();
            end
            % remove leaf from object list
            obj.all_nodes(leaf_idxs) = [];
        end
        
        % PLOTTING
        function [paths,scores] = getAllPathLatLng(obj)
            paths = {};
            scores = [];
            % add paths to all leaves
            for n=1:length(obj.all_nodes)
                if obj.all_nodes{n}.isLeaf()
                    % get path of indices
                    path_idxs = obj.all_nodes{n}.getPath();
                    % convert indices to lat/lng
                    path_latlng = obj.map.getPathLatLng(path_idxs);
                    % append to array
                    paths = [paths; path_latlng];
                    scores = [scores; obj.all_nodes{n}.path_cost];
                end
            end
        end

    end
    
end














