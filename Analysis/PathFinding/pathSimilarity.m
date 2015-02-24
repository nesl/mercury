clc; clear; clf;
add_paths

fprintf('reading maps...');
mapfile =    '../../Data/EleSegmentSets/ucla_5x5/';
map_data = MapData(mapfile);
fprintf('done\n');

%% Random Walk Parameters
path_length = 100; % number of elevation points
num_paths = 30;
flag_allow_go_back = 0; % if 'allow_go_back', you can return to a node by an intermediary.

elevs = cell(1, num_paths);
for i = 1:num_paths
    path = map_data.getRandomWalk(-1, path_length, flag_allow_go_back);
    elevs{i} = map_data.getPathElev(path);
end
fprintf('generated random walk paths\n');

scores = zeros(num_paths);
for i = 1:num_paths
    for j = 1:num_paths
        scores(i, j) = dtw_traditional( elevs{i}, elevs{j} );
    end
end
fprintf('finish calculating dtw scores\n');

imagesc(log10(scores+1));
colorbar