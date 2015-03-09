%% Housekeeping
clc; close all; clear all;
add_paths;
rng(100);

NUM_TRUE_PATHS = 100;
NUM_FAKE_PATHS = 50;

path_len_min = 2;
path_len_max = 300;

% Goal: for each location, pick a number of random true paths. for each
% random true path, pick a number of fake candidate paths and perform dtw.
% of all the dtw results, compute a % error number so that we can say per
% location, what's the dtw error vs. path length

map_manager = MapManager('../../Data/EleSegmentSets/');
map_size = 2;
map_ids = map_manager.getValidMapIds(map_size);

all_results_abs = zeros(length(map_ids), NUM_TRUE_PATHS, NUM_FAKE_PATHS);
all_results_rel = zeros(length(map_ids), NUM_TRUE_PATHS, NUM_FAKE_PATHS);

for midx = 1:length(map_ids)
    mapID = map_ids(midx);
    map_data = map_manager.getMapDataObject(mapID,map_size, 1);
    map_name = map_manager.getMapName(mapID,map_size);
    
    for tidx=1:NUM_TRUE_PATHS
                
        % path len
        all_lengths = linspace(path_len_min, path_len_max, NUM_TRUE_PATHS);
        len = all_lengths(tidx);
        
        % random walk for a true path
        start_node = map_data.getRandomNode();
        true_path = map_data.getRandomWalkConstrainedByTurn(...
            start_node, len, false, 50);
        true_elev = map_data.getPathElev(true_path);
        true_elev_noise = additiveNoise_OU(0:1:(length(true_elev)-1), 150, 0.001)';
        

        % DTW of true vs. true + noise
        dtw_base = DTW_MSE(true_elev, true_elev+true_elev_noise);
        
        for fidx=1:NUM_FAKE_PATHS
            
            % print status
            fprintf('Map %d / %d, path %d / %d, fake: %d / %d\n', ...
                midx, length(map_ids), tidx, NUM_TRUE_PATHS, fidx, NUM_FAKE_PATHS);
            
            % random walk for a fake path
            start_node = map_data.getRandomNode();
            fake_path = map_data.getRandomWalkConstrainedByTurn(...
                start_node, len, false, 50);
            fake_elev = map_data.getPathElev(fake_path);
            fake_elev_rel = fake_elev - (fake_elev(1) - true_elev(1) - true_elev_noise(1));
            
            % DTW score
            dtw_fake = DTW_MSE(true_elev, fake_elev);
            dtw_fake_rel = DTW_MSE(true_elev, fake_elev_rel);
            
            % perc. diff
            error_perc = 100*(dtw_fake - dtw_base)/dtw_base;
            error_perc_rel = 100*(dtw_fake_rel - dtw_base)/dtw_base;
            
            all_results_abs(midx, tidx, fidx) = error_perc;
            all_results_rel(midx, tidx, fidx) = error_perc_rel;
            
        end
    end
end

save('cache/dtwByLocation', 'all_results_abs', 'all_results_rel', ...
    'map_ids', 'map_size', 'path_len_min', 'path_len_max');
    

%% Analyze and Plot Results
load('cache/dtwByLocation');
