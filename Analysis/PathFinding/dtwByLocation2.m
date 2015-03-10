%% Housekeeping
clc; close all; clear all;
add_paths;
%rng(100);

NUM_PATHS = 5000;
PATH_LEN = 256;

% Goal: for each location, pick a number of random true paths. for each
% random true path, pick a number of fake candidate paths and perform dtw.
% of all the dtw results, compute a % error number so that we can say per
% location, what's the dtw error vs. path length

map_manager = MapManager('../../Data/EleSegmentSets/');
%map_size = [2 3 ];
%map_ids = [7, 1, 41]; % low var, med var, high var

map_info = [
    7  2
    7  4
    41 2
    41 4
];

all_results_abs        = zeros(PATH_LEN, NUM_PATHS, size(map_info, 1));
all_results_rel        = zeros(PATH_LEN, NUM_PATHS, size(map_info, 1));
all_results_abs_noise  = zeros(PATH_LEN, NUM_PATHS, size(map_info, 1));
all_results_rel_noise  = zeros(PATH_LEN, NUM_PATHS, size(map_info, 1));
all_results_abs_thres  = zeros(PATH_LEN, NUM_PATHS, size(map_info, 1));
all_results_rel_thres  = zeros(PATH_LEN, NUM_PATHS, size(map_info, 1));

for midx = 1:size(map_info)
    mapID = map_info(midx, 1);
    map_data = map_manager.getMapDataObject(mapID, map_info(midx, 2), 1);
    %map_name = map_manager.getMapName(mapID,map_size);
    
    for tidx=1:NUM_PATHS
                
        % random walk for a true path
        true_path = map_data.getRandomWalkConstrainedByTurn(-1, PATH_LEN, false, 50);
        true_elev = map_data.getPathElev(true_path);
        true_elev_noise = additiveNoise_OU(0:1:(length(true_elev)-1), 150, 0.001)';
        
        all_results_abs(:, tidx, midx)       = true_elev(1:PATH_LEN);
        all_results_abs_noise(:, tidx, midx) = true_elev(1:PATH_LEN) + true_elev_noise(1:PATH_LEN);
        all_results_rel(:, tidx, midx)       = all_results_abs(:, tidx, midx) - all_results_abs(1, tidx, midx);
        all_results_rel_noise(:, tidx, midx) = all_results_abs_noise(:, tidx, midx) - all_results_abs_noise(1, tidx, midx);
        all_results_abs_thres(:, tidx, midx) = DTW_MSE_3( all_results_abs(:, tidx, midx), all_results_abs_noise(:, tidx, midx) );
        all_results_rel_thres(:, tidx, midx) = DTW_MSE_3( all_results_rel(:, tidx, midx), all_results_rel_noise(:, tidx, midx) );

        fprintf('finish %d-%d\n', midx, tidx);
    end
end

%%
tasks = ndgrid2vec(1:size(map_info, 1), 1:NUM_PATHS, 1:NUM_PATHS);
order = randperm(size(tasks, 1))';
tasks = tasks(order,:);

testCount = zeros(size(map_info, 1), 1);
abs_errors = zeros(PATH_LEN, size(map_info, 1));
rel_errors = zeros(PATH_LEN, size(map_info, 1));

clf
%%
for i = 319366:size(tasks, 1)
    fprintf('iteration %d\n', i);
    if tasks(i, 2) ~= tasks(i, 3)
        abs_result = DTW_MSE_3( all_results_abs(:, tasks(i,2), tasks(i,1)), all_results_abs(:, tasks(i,3), tasks(i,1)) );
        abs_errors(:, tasks(i,1)) = abs_errors(:, tasks(i,1)) + (abs_result <= all_results_abs_thres(:, tasks(i,2), tasks(i,1)));
        rel_result = DTW_MSE_3( all_results_rel(:, tasks(i,2), tasks(i,1)), all_results_rel(:, tasks(i,3), tasks(i,1)) );
        rel_errors(:, tasks(i,1)) = rel_errors(:, tasks(i,1)) + (rel_result <= all_results_rel_thres(:, tasks(i,2), tasks(i,1)));
        testCount( tasks(i,1) ) = testCount( tasks(i,1) ) + 1;
    end
    
    
    if mod(i, 10000) == 0 || i == size(tasks, 1)
        for j = 1:size(map_info, 1)
            subplot( ceil(size(map_info, 1) / 2), 2, j);
            semilogy(1:PATH_LEN, abs_errors(:,j) / testCount(j), 'b')
            hold on
            semilogy(1:PATH_LEN, rel_errors(:,j) / testCount(j), 'r')
            hold off
            pause(0.1)
        end
    end
end
return;
%% fix the result
%{
for j = 1:6
    subplot(3, 2, j);
    semilogy(1:PATH_LEN, abs_errors(:,j)+eps / testCount(j), 'b')
    hold on
    semilogy(1:PATH_LEN, rel_errors(:,j)+eps / testCount(j), 'r')
    hold off
    pause(0.1)
end  
%}
%% finalize the figure
ylimValue = [
    1e-3 1
    1e-3 1
    1e-6 1
    1e-6 1
    ];

xinterest = 11:PATH_LEN;
for j = candidtate
    cfigure(14, 6);
    semilogy(xinterest, (abs_errors(xinterest,j)+1e-6) / testCount(j), 'b')
    hold on
    semilogy(xinterest, (rel_errors(xinterest,j)+1e-6) / testCount(j), 'r')
    hold off
    ylim(ylimValue(j,:));
    saveplot(['~/Dropbox/MercuryWriting/mobicom15/figs/dtwErrorPercentage_' num2str(j)])
end
%%
save('../../Data/tmpMatFiles/dtwLengthVSerror/trial2_abs_errors', 'abs_errors');
save('../../Data/tmpMatFiles/dtwLengthVSerror/trial2_rel_errors', 'rel_errors');
save('../../Data/tmpMatFiles/dtwLengthVSerror/trial2_testCount', 'testCount');