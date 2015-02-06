classdef GraphNode < handle
    %GRAPHNODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % parent node
        parent;
        % node index (matlab, not osm)
        node_idx;
        % node children
        children = {};
        map_idx2child = containers.Map('KeyType','int32','ValueType','int32');
    end
    
    methods
        % CONSTRUCTOR
        function obj = GraphNode(parent, nidx)
            obj.parent = parent;
            obj.node_idx = nidx;
        end
        
        % is this a leaf?
        function leaf = isLeaf(obj)
            leaf = isempty(children);
        end
        
        % add children to this node
        function  obj = addChild(child_nidx)
            % add as a child if it's not one already
            if ~isKey(obj.map_idx2child, child_nidx)
                % new node
                obj.children = [obj.children; GraphNode(obj, child_idx)];
                obj.map_idx2child(child_nidx) = length(obj.children);
            end
        end
        
        % remove a child
        function obj = removeChild(child_nidx)
            if isKey(obj.map_idx2child, child_nidx)
                % remove from cell array of children
                obj.children(obj.map_idx2child(child_nidx)) = [];
                % remove dictionary entry
                remove(obj.map_idx2child, child_nidx);
            end
        end
        
        
    end
    
end

