clc; clear; clf;
add_paths

map_manager = MapManager();
for mapID = [2 23 7]
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
for i = 1:num_paths
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

%% load mat and time to have some insight (for paper)

dirPath = '../../Data/tmpMatFiles/pathSimilarity/';
%{
matFileName = {
'simi-map41-size3.mat'
'simi-map38-size3.mat'
'simi-map23-size3.mat'
'simi-map2-size3.mat'
'simi-map29-size3.mat'
'simi-map7-size3.mat'
};
%}

matFileName = {
'simi-map41-size4.mat'
'simi-map23-size4.mat'
'simi-map2-size4.mat'
'simi-map7-size4.mat'
};


scoresAll = {};
sortedScoresAll = {};

errorThreshold = 100 * 1;
expectedVisitingTime = 2;


fractionControl = expectedVisitingTime * 0.5;

clf
hold on
for i = 1:numel(matFileName)
    matPath = [dirPath matFileName{i}];
    load(matPath, 'scores');
    numPath = size(scores, 1);
    numPath = floor(numPath * fractionControl);
    scores = scores(1:numPath, 1:numPath);
    scoresAll{i} = scores;
    tmpSortedScore = scores;
    for j = 1:numPath
        tmpSortedScore(j,:) = sort(scores(j,:));
        numSimilarPath(j) = sum(tmpSortedScore(j,2:end) < errorThreshold) / (numPath - 1);
    end
    sortedScoresAll{i} = tmpSortedScore;
    %imagesc(log10(tmpSortedScore+1));
    %colorbar
    y = linspace(0, 1, numel(numSimilarPath));
    x = sort(numSimilarPath);
    plot(x, y, 'Color', hsv2rgb([i/7, 1, 0.8]));
    %pause
    xlabel('Percentage of similar paths')
    ylabel('CDF probability')
end
legend('Seattle', 'SF', 'LA', 'Atlanta', 'NY', 'Chicago')