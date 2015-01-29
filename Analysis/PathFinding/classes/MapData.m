classdef MapData < handle
    %MAPDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        % node information
        endNodePairs = [];
        map_node2idx;
        map_idx2node;
        num_nodes;
        node_neighbors;
        
        % elevation information
        segment_elevations;
        segment_latlngs;
        LATLNG_DSAMPLE = 1;
        ELEV_HPF_FREQN = 1e-5;
        
    end
    
    methods
        % CONSTRUCTOR
        function obj = MapData(mapfile)
                        
            % load all file info
            fileInfo = dir(mapfile);
            % get rid of "." and ".." files
            fileInfo = fileInfo(3:end);
            obj.endNodePairs = [];
            obj.num_nodes = 0;
            obj.map_node2idx = containers.Map('KeyType','int32','ValueType','int32');
            obj.map_idx2node = [];

            % --- pre-fetch all segment nodes ---
            for i = 1:size(fileInfo)
                % get node boundaries of this segment
                fname = fileInfo(i).name;
                split_idx = find(fname == '_');
                node_a = str2double( fname(1:(split_idx-1)) );
                node_b = str2double( fname((split_idx+1):end) );
                
                % if we haven't seen node a, add it to our dictionary!
                if ~isKey(obj.map_node2idx, node_a)
                    obj.num_nodes = obj.num_nodes + 1;
                    obj.map_node2idx(node_a) = obj.num_nodes;
                    obj.map_idx2node = [obj.map_idx2node str2double(node_a)];
                end
                
                % if we haven't seen node b, add it to our dictionary!
                if ~isKey(obj.map_node2idx, node_b)
                    obj.num_nodes = obj.num_nodes + 1;
                    obj.map_node2idx(node_b) = obj.num_nodes;
                    obj.map_idx2node = [obj.map_idx2node str2double(node_b)];
                end
                
                % append to array of node pairs
                na_idx = obj.nodeToIdx(node_a);
                nb_idx = obj.nodeToIdx(node_b);
                obj.endNodePairs = [obj.endNodePairs; [na_idx nb_idx]];
                
            end
            
            % --- load all elevation and lat/lng data ---
            obj.segment_elevations = cell(obj.num_nodes);
            obj.segment_latlngs = cell(obj.num_nodes);
            obj.node_neighbors = cell(obj.num_nodes, 1);
            

            % loop through all segments
            for i = 1:size(obj.endNodePairs,1)
                na_idx = obj.endNodePairs(i,1);
                nb_idx = obj.endNodePairs(i,2);
                % read csv data
                raw = csvread([mapfile fileInfo(i).name]);
                % store elevation from a-->b only
                obj.segment_elevations{na_idx, nb_idx} = ...
                    raw(1:obj.LATLNG_DSAMPLE:end, 1);
                % store lat/lng from a-->b only
                obj.segment_latlngs{na_idx, nb_idx} = ...
                    raw(1:obj.LATLNG_DSAMPLE:end,2:3);
                % add to neighbor lists
                obj.node_neighbors{na_idx} = [obj.node_neighbors{na_idx} nb_idx];
                obj.node_neighbors{nb_idx} = [obj.node_neighbors{nb_idx} na_idx];
            end
            
            %fprintf('finish reading all the trajectories, %d nodes, %d segments\n', num_nodes, numel(endNodePairs))
        end
        
        % ACCESSORS
        function segs = getAllSegments(obj)
            segs = obj.endNodePairs;
        end
        
        function N = getNeighbors(obj, nidx)
            N =  obj.node_neighbors{nidx};
        end
        
        % get a single segment lat/lng
        function latlng = getSegLatLng(obj, seg)
            na_idx = seg(1);
            nb_idx = seg(2);
            % find the data for a-->b, if it doesn't exist, flip b-->a
            if ~isempty( obj.segment_latlngs{na_idx, nb_idx} )
                latlng = obj.segment_latlngs{na_idx, nb_idx};
            elseif ~isempty( obj.segment_latlngs{nb_idx, na_idx} )
                latlng = flipud( obj.segment_latlngs{nb_idx, na_idx} );
            else
                error('specified segment does not exist (getSegLatLng)');
            end
        end
        
        % get a single segment elevation
        function elev = getSegElevation(obj, seg)
            na_idx = seg(1);
            nb_idx = seg(2);
            % find the data for a-->b, if it doesn't exist, flip b-->a
            if ~isempty( obj.segment_elevations{na_idx, nb_idx} )
                elev = obj.segment_elevations{na_idx, nb_idx};
            elseif ~isempty( obj.segment_elevations{nb_idx,na_idx} )
                elev = flipud( obj.segment_elevations{nb_idx, na_idx} );
            else
                error('specified segment does not exist (getSegElevation)');
            end
        end
        
        % get filtered (HPF) elevation segment
        function elev_filt = getSegFilteredElevation(obj, na_idx, nb_idx)
            % high pass filter to remove weather-based variations
            elev_raw = obj.getElevation(na_idx, nb_idx);
            % filter
            [B,A] = butter(1, obj.ELEV_HPF_FREQN, 'high');
            elev_filt = filtfilt(B, A, elev_raw);
        end
        
        % get all elevation for nodes in a list
        function elevs = nodesToElev(obj, nodelist)
            elevs = [];
            
            % loop through all nodes
            for nidx=1:( length(nodelist)-1 )
                seg_elev = obj.getSegElevation(nodelist(nidx), nodelist(nidx+1));
                elevs = [elevs; seg_elev];
            end
            
        end
        
        % get all latitude and longitude for nodes in a listt
        function latlngs = nodesToLatLng(obj, nodelist)
            latlngs = [];
            
            % loop through all nodes
            for nidx=1:( length(nodelist)-1 )
                seg_latlng = obj.getSegLatLng(nodelist(nidx), nodelist(nidx+1));
                latlngs = [latlngs; seg_latlng];
            end
            
        end
        
        % convert local node index to OSM index
        function node = idxToNode(obj, nidx)
            node = obj.map_idx2node(nidx);
        end
        
        % convert OSM index to local matlab index
        function idx = nodeToIdx(obj, node)
            idx = obj.map_node2idx(node);
        end
        
    end
    
end

