classdef GraphNode < handle
    %GRAPHNODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % parent node
        parent;
        % node index (matlab, not osm)
        node_idx;
        % full path
        path;
        % node children
        children = {};
        map_idx2child = containers.Map('KeyType','int32','ValueType','int32');
    end
    
    methods
        % CONSTRUCTOR
        function obj = GraphNode(parent, nidx)
            obj.parent = parent;
            obj.node_idx = nidx;
            if ~isnan(parent)
                obj.path = [parent.path; nidx];
            else
                obj.path = nidx;
            end
        end
        
        % is this a leaf?
        function l = isLeaf(obj)
            l = isempty(obj.children);
        end
        
        % is this a root
        function p = isRoot(obj)
            p = isnan(obj.parent);
        end
        
        % upstream traversal to find loops
        function visited = findUpstreamNode(obj, nidx, min_loop_len)
            % find target node in path
            idx = find(obj.path == nidx,1,'last');
            if isempty(idx)
                visited = false;
                return;
            elseif length(obj.path) - idx > min_loop_len
                visited = false;
                return;
            else
                visited = true;
                return;
            end
        end

        
        % add children to this node
        function  obj = addChild(child_obj)
            child_idx = child_obj.node_idx;
            % add as a child if it's not one already
            if ~isKey(obj.map_idx2child, child_idx)
                % new child
                obj.children = [obj.children; child_obj];
                obj.map_idx2child(child_idx) = length(obj.children);
            end
        end
        
        % remove a child
        function obj = removeChild(child_obj)
            child_idx = child_obj.node_idx;
            if isKey(obj.map_idx2child, child_idx)
                % remove from cell array of children
                obj.children(obj.map_idx2child(child_idx)) = [];
                % remove dictionary entry
                remove(obj.map_idx2child, child_idx);
            end
        end
        
        
    end
    
end

