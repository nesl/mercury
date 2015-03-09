%% Housekeeping
clc; close all; clear all;
add_paths;


%% Result Folder
outpath = 'SimResults/';

%% Number of simulated paths to test per city
paths_per_city = 20;
start_path_idx = 11;

%% Random walk stats
METERS_PER_GPS = 10;
ELEV_WIN_SIZE = 1; % sec
walk_len_ave = 400; % gps pts
walk_len_var = 100;
walk_len_min = 50;
walk_speed_ave = 10; % m/s
walk_speed_var = 4;
walk_speed_min = 5;
walk_speed_max = 18;

%% Create map manager
mgr = MapManager('../../Data/EleSegmentSets/');
map_size = 3;
map_downsample = 2;
map_ids = mgr.getValidMapIds(map_size);

%% Loop through maps

for midx=1:length(map_ids)
%for midx=2
    map_id = map_ids(midx);
    map_file = mgr.getMapFile(map_id, map_size);
    map_name = mgr.getMapName(map_id, map_size);
    map_data = mgr.getMapDataObject(map_id, map_size, 1);  % so that's why METERS_PER_GPS is 10
    
    % Loop through walks
    for widx=1:paths_per_city
    %for widx=15
        rng(widx);  % reset random generator at the beginning of path generation

        if widx < start_path_idx
            fprintf('force skipping...\n')
            continue;
        end
        
        % random path length
        path_len = round( walk_len_ave + randn()*walk_len_var );
        path_len = max(walk_len_min, path_len);
        
        % random walk
        
        % THIS IS VERY IMPORTANT! DON'T CHANGE THIS PART OF CODE! ========
        % guide: can only add more cases, shouldn't modify the previous cases
        if widx <= 10
            randwalk = map_data.getRandomWalk(map_data.getRandomNode(), path_len, false);
        elseif widx <= 15
            randwalk = map_data.getRandomWalkConstrainedByTurn(-1, path_len, false, path_len / 1);
        elseif widx <= 20
            randwalk = map_data.getRandomWalkConstrainedByTurn(-1, path_len, false, path_len / 3);
        else
            fprintf('haven''t assigned... skip')
        end
        % UP TO HERE =====================================================
        
        randwalk_speed = 0;
        while randwalk_speed < walk_speed_min || randwalk_speed > walk_speed_max
            randwalk_speed = walk_speed_ave + randn()*walk_speed_var;
        end
        randwalk_gps = map_data.getPathLatLng(randwalk);
        randwalk_len = size(randwalk_gps,1);
        randwalk_dist = randwalk_len*METERS_PER_GPS;
        randwalk_time = randwalk_dist/randwalk_speed;
        % get sampled random walk time vs. elevation
        randwalk_elev_samp = map_data.getPathElev(randwalk);
        randwalk_times_samp = linspace(0,randwalk_time,size(randwalk_elev_samp,1));
        randwalk_gps_times = linspace(0,randwalk_time,size(randwalk_gps,1));
        % we may need to interpolation if our speed is slow
        randwalk_times = 0:ELEV_WIN_SIZE:randwalk_time;
        randwalk_elevs = interp1(randwalk_times_samp, randwalk_elev_samp, randwalk_times);
        
        % simulated barometer
        noise = additiveNoise_OU(randwalk_times, 150, 0.001);
        randwalk_elevs_noise = randwalk_elevs + noise;
        
        % Plot barometer noise
        %{
        plot(randwalk_times, randwalk_elevs, 'k-');
        hold on;
        plot(randwalk_times, randwalk_elevs_noise, 'b-');
        pause();
        hold off;
        %}
        
        % simulated turn events
        randwalk_turns = map_data.getPathTurns(randwalk);
        % transform to sampled time
        turn_times = ( randwalk_turns(:,1)./size(randwalk_gps,1) )*randwalk_time;
        randwalk_turns(:,1) = turn_times;
        % add noise
        randwalk_turns_noise = randwalk_turns(:,2) + 10*randn(size(randwalk_turns,1),1);
                
        % create test case
        testCase = TestCase();
        testCase.mapFilePath = map_file;
        testCase.sensorFilePath = '';
        testCase.startAbsTime = 0;
        testCase.stopAbsTime = randwalk_time;
        testCase.sensorWindowSize = ELEV_WIN_SIZE;
        testCase.mapDataDownSampling = map_downsample;
        testCase.simulated = true;
        testCase.sim_path = randwalk;
        testCase.sim_elevations = [randwalk_times' randwalk_elevs_noise'];
        testCase.sim_turns = [randwalk_turns(:,1) randwalk_turns_noise];
        testCase.sim_elevations_nonoise = [randwalk_times' randwalk_elevs'];
        testCase.sim_turns_nonoise = randwalk_turns;
        testCase.sim_gps = [randwalk_gps_times' randwalk_gps];
        testCase.sim_speed = randwalk_speed;
        
        caseName = strcat('TESTCASE_SIM_', map_name, '_', num2str(widx));
        fprintf('Test case: %s\n', caseName);
        testCase.saveTo(['../../Data/SimTestCases/' caseName], caseName);
        

    end

    
end

return

%% compare with and without turns
mapManager = MapManager('../../Data/EleSegmentSets/');
mapData = mapManager.getMapDataObject(24, 3, 1);

figure
for i = 1:6
    subplot(2, 3, i)
    if mod(i, 2) == 1
        path = mapData.getRandomWalk(-1, 300, 0);
    else
        path = mapData.getRandomWalkConstrainedByTurn(-1, 300, 0, 50);
    end
    latlngs = mapData.getPathLatLng(path);
    plot(latlngs(:,2), latlngs(:,1));
end

%% KL(path||map), variation(path) -> how likely to find the path
elevBinWidth = 0.3;

mgr = MapManager('../../Data/EleSegmentSets/');
map_size = 3;
map_downsample = 2;
map_ids = mgr.getValidMapIds(map_size);

% kl(path||map)  variation(path)  entropy(map)  variation(map)
resultEV = zeros( length(map_ids) * paths_per_city, 2);

for midx=1:length(map_ids)
%for midx=4:4
    map_id = map_ids(midx);
    map_name = mgr.getMapName(map_id, map_size);
    map_data = mgr.getMapDataObject(map_id, map_size, 1);  % so that's why METERS_PER_GPS is 10
    
    mapAllElevs = [];
    for j = 1:size(map_data.endNodePairs, 1)
        mapAllElevs = [mapAllElevs; map_data.getPathElev( map_data.endNodePairs(j,:) ) ];
    end
    mapElevVar = var(mapAllElevs);
    tmp = tabulate(mapAllElevs);
    tmp = tmp(:,3) / 100;
    tmp = tmp( tmp > 0 );
    mapElevEntropy = sum( tmp(:) * log2(tmp(:)) );
    
    for widx=1:paths_per_city
        saveIdx = (midx-1) * paths_per_city + widx + 1;
        caseName = strcat('../../Data/SimTestCases/TESTCASE_SIM_', map_name, '_', num2str(widx), '.mat');
        loaded = load(caseName);
        testcase = loaded.obj;
        tableMap = tabulate( ceil(mapAllElevs / elevBinWidth) );
        tablePath = tabulate( ceil(testcase.sim_elevations(:,2) / elevBinWidth) );
        minBinIdx = min(tableMap(1,1), tablePath(1,1));
        tableMap(:,1) = tableMap(:,1) - minBinIdx + 1;
        tablePath(:,1) = tablePath(:,1) - minBinIdx + 1;
        maxBinIdx = max(tableMap(end,1), tablePath(end,1));
        merge = zeros(maxBinIdx, 2);
        merge(tablePath(:,1) ,1) = tablePath(:,3) / 100;
        merge(tableMap(:,1) ,2) = tableMap(:,3) / 100;
        if sum(merge(:,1) > 0 & merge(:,2) == 0)
            warning('violate KL def');
        end
        merge = merge( merge(:,1) > 0 & merge(:,2) > 0, :);
        resultEV(saveIdx, 1) = sum( merge(:,1) .* log2( merge(:,1) ./ merge(:,2) ) );
        resultEV(saveIdx, 2) = var( testcase.sim_elevations(:,2) );
        resultEV(saveIdx, 3) = mapElevEntropy;
        resultEV(saveIdx, 4) = mapElevVar;
        fprintf('KL=%f, VAR=%f\n', resultEV(saveIdx, 1), resultEV(saveIdx, 2));
    end
end

save('../../Data/tmpMatFiles/simPathKLVar.mat', 'resultEV');

%% calculate path entropy
mgr = MapManager('../../Data/EleSegmentSets/');
map_size = 3;
map_downsample = 2;
map_ids = mgr.getValidMapIds(map_size);

relativeEntropies = zeros( length(map_ids), paths_per_city );
for midx=1:length(map_ids)
    map_id = map_ids(midx);
    map_name = mgr.getMapName(map_id, map_size);
    randomWalkManager = RandomWalkManager(map_id, map_size, 1);
    randomWalkManager.generatePaths(1);
    
    for widx=1:paths_per_city
        caseName = strcat('../../Data/SimTestCases/TESTCASE_SIM_', map_name, '_', num2str(widx), '.mat');
        loaded = load(caseName);
        testcase = loaded.obj;
        relativeEntropies(midx, widx) = randomWalkManager.getRelativeEntropy(testcase.sim_elevations(:,2))
    end
end