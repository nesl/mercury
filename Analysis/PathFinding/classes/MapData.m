classdef MapData < handle
    %MAPDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        % node information
        endNodePairs = [];
        map_node2ind;
        map_ind2node;
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
            obj.map_node2ind = containers.Map('KeyType','int32','ValueType','int32');
            obj.map_ind2node = [];

            % --- pre-fetch all segment nodes ---
            for i = 1:size(fileInfo)
                % get node boundaries of this segment
                fname = fileInfo(i).name;
                split_idx = find(fname == '_');
                node_a = str2double( fname(1:(split_idx-1)) );
                node_b = str2double( fname((split_idx+1):end) );
                % append to array of node pairs
                obj.endNodePairs = [obj.endNodePairs; [node_a node_b]];
                
                % if we haven't seen node a, add it to our dictionary!
                if ~isKey(obj.map_node2ind, node_a)
                    obj.num_nodes = obj.num_nodes + 1;
                    obj.map_node2ind(node_a) = obj.num_nodes;
                    obj.map_ind2node = [obj.map_ind2node str2double(node_a)];
                end
                
                % if we haven't seen node b, add it to our dictionary!
                if ~isKey(obj.map_node2ind, node_b)
                    obj.num_nodes = obj.num_nodes + 1;
                    obj.map_node2ind(node_b) = obj.num_nodes;
                    obj.map_ind2node = [obj.map_ind2node str2double(node_b)];
                end
                
            end
            
            % --- load all elevation and lat/lng data ---
            obj.segment_elevations = cell(obj.num_nodes);
            obj.segment_latlngs = cell(obj.num_nodes);
            obj.node_neighbors = cell(obj.num_nodes, 1);
            
            % loop through all segments
            for i = 1:numel(obj.endNodePairs)
                na_idx = obj.map_node2ind( obj.endNodePairs(i,1) );
                nb_idx = obj.map_node2ind( obj.endNodePairs(i,2) );
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
        function N = getNeighbors(obj, nidx)
            N =  obj.node_neighbors{nidx};
        end
        
        function latlng = getSegLatLng(obj, na_idx, nb_idx)
            % find the data for a-->b, if it doesn't exist, flip b-->a
            if ~isempty( obj.segment_latlngs{na_idx, nb_idx} )
                latlng = obj.segment_latlngs{na_idx, nb_idx};
            else
                latlng = flipud( obj.segment_latlngs{nb_idx, na_idx} );
            end
        end
        
        function elev = getSegElevation(obj, na_idx, nb_idx)
            % find the data for a-->b, if it doesn't exist, flip b-->a
            if ~isempty( obj.segment_elevations{na_idx, nb_idx} )
                elev = obj.segment_elevations{na_idx, nb_idx};
            else
                elev = flipud( obj.segment_elevations{nb_idx, na_idx} );
            end
        end
        
        function elev_filt = getSegFilteredElevation(obj, na_idx, nb_idx)
            % high pass filter to remove weather-based variations
            elev_raw = obj.getElevation(na_idx, nb_idx);
            % filter
            [B,A] = butter(1, obj.ELEV_HPF_FREQN, 'high');
            elev_filt = filtfilt(B, A, elev_raw);
        end
        
        function elevs = nodesToElev(obj, nodelist)
            elevs = [];
            
            % loop through all nodes
            for nidx=1:( length(nodelist)-1 )
                seg_elev = obj.getSegElevation(nodelist(nidx), nodelist(nidx+1));
                elevs = [elevs; seg_elev];
            end
            
        end
        
        function latlngs = nodesToLatLng(obj, nodelist)
            latlngs = [];
            
            % loop through all nodes
            for nidx=1:( length(nodelist)-1 )
                seg_latlng = obj.getSegLatLng(nodelist(nidx), nodelist(nidx+1));
                latlngs = [latlngs; seg_latlng];
            end
            
        end
        
    end
    
end

