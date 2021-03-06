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
        segment_start_orientation;   % a==----->b,  orientation of == part 
        segment_end_orientation;     % a-----==>b
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
            
            obj.endNodePairs = [];
            obj.num_nodes = 0;
            obj.map_node2idx = containers.Map('KeyType','int64','ValueType','int32');
            obj.map_idx2node = [];
            
            % read from the map file. It's not a folder any more
            fid = fopen(mapfile);
            tline = fgets(fid);
            lineIdx = 1;
            segStructures = {};
            while ischar(tline)
                %disp(tline)
                tline = tline(1:end-1);
                terms = strsplit(tline, ',');
                numTerms = numel(terms);
                if mod(numTerms, 3) ~= 2
                    error(['Incorrect number of elements at line ' num2str(lineIdx) ' (constructor of MapData)']);
                end
                
                values = cell2mat(cellfun(@(x) str2num(x), terms, 'un', 0));
                node_a = values(1);
                node_b = values(2);
                if node_a == node_b
                    error(['Same source and destination at line ' num2str(lineIdx) ' (constructor of MapData)']);
                end
                numPoints = (numTerms - 2) / 3;
                data = reshape(values(3:end), [3 numPoints])';
                
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
                
                % create segment structure
                tmpSegStructure = [];
                tmpSegStructure.na_idx = na_idx;
                tmpSegStructure.nb_idx = nb_idx;
                tmpSegStructure.data = data;
                segStructures{lineIdx} = tmpSegStructure;

                
                % for next iteration
                tline = fgets(fid);
                lineIdx = lineIdx + 1;
            end
            fclose(fid);
            
            if numel(segStructures) == 0
                error('The specified map folder is not existed or empty folder (constructor of MapData)');
            end
            
            fprintf('Map file parsed\n');
      
            % --- load all elevation and lat/lng data ---
            obj.segment_elevations = cell(obj.num_nodes);
            obj.segment_latlngs = cell(obj.num_nodes);
            obj.segment_length = cell(obj.num_nodes);
            obj.segment_num_elements = zeros(obj.num_nodes);
            obj.segment_start_orientation = nan(obj.num_nodes);
            obj.segment_end_orientation = nan(obj.num_nodes);
            obj.node_neighbors = cell(obj.num_nodes, 1);
            obj.node_elevation = zeros(obj.num_nodes, 1);
            obj.node_latlng = zeros(obj.num_nodes, 2);
            
            % loop through all segments
            for i = 1:numel(segStructures)
                na_idx = segStructures{i}.na_idx;
                nb_idx = segStructures{i}.nb_idx;
                raw = segStructures{i}.data;
                rawNumRows = size(raw, 1);
                rawIdx = [1:obj.LATLNG_DSAMPLE:(rawNumRows-1)  rawNumRows];  % in case of down sampling, always make sure to include the end node
                % store elevation from a-->b only
                obj.segment_elevations{na_idx, nb_idx} = raw(rawIdx, 1);
                % store lat/lng from a-->b only
                obj.segment_latlngs{na_idx, nb_idx} = raw(rawIdx, 2:3);
                % store the orientation from any pair a-->b
                tmpLatLng = obj.segment_latlngs{na_idx, nb_idx}(1:2, :);
                obj.segment_start_orientation(na_idx, nb_idx) = ...
                    atan2d(tmpLatLng(2, 1) - tmpLatLng(1, 1), tmpLatLng(2, 2) - tmpLatLng(1, 2));
                tmpLatLng = obj.segment_latlngs{na_idx, nb_idx}(end-1:end, :);
                obj.segment_end_orientation(na_idx, nb_idx) = ...
                    atan2d(tmpLatLng(2, 1) - tmpLatLng(1, 1), tmpLatLng(2, 2) - tmpLatLng(1, 2));
                obj.segment_start_orientation(nb_idx, na_idx) = obj.segment_end_orientation(na_idx, nb_idx) - 180;
                if obj.segment_start_orientation(nb_idx, na_idx) < -180
                    obj.segment_start_orientation(nb_idx, na_idx) = obj.segment_start_orientation(nb_idx, na_idx) + 360;
                end
                obj.segment_end_orientation(nb_idx, na_idx) = obj.segment_start_orientation(na_idx, nb_idx) - 180;
                if obj.segment_end_orientation(nb_idx, na_idx) < -180
                    obj.segment_end_orientation(nb_idx, na_idx) = obj.segment_end_orientation(nb_idx, na_idx) + 360;
                end
                
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
            
            fprintf('finish reading all the trajectories, %d nodes, %d segments\n', obj.num_nodes, numel(segStructures));
        end
        
        % ACCESSORS
        function num = getNumNodes(obj)
            num = obj.num_nodes;
        end
        
        function segs = getAllSegments(obj)
            segs = obj.endNodePairs;
        end
        
        function num = getNumSegments(obj)
            num = size(obj.endNodePairs, 1);
        end
        
        function lines = getAllSegLatLng(obj)
            lines = {};
            segs = obj.getAllSegments();
            for sidx=1:length(segs)
                latlng = obj.getSegLatLng(segs(sidx,:));
                lines = [lines; {latlng}];
            end
        end
        
        function N = getNeighbors(obj, nidx)  % returns a row vector of neighbors
            N = obj.node_neighbors{nidx};
        end
        
        
        % get --+-- NodeIdx ---+--+-- (Filtered) Elev --------+-- ()
        %       +-- NodeIdxs --+  +------------- LatLng ------+
        %       +-- Seg -------+  +------------- Length ------+
        %       +-- path ------+  +------------- NumElement --+
     
        
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
                error(['specified segment does not exist: ' num2str(na_idx) ', ' num2str(nb_idx)]);
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
        
