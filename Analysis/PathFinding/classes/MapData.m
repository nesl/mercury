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
        segment_num_elements;
        segment_allPairDTW;
        segment_length;  % don't be confused. this is physical length as the unit is meter.
        LATLNG_DSAMPLE = 1;
        ELEV_HPF_FREQN = 1e-5;
        
    end
    
    methods
        % CONSTRUCTOR
        % MapData(mapfile)
        % MapData(mapfile, latlngDownSampleStep)
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
            obj.segment_length = cell(obj.num_nodes);
            obj.segment_num_elements = zeros(obj.num_nodes);
            obj.node_neighbors = cell(obj.num_nodes, 1);
            obj.node_elevation = zeros(obj.num_nodes, 2);
            obj.node_latlng = zeros(obj.num_nodes, 2);
            
            % loop through all segments
            for i = 1:size(obj.endNodePairs,1)
                na_idx = obj.endNodePairs(i,1);
                nb_idx = obj.endNodePairs(i,2);
                % read csv data
                raw = csvread([mapfile fileInfo(i).name]);
                rawNumRows = size(raw, 1);
                rawIdx = [1:obj.LATLNG_DSAMPLE:(rawNumRows-1)  rawNumRows];  % in case of down sampling, always make sure to include the end node
                % store elevation from a-->b only
                obj.segment_elevations{na_idx, nb_idx} = raw(rawIdx, 1);
                % store lat/lng from a-->b only
                obj.segment_latlngs{na_idx, nb_idx} = raw(rawIdx, 2:3);
                % calculate the geo length in meter
                obj.segment_length{na_idx, nb_idx} = obj.private_getSegmentLength(na_idx, nb_idx);
                % store number of elements of each segment
                obj.segment_num_elements(na_idx, nb_idx) = numel(rawIdx);
                obj.segment_num_elements(nb_idx, na_idx) = numel(rawIdx);
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
        
        function lines = getAllSegLatLng(obj)
            lines = {};
            segs = obj.getAllSegments();
            for sidx=1:length(segs)
                latlng = obj.getSegLatLng(segs(sidx,:));
                lines = [lines; {latlng}];
            end
        end
        
        function N = getNeighbors(obj, nidx)
            N = obj.node_neighbors{nidx};
        end
        
        
        % get --+-- NodeIdx ---+--+-- (Filtered) Elev --------+-- ()
        %       +-- NodeIdxs --+  +------------- LatLng ------+
        %       +-- Seg -------+  +------------- Length ------+
        %       +-- path ------+  +------------- NumElement --+
     
        % get node indexes of OSM nodes
        function nlist = getNodeIdxs(obj, osm_nodes)
           nlist = zeros(length(osm_nodes), 1);
           for i=1:length(osm_nodes)
              nlist(i) = obj.nodeToIdx(osm_nodes(i)); 
           end
        end
        
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
                warning('receive multiple indexs in getNodeIdxElev(). Redirect to getNodeIdxsLatLng()');
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
        
        % get length (geo distance) of one segment
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
        
        % get number of elements in this segment
        function numElement = getSegNumElement(obj, seg)
            na_idx = seg(1);
            nb_idx = seg(2);
            numElement = obj.segment_num_elements(na_idx, nb_idx);
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
        
        % get elevation changes (derivative) over the path specified by
        % node idxs in a list
        function dElevs = getPathElevDeriv(obj, nidxList)
            elevs = obj.getPathElev(nidxList);
            % filter elevations and take derivative (can't filter <= 6)
            if length(elevs) > 6
                [b,a] = butter(2, 0.1);
                fElevs = filtfilt(b,a,elevs);
            else
                fElevs = elevs;
            end
            SCALE = 20;
            dElevs = SCALE*diff(fElevs);
        end
        
        % get angle sequence for a given node list / path
        function angles = getPathAngles(obj, nidxList)
            if isempty(nidxList)
                error('node list is empty (getPathTurns)');
            end
            
            % initialize empty deltaAngle vector
            angles = [];
            
            % starting point
            latlng_last = [];
           
            for i=1:( length(nidxList) - 1 )
                % get segment nodes
                nidx_a = nidxList(i);
                nidx_b = nidxList(i+1);
                % get lat/lng array
                segLatLng = obj.getSegLatLng([nidx_a nidx_b]);
                
                for j=1:size(segLatLng,1)
                    % lat = y, lng = x
                    latlng = segLatLng(j,:);
                   % check for starting point
                   if i==1 && j==1
                       latlng_last = latlng;
                       continue;
                   end
                   
                   % check for zero movement (latlng too close to latlng_last)
                   if (latlng - latlng_last < 0.01e-5)
                       latlng_last = latlng;
                       continue;
                   end
                   
                   disp_norm = (latlng - latlng_last)./norm( latlng - latlng_last );
                   theta = atan2d(disp_norm(1), disp_norm(2));
                   
                   angles = [angles; theta];
                   
                   % recycle this lat/lng pair
                   latlng_last = latlng;
                end
                
            end
            
            % add one more to the angles list to make it the same size
            angles = [angles; angles(end)];
            
            % smooth out angles
            [b,a] = butter(1,0.5);
            angles = filtfilt(b,a,angles);
        end
        
        % get turn sequence for a node list
        function turns = getPathTurns(obj, nidxList)
            % get absolute path angles
            angles = obj.getPathAngles(nidxList);
            % smooth out these angles
            
            turns = diff(angles);
            
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
        
        % ESTIMATE MAP TURNS
        function turns = getTurnsFromNodes(obj, nidxList)
            % get the lat/lng first
            latlngs = obj.getPathLatLng(nidxList);
            % now find absolute turns
            angles = [];
            for i=2:size(latlngs,1)
                angle = atan2d( latlngs(i,1)-latlngs(i-1,1), latlngs(i,2)-latlngs(i-1,2) );
                angles = [angles; angle];
            end
            
            % and then relative turns
            dAngles = zeros(size(angles));
            for i=2:length(angles)
                dAngle = angles(i) - angles(i-1);
                dAngles(i) = dAngle;
            end
            
            % and finally window these turns
            wlen = 5;
            SCALE = 0.2;
            turns = [];
            for i=1:(length(dAngles)-wlen)
                turns = [turns;
                    SCALE*sum(dAngles(i:(i+wlen)))];
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
        
        function nodeIdxs = findShortestPath(obj, ns_idx, ne_idx)
            dis = containers.Map('KeyType','int32','ValueType','double');
            from = containers.Map('KeyType','int32','ValueType','int32');
            dis(ns_idx) = 0;
            from(ns_idx) = 0;
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
                %i
                %trackList
                trackList([i chooseIdx]) = trackList([chooseIdx i]);
                %trackList
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
                %[curIdx curDis]
                %obj.getNeighbors(curIdx)
                %[-1 -1 obj.num_nodes size(obj.segment_length)]
                for neighbor = obj.getNeighbors(curIdx)
                    nextDis = curDis + obj.getSegLength( [curIdx neighbor] );
                    %keys(dis)
                    %keys(from)
                    %neighbor
                    if ~isKey(dis, neighbor)
                        dis(neighbor) = inf;
                        trackList = [trackList neighbor];
                        %fprintf('add %d\n', neighbor);
                    end
                    if dis(neighbor) > nextDis
                        dis(neighbor) = nextDis;
                        from(neighbor) = curIdx;
                    end
                    %keys(dis)
                    %keys(from)
                    %neighbor
                    %[ 0 0 curIdx curDis neighbor dis(neighbor) from(neighbor)]
                end
            end
            error('hmm... it seems you give me a big challenge... (findShortestPath())');
        end
        
        function retNodeIdxs = findApproximatePathOverMapByLatLng(obj, latlngs)
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
            retNodeIdxs = obj.findApproximatePathOverMapByNodeIdxs(criticalNodeIdxs);
        end
        
        function retNodeIdxs = findApproximatePathOverMapByNodeIdxs(obj, nodeIdxs)
            numNodes = numel(nodeIdxs);
            retNodeIdxs = [];
            for i = 1:(numNodes-1)
                tmpSegPath = obj.findShortestPath( nodeIdxs(i), nodeIdxs(i+1) );
                retNodeIdxs = [retNodeIdxs tmpSegPath(1:end-1)];
            end
            retNodeIdxs = [retNodeIdxs nodeIdxs(end)];
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

