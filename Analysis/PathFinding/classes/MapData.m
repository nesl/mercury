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
        node_elevation;
        node_latlng;
        segment_elevations;
        segment_latlngs;
        segment_allPairDTW;
        segment_length;
        LATLNG_DSAMPLE = 1;
        ELEV_HPF_FREQN = 1e-5;
        
    end
    
    methods
        % CONSTRUCTOR
        % MapData(mapfile)
        % MapData(mapfile, )
        function obj = MapData(mapfile, varargin)
            if numel(varargin) >= 1
                obj.LATLNG_DSAMPLE = varargin{1};
            end
            
            % load all file info
            fileInfo = dir(mapfile);
            % get rid of "." and ".." files
            fileInfo = fileInfo(3:end);
            obj.endNodePairs = [];
            obj.num_nodes = 0;
            obj.map_node2idx = containers.Map('KeyType','int64','ValueType','int32');
            obj.map_idx2node = [];

            % --- pre-fetch all segment nodes ---
            for i = 1:size(fileInfo)
                % get node boundaries of this segment
                fname = fileInfo(i).name;
                split_idx = find(fname == '_');
                node_a = str2num( fname(1:(split_idx-1)) );
                node_b = str2num( fname((split_idx+1):end) );
                
                % if we haven't seen node a, add it to our dictionary!
                if ~isKey(obj.map_node2idx, node_a)
                    obj.num_nodes = obj.num_nodes + 1;
                    obj.map_node2idx(node_a) = obj.num_nodes;
                    obj.map_idx2node = [obj.map_idx2node node_a];
                end
                
                % if we haven't seen node b, add it to our dictionary!
                if ~isKey(obj.map_node2idx, node_b)
                    obj.num_nodes = obj.num_nodes + 1;
                    obj.map_node2idx(node_b) = obj.num_nodes;
                    obj.map_idx2node = [obj.map_idx2node node_b];
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
            obj.node_elevation = zeros(obj.num_nodes, 2);
            obj.node_latlng = zeros(obj.num_nodes, 2);
            
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
                % calculate the geo length in meter
                obj.segment_length{na_idx, nb_idx} = obj.private_getSegmentLength(na_idx, nb_idx);
                % add to neighbor lists
                obj.node_neighbors{na_idx} = [obj.node_neighbors{na_idx} nb_idx];
                obj.node_neighbors{nb_idx} = [obj.node_neighbors{nb_idx} na_idx];
                % fecth the lat/lng for end nodes
                obj.node_elevation(na_idx) = raw(1, 1);
                obj.node_elevation(nb_idx) = raw(end, 1);
                obj.node_latlng(na_idx, :) = raw(1, 2:3);
                obj.node_latlng(nb_idx, :) = raw(end, 2:3);
            end
            
            %fprintf('finish reading all the trajectories, %d nodes, %d segments\n', num_nodes, numel())
        end
        
        % ACCESSORS
        function num = getNumNodes(obj)
            num = obj.num_nodes;
        end
        
        function segs = getAllSegments(obj)
            segs = obj.endNodePairs;
        end
        
        function N = getNeighbors(obj, nidx)
            N =  obj.node_neighbors{nidx};
        end
        
        
        % get --+-- NodeIdx ---+--+-- (Filtered) Elev ----+-- ()
        %       +-- NodeIdxs --+  +------------- LatLng --+
        %       +-- Seg -------+  +------------- Length --+
        %       +-- path ------+
     
        
        % get elevation for solely one node
        function elev = getNodeIdxElev(obj, idx)
            if numel(idx) > 1
                warning('receive multiple indexs in getNodeIdxElev(). Redirect to getNodeIdxsElev()');
            end
            elev = obj.getNodeIdxsElev(idx);
        end
        
        % get lat/lng for solely one node
        function latlng = getNodeIdxLatLng(obj, idx)
            if numel(idx) > 1
                warning('receive multiple indexs in getNodeIdxElev(). Redirect to getNodeIdxsElev()');
            end
            latlng = obj.getNodeIdxsLatLng(idx);
        end
        
        % get elevation of multiple nodes
        function elevs = getNodeIdxsElev(obj, idxs)
            elevs = obj.node_elevation(idxs);
        end
        
        % get lat/lng of multiple nodes
        function latlngs = getNodeIdxsLatLng(obj, idxs)
            latlngs = obj.node_latlng(idxs, :);
        end
        
        
        % get a single segment elevation
        function elev = getSegElev(obj, seg)
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
        function elev_filt = getSegFilteredElevation(obj, seg)
            na_idx = seg(1);
            nb_idx = seg(2);
            % high pass filter to remove weather-based variations
            elev_raw = obj.getElevation(na_idx, nb_idx);
            % filter
            [B,A] = butter(1, obj.ELEV_HPF_FREQN, 'high');
            elev_filt = filtfilt(B, A, elev_raw);
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
        
        % get length of one segment
        function meter = getSegLength(obj, seg)
            na_idx = seg(1);
            nb_idx = seg(2);
            % find the data for a-->b, if it doesn't exist, flip b-->a
            if ~isempty( obj.segment_length{na_idx, nb_idx} )
                meter = obj.segment_length{na_idx, nb_idx};
            elseif ~isempty( obj.segment_length{nb_idx, na_idx} )
                meter = obj.segment_length{nb_idx, na_idx};
            else
                error('specified segment does not exist (getSegLength)');
            end
        end
        
        % get elevation over the path specified the node idxs in a list
        function elevs = getPathElev(obj, nidxList)
            elevs = [];
            
            % loop through all nodes
            for nidx=1:( length(nidxList)-1 )
                seg_elev = obj.getSegElev(  nidxList( nidx:(nidx+1) ) );
                elevs = [elevs; seg_elev];
            end
            
        end
        
        % get all latitude and longitude for nodes in a list
        function latlngs = getPathLatLng(obj, nidxList)
            latlngs = [];
            
            % loop through all nodes
            for nidx=1:( length(nidxList)-1 )
                seg_latlng = obj.getSegLatLng( nidxList( nidx:(nidx+1) ) );
                latlngs = [latlngs; seg_latlng];
            end
        end
        
        % get length of a path
        function meter = getPathLength(obj, nidxList)
            meter = 0;
            for nidx=1:( length(nidxList)-1 )
                meter = meter + obj.getSegLength( nidxList( nidx:(nidx+1) ) );
            end
        end
        
        % QUERY BY GEO INFORMATION
        function meter = distanceToNodeIdx(obj, latlng, nodeIdx)
            meter = latlng2m(latlng, obj.getNodeIdxLatLng(nodeIdx));
        end
        
        function meter = distanceToSeg(obj, latlng, seg)
            segLatLngs = obj.getSegLatLng(seg);
            meter = inf;
            for i = 1:size(segLatLngs, 1)
                tdis = latlng2m(latlng, segLatLngs(i,:));
                meter = min(tdis, meter);
            end    
        end
        
        function retIdx = getNearestNodeIdx(obj, latlng)
            retIdx = 1;
            dis = inf;
            for nidx = 1:obj.num_nodes
                tdis = latlng2m(latlng, obj.getNodeIdxLatLng(nidx));
                if tdis < dis
                    dis = tdis;
                    retIdx = nidx;
                end
            end
        end
        
        function retSeg = getNearestSeg(obj, latlng)
            dis = inf;
            segIdx = 1;
            for i = 1:size(obj.endNodePairs, 1)
                tdis = obj.distanceToSeg(latlng, obj.endNodePairs(i,:));
                if tdis < dis
                    segIdx = i;
                    dis = tdis;
                end
            end
            retSeg = obj.endNodePairs(segIdx, :);
        end
        
        function nodeIdxs = findShortestPath(obj, ns_idx, ne_idx)  %% UNTESTED
            dis = containers.Map();
            from = containers.Map();
            dis(ns_idx) = 0;
            trackList = ns_idx;
            for i = 1:1000
                % find next shortest-distance node
                len = length(trackList);
                chooseIdx = i;
                minDis = dis( trackList(chooseIdx) );
                for j = (i+1):len
                    tmpDis = dis( trackList(j) );
                    if tmpDis < minDis
                        minDis = tmpDis;
                        chooseIdx = j;
                    end
                end
                trackList([i chooseIdx]) = trackList([chooseIdx i]);
                if trackList(i) == ne_idx  % reach goal
                    % back-tracking
                    nodeIdxs = trackList(i);
                    while nodeIdxs(1) ~= ns_idx
                        nodeIdxs = [ from(nodeIdxs(1)) nodeIdxs ];
                    end
                    return;
                end
                
                % if it doesn't return, means that we need to keep search
                curIdx = trackList(i);
                curDis = minDis;
                for neighbor = obj.getNeighbors()
                    nextDis = curDis + obj.getSegLength(curIdx, neighbor);
                    if ~iskey(dis, neighbor)
                        dis(neighbor) = inf;
                        trackList = [trackList neighbor];
                    end
                    if dis(neighbor) > nextDis
                        dis(neighbor) = nextDis;
                        from(neighbor) = curIdx;
                    end
                end
            end
            error('hmm... it seems you give me a big challenge... (findShortestPath())');
        end
        
        function retNodeIdxs = findApproximatePathOverMap(obj, latlngs)
            % this method finds the closest node of every lat/lng, and then
            % based on this information to find the shortest path
            numLatLngs = size(latlngs, 1);
            closestNodeIdxs = zeros(1, numLatLngs);
            for i = 1:numLatLngs
                closestNodeIdxs(i) = obj.getNearestNodeIdx(latlngs(i,:));
            end
            criticalNodeIdxs = closestNodeIdxs(1);
            for i = 1:(numel(closestNodeIdxs)-1)
                if closestNodeIdxs(i+1) ~= closestNodeIdxs(i)
                    criticalNodeIdxs = [criticalNodeIdxs closestNodeIdxs(i+1)];
                end
            end
            for i = 1:numel(criticalNodeIdxs)
                % TODO
            end
        end
        
        % INDEX SYSTEM CONVERSION
        % convert local node index to OSM index
        function node = idxToNode(obj, nidx)
            node = obj.map_idx2node(nidx);
        end
        
        % convert OSM index to local matlab index
        function idx = nodeToIdx(obj, node)
            idx = obj.map_node2idx(node);
        end
        
        % METHODS REGARDING ALL PAIRS DTW
        function preProcessAllPairDTW(obj, elevFromBaro)
            obj.segment_allPairDTW = cell(obj.num_nodes);
            numPairs = size(obj.endNodePairs, 1);
            for i = 1:numPairs
                na_idx = obj.endNodePairs(i, 1);
                nb_idx = obj.endNodePairs(i, 2);
                fprintf('calculating dtw of traj(%d, %d)\n', na_idx, nb_idx);
                obj.segment_allPairDTW{na_idx, nb_idx} = all_pair_dtw_baro( ...
                    obj.getSegElev(obj.endNodePairs(i,:)), elevFromBaro);
            end
        end
        
        % [ square_matrix ] = queryAllPairDTW(obj, na_idx, nb_idx)
        % [   row_vector  ] = queryAllPairDTW(obj, na_idx, nb_idx, start_step)  // end_step=any
        % [  single_value ] = queryAllPairDTW(obj, na_idx, nb_idx, start_step, end_step)
        function res = queryAllPairDTW(obj, na_idx, nb_idx, varargin)
            % switch index if there's no segment of <na_idx, nb_idx>
            if numel(obj.segment_allPairDTW{na_idx, nb_idx}) == 0
                t = na_idx;   na_idx = nb_idx;   nb_idx = t;
            end
            if numel(varargin) == 0
                res = obj.segment_allPairDTW{na_idx, nb_idx};
            elseif numel(varargin) == 1
                res = obj.segment_allPairDTW{na_idx, nb_idx}( varargin{1}, varargin{1}:end );
            else
                res = obj.segment_allPairDTW{na_idx, nb_idx}( varargin{1}, varargin{2} );
            end
        end
        
        
        % +-----------------+
        % | PRIVATE METHODS |
        % +-----------------+
        
        % get segment length
        function meter = private_getSegmentLength(obj, na_idx, nb_idx)
            meter = 0;
            numElements = size( obj.segment_latlngs{na_idx, nb_idx}, 1);
            for i = 1:(numElements-1)
                meter = meter + latlng2m( obj.segment_latlngs{na_idx, nb_idx}(i,:), ...
                    obj.segment_latlngs{na_idx, nb_idx}(i+1, :) );
            end
        end
    end
    
end

