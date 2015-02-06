classdef GraphExplorer < handle
    %GRAPHEXPLORER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % "parent" map object
        map;
        
        % branch pruning percentile
        PRUNE_PERCENTILE_BRANCH = 100;
    
        % score of best branch
        best_score = inf;
        
        % root node
        root;
        
        % keep track of nodes
        all_nodes = {};
    end
    
    methods
        % CONSTRUCTOR
        function obj = GraphExplorer(map, root_idx, pruning)
            obj.map = map;
            obj.PRUNE_PERCENTILE_BRANCH = pruning;
            
            % create root node
            obj.root = GraphNode(nan, root_idx);
            all_nodes = [all_nodes; obj.root];
        end
        
        % TRAVERSAL FUNCTIONS
        function exploreNewNodes(obj)
            for n=1:length(obj.all_nodes)
                % explore from all leaves in this graph
               if n.isLeaf()
                   % get neighbors
                   N = obj.map.getNeighbors(n.node_idx);
                   
               end
            end
            
        end
        
        function pruneBranches(obj)
            
        end
    end
    
end

