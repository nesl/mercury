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
        MIN_BRANCH_LOOP_LENGTH = 10;
    
        % score of best branch
        cost = inf;
        
        % root node
        root;
        
        % keep track of nodes
        all_nodes = {};
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
            
            % create root node
            obj.root = GraphNode(nan, root_idx);
            obj.all_nodes = [obj.all_nodes; obj.root];
        end
        
        % TAKE ONE STEP / ITERATION
        function step(obj)
           % explore new nodes
           obj.exploreNewNodes();
           
           % prune bad branches
           obj.prunePaths();
           
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
                            child_node.cost = new_path_cost;
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
            mapElevationChanges = obj.map.getPathElevDeriv(path_nodes);
            estElevationChanges = obj.sensor.getElevationDeriv();
            
            % get greedy elevation cost
            [~,~,cost_elev] = MSE_greedy(estElevationChanges, mapElevationChanges); 
            
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
            
            % what's our threshold for tossing out bad paths?
            % throw away any path that exceeds (1-factor)*min_cost
            min_cost = min(path_costs);
            obj.cost = min_cost;
            
            for n=1:length(obj.all_nodes)
                if obj.all_nodes{n}.isLeaf()
                    
                    % cost_scale
                    cost_scale = obj.all_nodes{n}.path_cost/min_cost;
                    
                    % if it's too big, throw it out!
                    if cost_scale >= obj.PRUNE_FACTOR_BRANCH
                        obj.pruneLeaf(n);
                    end
                    
                end
            end
            
        end
        
        % pruning a leaf
        function pruneLeaf(obj, n)
            % blacklist this child for it's parent node
            obj.all_nodes{n}.prune();
            obj.all_nodes{n} = [];
        end
        
        
    end
    
end














