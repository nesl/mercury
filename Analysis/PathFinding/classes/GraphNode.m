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
        % path cost (leaf nodes only)
        path_cost;
        % node children
        children = {};
        map_idx2child = containers.Map('KeyType','int32','ValueType','int32');
        % blacklist of children that should not be visited again
        blacklist_nodes = [];
        % is this node a dead end? i.e. have all children been blacklisted?
        deadend = false;
        
    end
    
    methods
        % CONSTRUCTOR
        function obj = GraphNode(parent, nidx)
            obj.parent = parent;
            obj.node_idx = nidx;
            if ~isempty(parent)
                obj.path = [parent.path; nidx];
            else
                obj.path = nidx;
            end
        end
        
        % get the path
        function p = getPath(obj)
            p = obj.path;
        end
        
        % is this a leaf?
        function l = isLeaf(obj)
            l = isempty(obj.children);
        end
        
        % is this a root
        function p = isRoot(obj)
            p = isnan(obj.parent);
        end
        
        
        % prune and blacklist this child from its parent
        function prune(obj)
            obj.parent.blacklist(obj.node_idx);
        end
        
        % blacklist a child of this node
        function blacklist(obj, child_idx)
            if isKey(obj.map_idx2child, child_idx)
                % blacklist the child node
                obj.blacklist_nodes = [obj.blacklist_nodes; child_idx];
                % remove the child
                %    never "delete" the child object, or the map idx2child
                %    will be wrong and need to be fixed! so we just clear it.
                obj.children{ obj.map_idx2child(child_idx) } = [];
                % remove the dictionary entry
                remove(obj.map_idx2child, child_idx);
            end
        end
        
        % is this node blacklisted?
        function val = isChildBlacklisted(obj, child_idx)
            val = ~isempty( find(obj.blacklist_nodes == child_idx) );
        end
        
        % set this node as a dead end (all children blacklisted)
        function obj = setDeadend(obj)
            obj.deadend = true;
        end
        
        % is this node a deadend?
        function val = isDeadend(obj)
            val = obj.deadend;
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
        function  obj = addChild(obj, child_obj)
            child_idx = child_obj.node_idx;
            % add as a child if it's not one already
            if ~isKey(obj.map_idx2child, child_idx)
                % new child
                obj.children = [obj.children; {child_obj}];
                obj.map_idx2child(child_idx) = length(obj.children);
            end
        end
        
        % remove a child
        function obj = removeChild(obj, child_obj)
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