%         % get angle sequence for a given node list / path
%         function angles = getPathAngles(obj, nidxList)
%             if isempty(nidxList)
%                 error('node list is empty (getPathTurns)');
%             end
%             
%             % initialize empty deltaAngle vector
%             angles = [];
%             
%             % starting point
%             latlng_last = [];
%            
%             for i=1:( length(nidxList) - 1 )
%                 % get segment nodes
%                 nidx_a = nidxList(i);
%                 nidx_b = nidxList(i+1);
%                 % get lat/lng array
%                 segLatLng = obj.getSegLatLng([nidx_a nidx_b]);
%                 
%                 for j=1:size(segLatLng,1)
%                     % lat = y, lng = x
%                     latlng = segLatLng(j,:);
%                    % check for starting point
%                    if i==1 && j==1
%                        latlng_last = latlng;
%                        continue;
%                    end
%                    
%                    % check for zero movement (latlng too close to latlng_last)
%                    if (latlng - latlng_last < 0.01e-5)
%                        latlng_last = latlng;
%                        continue;
%                    end
%                    
%                    disp_norm = (latlng - latlng_last)./norm( latlng - latlng_last );
%                    theta = atan2d(disp_norm(1), disp_norm(2));
%                    
%                    angles = [angles; theta];
%                    
%                    % recycle this lat/lng pair
%                    latlng_last = latlng;
%                 end
%                 
%             end
%             
%             % add one more to the angles list to make it the same size
%             angles = [angles; angles(end)];
%             
%             % smooth out angles
%             [b,a] = butter(1,0.5);
%             angles = filtfilt(b,a,angles);
%         end
        
        % ESTIMATE MAP TURNS
        function angle = getAdjacentSegmentsAngle(obj, path)
            % the path should have exactly 3 elements, which composes
            % exactly 2 segments.
            angle = obj.segment_start_orientation( path(2), path(3) ) ...
                - obj.segment_end_orientation( path(1), path(2) );
            if angle >= 180
                angle = angle - 360;
            end
            if angle <= -180
                angle = angle + 360;
            end
        end
        
        
        function turns = getPathTurnVector(obj, nidxList)
            events = obj.getPathTurns(nidxList);
            latlngs = obj.getPathLatLng(nidxList);
            turns = zeros( size(latlngs,1), 1);
            if ~isempty(events)
                turns(events(:,1),:) = events(:,2);
            end
        end
        
        function turns = getPathTurns(obj, nidxList)
            thresh = 25;
            % get the lat/lng first
            latlngs = obj.getPathLatLng(nidxList);
            
            % now find absolute angles
            angles = [];
            for i=2:size(latlngs,1)
                % if latlng didn't change, continue
                if latlngs(i,1) - latlngs(i-1,1) == 0 &&...
                        latlngs(i,2) - latlngs(i-1,2) == 0
                    continue;
                end
                angle = atan2d( latlngs(i,1)-latlngs(i-1,1), latlngs(i,2)-latlngs(i-1,2) );
                angles = [angles; [i, angle]];
            end
            
            
            % find turns
            turns = [];
            decay = 7;
            angle_last = angles(1,2);
            
            for i=2:size(angles,1)
                change_since_last = angles(i,2) - angle_last;
                decay_idx = max(1, i-decay);
                change_since_decay = angles(i,2) - angles(decay_idx,2);
                
                if abs(change_since_last) > abs(change_since_decay)
                    change = change_since_decay;
                else
                    change = change_since_last;
                end
                
                
                if abs(change) > thresh
                    turns = [turns; [angles(i,1) change]];
                    angle_last = angles(i,2);
                end
            end
            
            
            % combine clusters of turns
            csize = 7;
            
            for i=1:size(turns,1)
                if i > size(turns,1)
                    break;
                end
                idx = turns(i,1);
                close_idxs = find( turns(:,1) > idx & turns(:,1) - idx < csize);
                total = sum(turns([i; close_idxs],2));
                total = mod( total+180, 360) - 180;
                turns(i,:) = [idx,total];
                turns(close_idxs,:) = [];
                
            end
            
            if ~isempty(turns)
                turns( abs(turns(:,2)) < thresh, :) = [];
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
        
        % pick a random node (to start random walk)
        function node = getRandomNode(obj)
            node = randi(obj.num_nodes,1);
        end
        
        
        % RANDOM WALK
        
        % This function returns a path of random walk. It starts from
        % startNodeIdx. If startNodeIdx is set as a negative value, then
        % the function will randomly pick a starting node. pathLength
        % refers to how many elevation points do you want. If
        % allowImmediateBack is set, then the path may contain the
        % go-and-forth pattern such as <a>--<b>--<a>. We decide to make the
        % function returns a path (i.e., a series of nodeIdx) since the
        % consumer can easily extract the elevations by getPathElev(). Also
        % the full elevation path can be slightly longer than the desired
        % length. However, the consumer can easily truncate the redundant
        % ones.
        function path = getRandomWalk(obj, startNodeIdx, pathLength, allowImmediateBack)
            if startNodeIdx >= 0
                cur_node = startNodeIdx;
            else
                cur_node = round(1 + (obj.num_nodes - 1)*rand(1));
            end
            prev_node = -1;  % previous node doesn't exist
            
            curLength = 0;
            path = cur_node;
            while curLength < pathLength
                next_nodes = obj.getNeighbors(cur_node);
                rand_steps = randperm(numel(next_nodes));
                if ~allowImmediateBack
                    while numel(rand_steps) > 0 && next_nodes(rand_steps(1)) == prev_node  % exclude going back case
                        rand_steps = rand_steps(2:end);
                    end
                end
                if numel(rand_steps) == 0  % omg, cannot go any further. roll back
                    stepsToGetBack = ceil(rand() * 6);
                    stepsToGetBack = min(stepsToGetBack, numel(path) - 1);
                    while stepsToGetBack > 0
                        curLength = curLength - numel(obj.getSegElev([path(end) path(end-1)])) + 1;
                        %path
                        path = path(1:end-1);
                        %path
                        stepsToGetBack = stepsToGetBack - 1;
                    end
                    if numel(path) == 1
                        prev_node = -1;
                    else
                        prev_node = path(end-1);
                    end
                    cur_node = path(end);
                else
                    prev_node = cur_node;
                    cur_node = next_nodes(rand_steps(1));
                    curLength = curLength + numel(obj.getSegElev([prev_node cur_node])) - 1;
                    path = [path; cur_node];
                end
                %path
                %fprintf('%d\n', curLength);
                %pause
            end
        end
        
        function path = getRandomWalkConstrainedByTurn(obj, startNodeIdx, pathLength, allowImmediateBack, avgLengthPerTurn)
            if startNodeIdx >= 0
                path = startNodeIdx;
            else
                path = round(1 + (obj.num_nodes - 1)*rand(1));
            end
            
            curLength = 0;
            
            probNoTurnPerNode = 1 - 1/avgLengthPerTurn;
            probStraight = 1;
            strike = 0;
            while curLength < pathLength
                cur_node = path(end);
                next_nodes = obj.getNeighbors(cur_node);
                
                if numel(path) == 1
                    prev_node = -1;  % previous node doesn't exist
                else
                    prev_node = path(end-1);
                end
            
                if ~allowImmediateBack
                    next_nodes = next_nodes(next_nodes ~= prev_node);
                end
                
                angles = zeros(size(next_nodes));  % by default, assume that I don't need take turns to reach my neighbors. Especially handle no previous node case
                if prev_node ~= -1  % there's a previous node
                    for i = 1:numel(next_nodes)
                        angles(i) = obj.getAdjacentSegmentsAngle( [path(end-1:end) next_nodes(i)] );
                    end
                end
                
                %path
                %next_nodes
                %angles
                shouldIGoStraight = (rand() < probStraight(end));
                if shouldIGoStraight
                    threshold = 45 * (1.1 ^ strike(end));
                    possibleNeighborIdxs = (-threshold <= angles & angles <= threshold);
                else
                    threshold = 45 / (1.1 ^ strike(end));
                    possibleNeighborIdxs = (angles < -threshold | angles > threshold);
                end
                possibleNeighbors = next_nodes(possibleNeighborIdxs);
                
                if numel(possibleNeighbors) == 0  % omg, cannot go any further. roll back
                    stepsToGetBack = ceil(rand() * 6);
                    stepsToGetBack = min(stepsToGetBack, numel(path) - 1);
                    while stepsToGetBack > 0
                        curLength = curLength - numel(obj.getSegElev([path(end) path(end-1)])) + 1;
                        %path
                        path         = path(1:end-1);
                        probStraight = probStraight(1:end-1);
                        strike       = strike(1:end-1);
                        %[path ;probStraight; strike]
                        stepsToGetBack = stepsToGetBack - 1;
                    end
                    strike(end) = strike(end)+1;
                else
                    selectedNode = possibleNeighbors( ceil(rand() * numel(possibleNeighbors)) );
                    segLength = numel(obj.getSegElev([cur_node selectedNode])) - 1;
                    curLength = curLength + numel(obj.getSegElev([cur_node selectedNode])) - 1;
                    path(end+1) = selectedNode;
                    probStraightAfterSeg = probNoTurnPerNode ^ segLength;
                    if shouldIGoStraight
                        probStraight(end+1) = probStraight(end) * probStraightAfterSeg;
                    else
                        probStraight(end+1) = probStraightAfterSeg;
                    end
                    strike(end+1) = floor(strike(end) / 3);
                end
                %path
                %[path ;probStraight; strike]
                %fprintf('%d\n', curLength);
                %pause
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
                for neighbor = obj.getNeighbors(curIdx)
                    nextDis = curDis + obj.getSegLength( [curIdx neighbor] );

                    if ~isKey(dis, neighbor)
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
        
        % MAP CHARACTERISTICS
        function [latlngNE, latlngSW] = getBoundaryCoordinates(obj)
            %        +----- latlngNE
            %        |          |
            %      latlngSW ----+
            minLat = inf;
            minLng = inf;
            maxLat = -inf;
            maxLng = -inf;
            for i = 1:size(obj.endNodePairs, 1)
                tmpSegLatLng = obj.getSegLatLng(obj.endNodePairs(i,:));
                minLat = min(minLat, min(tmpSegLatLng(:,1)));
                minLng = min(minLng, min(tmpSegLatLng(:,2)));
                maxLat = max(maxLat, min(tmpSegLatLng(:,1)));
                maxLng = max(maxLng, min(tmpSegLatLng(:,2)));
            end
            latlngNE = [maxLat, maxLng];
            latlngSW = [minLat, minLng];
        end
        
        function [meterHorizontal, meterVertical] = getBoundaryDistance(obj)
            [latlngNE, latlngSW] = obj.getBoundaryCoordinates();
            latlngNW = [latlngNE(1) latlngSW(2)];      latlngNE;
            latlngSW;                                  latlngSE = [latlngSW(1) latlngNE(2)];
            meterHorizontal = (latlng2m(latlngNW, latlngNE) + latlng2m(latlngSW, latlngSE)) / 2;
            meterVertical   = (latlng2m(latlngNW, latlngSW) + latlng2m(latlngNE, latlngSE)) / 2;
        end
        
        function areaMeterSquare = getBoundingBoxArea(obj)
            [meterHorizontal, meterVertical] = obj.getBoundaryDistance();
            areaMeterSquare = meterHorizontal * meterVertical;
        end
        
        function meter = getTotalDistanceOfAllSegments(obj)
            meter = 0;
            for i = 1:size(obj.endNodePairs, 1)
                meter = meter + obj.getSegLength(obj.endNodePairs(i,:));
            end
        end
        
        % The idea of getHomogeneousMap() is considering every points are
        % the same, meaning that we don't have a hierarchy of end nodes on
        % the segments, then in each one of them there are several internal
        % points.
        % The index is like this: The length of both return values are Nx1
        % matrice or cell, where as N refers the total points
        % in this map (apparently much more than num_nodes). The first
        % num_nodes refer to the same points as (joint) nodes in the map.
        function [elevs, latlngs, neighbors] = getHomogeneousMap(obj)
            numTotalPoints = obj.num_nodes;
            for i = 1:size(obj.endNodePairs, 1)
                numTotalPoints = numTotalPoints + length( obj.getSegLatLng( obj.endNodePairs(i,:) ) ) - 2;
            end
            elevs = zeros(numTotalPoints, 1);
            latlngs = zeros(numTotalPoints, 2);
            neighbors = cell(numTotalPoints, 1);
            
            elevs(1:obj.num_nodes) = obj.getNodeIdxsElev( 1:obj.num_nodes );
            latlngs(1:obj.num_nodes, :) = obj.getNodeIdxsLatLng( 1:obj.num_nodes );
            
            nextStartIdx = obj.num_nodes + 1;
            for i = 1:size(obj.endNodePairs, 1)
                tmpElev = obj.getSegElev( obj.endNodePairs(i,:) );
                tmpLatLng = obj.getSegLatLng( obj.endNodePairs(i,:) );
                numInternalNodes = length(tmpElev) - 2;
                internalIds = (1:numInternalNodes) - 1 + nextStartIdx;
                elevs(internalIds) = tmpElev(2:end-1);
                latlngs(internalIds, :) = tmpLatLng(2:end-1, :);
                allIds = [ obj.endNodePairs(i,1)  internalIds  obj.endNodePairs(i,2) ];
                for j = 1:length(allIds)-1
                    neighbors{ allIds(j  ) } = [ neighbors{ allIds(j  ) }   allIds(j+1) ];
                    neighbors{ allIds(j+1) } = [ neighbors{ allIds(j+1) }   allIds(j  ) ];
                end
                nextStartIdx = nextStartIdx + numInternalNodes;
            end
        end
        
        % INDEX SYSTEM CONVERSION
        % convert local node index to OSM index
        function node = idxToNode(obj, nidx)
            node = obj.idxsToNodes(nidx);
        end
        
        % convert OSM index to local matlab index
        function idx = nodeToIdx(obj, node)
            idx = obj.nodesToIdxs(node);
        end
        
        % convert local node indexes to OSM indexes
        function nodes = idxsToNodes(obj, nidxs)
            nodes = nidxs;
            for i = 1:numel(nidxs)
                nodes(i) = obj.map_idx2node(nidxs(i));
            end
        end
        
        % convert OSM indexes to local matlab indexes
        function idxs = nodesToIdxs(obj, nodes)
            idxs = nodes;
            for i = 1:numel(nodes)
                idxs(i) = obj.map_node2idx(nodes(i));
            end
        end
        
        % get node indexes of OSM nodes  % TODO: duplicated function?
        function nlist = getNodeIdxs(obj, osm_nodes)
           nlist = zeros(length(osm_nodes), 1);
           for i=1:length(osm_nodes)
              nlist(i) = obj.nodeToIdx(osm_nodes(i)); 
           end
        end
        
        % GPS ALLIGNMENT
        function result = rawGpsAlignment(obj, gpsLatLngs)
            % return value contains 4 columns which are [lat lng elev error]
            %{
            prevSeg = [];
            numLatLng = size(gpsLatLngs, 1);
            result = zeros(numLatLng, 4);
            for i = 1:numLatLng
                minDistance = inf;
                candidateSegs = obj.endNodePairs;
                if numel(prevSeg) == 2
                    candidateSegs = [prevSeg; candidateSegs];
                end
                for j = 1:size(candidateSegs, 1)
                    % simple pruning
                    segLen = obj.getSegLength( candidateSegs(j,:) );
                    segGps = obj.getSegLatLng( candidateSegs(j,:) );
                    segElev = obj.getSegElev( candidateSegs(j,:) );
                    distanceToSegEnd1 = obj.distanceToNodeIdx( gpsLatLngs(i,:), candidateSegs(j,1) );
                    distanceToSegEnd2 = obj.distanceToNodeIdx( gpsLatLngs(i,:), candidateSegs(j,2) );
                    if min(distanceToSegEnd1, distanceToSegEnd2) - segLen < minDistance
                        fprintf('%d,%d\n', i, j);
                        for k = 1:size(segGps, 1)
                            meter = latlng2m(segGps(k,:), gpsLatLngs(i,:));
                            if meter < minDistance
                                result(i, 1:2) = segGps(k,:);
                                result(i, 3) = segElev(k);
                                result(i, 4) = meter;
                                minDistance = meter;
                                prevSeg = candidateSegs(j,:);
                            end
                        end
                    end
                end
            end
            %}
            [mapElevs, mapLatLngs, ~] = obj.getHomogeneousMap();
            [disError, selectedIdx] = min( latlng2m(mapLatLngs, gpsLatLngs) );
            result = [ mapLatLngs(selectedIdx, :) mapElevs(selectedIdx, :) disError' ];
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
        
        % VISUALIZATION
        function plotCDFofNodeElevs(obj)
            clf
            cdfplot(obj.node_elevation);
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

