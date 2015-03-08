classdef RandomWalkManager < handle
    properties (SetAccess = public, GetAccess = public)
        map_data;
        path_elevs;
    end
    
    methods
        function obj = RandomWalkManager(mapID, size, downSampling)
            mapManager = MapManager('../../Data/EleSegmentSets/');
            obj.map_data = mapManager.getMapDataObject(mapID, size, downSampling);
        end
        
        function generatePaths(obj, numPaths)
            for i = 1:numPaths
                rng(1000+i);
                walk_len_ave = 400; % gps pts
                walk_len_var = 100;
                walk_len_min = 50;
                path_len = round( walk_len_ave + randn()*walk_len_var );
                path_len = max(walk_len_min, path_len);
                pathIdx = obj.map_data.getRandomWalkConstrainedByTurn(-1, path_len, false, path_len / (rand() * 3 + 1));
                obj.path_elevs{i} = obj.map_data.getPathElev(pathIdx);
            end
        end
        
        function meanRelativeEntropy = getRelativeEntropy(obj, elev)
            binWidth = 0.3;
            relEnt = zeros(1, numel(obj.path_elevs));
            for i = 1:numel(obj.path_elevs)
                maxElev = max( max(elev), max(obj.path_elevs{i}) );
                numBins = ceil(maxElev / binWidth);
                % p(elev)  p(path)
                stat = zeros(numBins, 2);
                tmp = tabulate( ceil(elev / binWidth) );
                stat(tmp(:,1), 1) = tmp(:,3) / 100;
                tmp = tabulate( ceil(obj.path_elevs{i} / binWidth) );
                stat(tmp(:,1), 2) = tmp(:,3) / 100;
                stat = stat( stat(:,1) ~= 0 & stat(:,2) ~= 0, :)
                relEnt(i) = sum( stat(:,1) .* log( stat(:,1) ./ stat(:,2) ) )
                pause
            end
            meanRelativeEntropy = mean(relEnt);
        end
    end
    
end

