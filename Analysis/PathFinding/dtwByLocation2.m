%% Housekeeping
clc; close all; clear all;
add_paths;
rng(100);

NUM_TRUE_PATHS = 300;
NUM_FAKE_PATHS = 100;

path_len_min = 2;
path_len_max = 300;

% Goal: for each location, pick a number of random true paths. for each
% random true path, pick a number of fake candidate paths and perform dtw.
% of all the dtw results, compute a % error number so that we can say per
% location, what's the dtw error vs. path length

map_manager = MapManager('../../Data/EleSegmentSets/');
map_size = 2;
map_ids = [7, 1, 41]; % low var, med var, high var

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
            dtw_fake = DTW_MSE_2(true_elev, fake_elev);
            dtw_fake_rel = DTW_MSE_2(true_elev, fake_elev_rel);
            
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

% plot ids: low (chicago), med (albuquerque), high (seattle)
plotids = { {'bs-', 'bs--'}, {'ro-', 'rs--'}, {'m^-', 'm^--'} };
cfigure(14,8);
wsize = 20;

handles = [];

for m=3:-1:1
    errors_abs = squeeze( all_results_abs(m,:,:) );
    errors_rel = squeeze( all_results_rel(m,:,:) );
    all_lengths = linspace(path_len_min, path_len_max, size(all_results_abs,2));
    errors_ave_abs = median( errors_abs, 2);
    errors_ave_rel = median( errors_rel, 2);
    
    % window to clean up
    errors_win_abs = [];
    errors_win_rel = [];
    lengths = [];
    for w=(1+wsize):wsize:length(errors_ave_abs)
        errors_win_abs = [errors_win_abs; mean( errors_ave_abs((w-wsize):w) )];
        errors_win_rel = [errors_win_rel; mean( errors_ave_rel((w-wsize):w) )];
        lengths = [lengths; mean( all_lengths((w-wsize):w) )];
    end
    
    h = semilogy(lengths*10, errors_win_abs, plotids{m}{1},'LineWidth',2);
    handles = [handles; h];
    hold on;
    h = semilogy(lengths*10, errors_win_rel, plotids{m}{2},'LineWidth',2);
    handles = [handles; h];

    
end



grid on;
xlabel('Path Length (m)','FontSize',12);
ylabel('% Error vs. True Path','FontSize',12);
legend([handles(1), handles(3), handles(5)], 'Seattle', 'Albuquerque', 'Chicago');
saveplot('figs/dtwByLocation');












