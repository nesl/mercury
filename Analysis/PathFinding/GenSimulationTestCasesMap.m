%% Housekeeping
clc; close all; clear all;
add_paths;


%% Number of simulated paths to test per city
paths_per_city = 20;

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
map_ids = [1];  % med(albuquerque)
map_sizes = [2 3 4 5 6];

%% Loop through maps

for midx=1:length(map_sizes)
    map_id = map_ids(1);
    map_size = map_sizes(midx);
    map_file = mgr.getMapFile(map_id, map_size);
    map_name = mgr.getMapName(map_id, map_size);
    map_data = mgr.getMapDataObject(map_id, map_size, 1);
    
    % Loop through walks
    for widx=1:paths_per_city
    %for widx=15
        rng(widx);  % reset random generator at the beginning of path generation
        
        % random path length
        path_len = round( walk_len_ave + randn()*walk_len_var );
        path_len = max(walk_len_min, path_len);
        
        % random walk
        randwalk = map_data.getRandomWalkConstrainedByTurn(-1, path_len, false, 50);
        
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
        if isempty(randwalk_turns)
            turn_times = [];
        else
            turn_times = ( randwalk_turns(:,1)./size(randwalk_gps,1) )*randwalk_time;
            randwalk_turns(:,1) = turn_times;
            % add noise
            randwalk_turns_noise = randwalk_turns(:,2) + 10*randn(size(randwalk_turns,1),1);
        end
        
       
                
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
        %testCase.sim_turns = [randwalk_turns(:,1) randwalk_turns_noise];
        testCase.sim_turns = [];
        testCase.sim_elevations_nonoise = [randwalk_times' randwalk_elevs'];
        testCase.sim_turns_nonoise = randwalk_turns;
        testCase.sim_gps = [randwalk_gps_times' randwalk_gps];
        testCase.sim_speed = randwalk_speed;
        
        caseName = strcat('TESTCASE_SIM_', map_name, '_', num2str(widx));
        fprintf('Test case: %s\n', caseName);
        testCase.saveTo(['../../Data/SimTestCasesMap/' caseName], caseName);
        

    end

    
end

return
