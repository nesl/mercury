classdef GraphExplorer < handle
    %GRAPHEXPLORER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % graph root location
        root_loc = [];
        
        % "parent" map object
        map;
        
        % branch pruning percentile
        PRUNE_PERCENTILE_BRANCH = 100;
    
        % score of best branch
        best_score = inf;
        
        % number and list of branches
        num_branches = 0;
        branches = {};
    end
    
    methods
        % CONSTRUCTOR
        function obj = GraphExplorer(map, location, pruning)
            obj.map = map;
            obj.root_loc = location;
            obj.PRUNE_PERCENTILE_BRANCH = pruning;
        end
        
        % TRAVERSAL FUNCTIONS
        function exploreNewNodes(obj)
            
            
        end
        
        function pruneBranches(obj)
            
        end
    end
    
end

