clc; clear; clf;
add_paths

map_manager = MapManager();
for mapID = [23 7]
for mapSize = [4]

%mapfile =    '../../Data/EleSegmentSets/ucla_5x5/';
%map_data = MapData(mapfile);

%map_data = map_manager.getMapDataObject(41, 3, 1);  % Seattle
%map_data = map_manager.getMapDataObject(38, 3, 1);  % San Francisco
%map_data = map_manager.getMapDataObject(2, 3, 1);  % Atlanta
%map_data = map_manager.getMapDataObject(23, 3, 1);  % Los Angeles
%map_data = map_manager.getMapDataObject(29, 3, 1);  % New York
%map_data = map_manager.getMapDataObject(7, 3, 1);  % Chicago

map_data = map_manager.getMapDataObject(mapID, 4, 1);  % Chicago

%% Random Walk Parameters
path_length = 100; % number of elevation points
flag_allow_go_back = 0; % if 'allow_go_back', you can return to a node by an intermediary.
expected_visited_time = 2;

totalDistance = map_data.getTotalDistanceOfAllSegments();
num_paths = floor(totalDistance / 10 / path_length * expected_visited_time);
fprintf('will generate %d paths\n', num_paths);

elevs = cell(1, num_paths);
for i = 1:num_paths
    path = map_data.getRandomWalk(-1, path_length, flag_allow_go_back);
    elevs{i} = map_data.getPathElev(path);
    fprintf('path %d generated (out of %.0f)\n', i, num_paths);
end
fprintf('generated random walk paths\n');

scores = zeros(num_paths);
parfor i = 1:num_paths
    for j = 1:num_paths
        scores(i, j) = dtw_traditional( elevs{i}, elevs{j} );
    end
    fprintf('DTW(%d,*) out of %.0f\n', i, num_paths);
end
fprintf('finish calculating dtw scores\n');

matName = ['simi-map' num2str(mapID) '-size' num2str(mapSize)];
save(matName, 'scores');
matName = ['simi-map' num2str(mapID) '-size' num2str(mapSize) '-paths'];
save(matName, 'elevs');

end
end

%%
imagesc(log10(scores+1));
colorbar
return;

%% play with scores
sortedScores = scores;
for i = 1:num_paths
    sortedScores(i,:) = sort(scores(i,:));
end

imagesc(log10(sortedScores+1));
colorbar
