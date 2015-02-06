classdef GraphExplorer < handle
    %GRAPHEXPLORER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % "parent" map object
        map;
        
        % sensor data object
        sensor;
        
        % branch pruning percentile
        PRUNE_PERCENTILE_BRANCH = 100;
        
        % branch loop reduction
        MIN_BRANCH_LOOP_LENGTH = 10;
    
        % score of best branch
        best_score = inf;
        
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
            obj.PRUNE_PERCENTILE_BRANCH = pruning;
            
            % create root node
            obj.root = GraphNode(nan, root_idx);
            all_nodes = [all_nodes; obj.root];
        end
        
        % EXPLORING NEW NODES
        function exploreNewNodes(obj)
            
            for n=1:length(obj.all_nodes)
                node = obj.all_nodes{n};
                % explore from all leaves in this graph
                if node.isLeaf()
                    % get neighbors
                    N = obj.map.getNeighbors(node.node_idx);
                    % loop through all neighbors
                    for i=1:length(N)
                        % have we visited this node recently?
                        neighbor_idx = N(i);
                        visited = node.findUpstreamNode(neighbor_idx,...
                                obj.MIN_BRANCH_LOOP_LENGTH);
                        % if not, let's add it as a child
                        if ~visited
                            % create a new child node
                            child_node = GraphNode(node, neighbor_idx);
                            node.addChild(child_node);
                        end
                    end
               end
            end
        end
        
        % DETERMINE THE COST OF A GIVEN PATH
        function calculatePathCost(obj, leaf_node)
            path_nodes = leaf_node.path;
            
            % get elevation
            elevations = obj.map.getPathElev(path_nodes);
            
            % get turns
            turns = obj.map.getPathTurns(path_nodes);
            
            % get elevation cost
            
            % get turn cost
            
            % combine costs
            
            % TODO !!!
            
            
        end
        
        % DETERMINE THE COST OF ALL NEW PATHS
        function calculateNewPathCosts(obj, new_leaf_nodes)
            % TODO !!!
        end
        
        
        
        function pruneBranches(obj)
            
        end
        
        
    end
    
end

