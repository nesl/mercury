%% Housekeeping
clc; close all; clear all;
add_paths

%% Get test cases

mgr = MapManager('../../Data/EleSegmentSets/');
map_size = 3;
map_downsample = 2;
map_ids = mgr.getValidMapIds(map_size);

casePerCity = 10;
numRandomPaths = 20;

totalCases = length(map_ids) * numRandomPaths;

pathError = zeros( totalCases, numRandomPaths );
shapeError = zeros( totalCases, numRandomPaths );
shapeErrorBi = zeros( totalCases, numRandomPaths );

%% Loop through all test cases
%for tidx=1:length(test_files)
for tidx=257:270
    %tfile = test_files{tidx};
    
    %fprintf('load %s\n', tfile);
    
    % solve this test case w/ greedy solver
    %loaded = load([testdir tfile]);
    %testcase = loaded.obj;
    
    % sensor data
    if mod(tidx, casePerCity) == 1
        map_id = map_ids(ceil(tidx / casePerCity));
        map_data = mgr.getMapDataObject(map_id, 3, 1);
    end
    
    sim_path = map_data.getRandomWalkConstrainedByTurn(-1, 300, -1, 100);
    sim_elevations = map_data.getPathElev(sim_path);
    sim_elevations = [ (1:numel(sim_elevations))'  sim_elevations];
    sim_gps = map_data.getPathLatLng(sim_path);
    sim_gps = [  linspace(0, numel(sim_elevations), length(sim_gps))' sim_gps ];
    
    sensor_data = SensorDataSim(sim_elevations, [], sim_gps);
    elevBaroWithTime = sensor_data.getElevationTimeWindow();
    elevBaro = elevBaroWithTime(:,2);
    
    % map data
    
    evaluator = Evaluator(sensor_data, map_data);
    
    tmpPathError = zeros(numRandomPaths, 1);
    tmpShapeError = zeros(numRandomPaths, 1);
    tmpShapeErrorBi = zeros(numRandomPaths, 1);
    for i = 1:numRandomPaths
        if mod(i, 2) == 1
            pathIdxs = map_data.getRandomWalkConstrainedByTurn(-1, length(elevBaroWithTime) * 0.7, false, 50);
        else
            pathIdxs = map_data.getRandomWalk(-1, length(elevBaroWithTime) * 0.7, false);
        end
        pathElev = map_data.getPathElev(pathIdxs);
        pathLatLng = map_data.getPathLatLng(pathIdxs);
        [idxFrom, idxTo, ~] = dp_backtracking(elevBaro, pathElev);
        mapToPath = zeros(1, length(elevBaro));
        for j = 1:length(elevBaro)
            idxsOfInterest = (idxFrom == j);
            mapToPath(j) = round( mean(idxTo(idxsOfInterest)) );
        end
        estiLatLngs = pathLatLng(mapToPath, :);
        estiTimeLatLngs = [ elevBaroWithTime(:,1) estiLatLngs ];
        pathError(tidx, i) = evaluator.getPathSimilarityConsideringTime(estiTimeLatLngs);
        shapeError(tidx, i) = evaluator.getPathShapeSimilarity(estiLatLngs);
        shapeErrorBi(tidx, i) = evaluator.getPathShapeSimilarityBiDirection(estiLatLngs);
        fprintf('finish tidx=%d, path=%d\n', tidx, i);
    end
end


return;

%}


%% load for plotting

%rankOfInterest = [1 3 5 10 15 20 30 50 inf];
rankOfInterest = [1 3 5 20];
topNPathError = [];  % numel(rankOfInterest) by num_available_solution
topNShapeError = [];  % numel(rankOfInterest) by num_available_solution
topNBiShapeError = [];  % numel(rankOfInterest) by num_available_solution


%for tidx=1:length(test_files)
for tidx=1:270
    for i = 1:length(rankOfInterest)
        rank = rankOfInterest(i);
        topNPathError(i, tidx) = min(pathError(tidx, 1:rank));
        topNShapeError(i, tidx) = min(shapeError(tidx, 1:rank));
        topNBiShapeError(i, tidx) = min(shapeErrorBi(tidx, 1:rank));
    end
end

%% Plotting

%
%cfigure(14,8);

clf

colors = {'bs-', 'r^-', 'mo-', 'k*-'};
%skip = 20;

subplot(1, 3, 1);
hold on
for i = length(rankOfInterest):-1:1
    x = sort(topNPathError(i,:));
    y = linspace(0, 1, length(x));
    %plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
    plot(x, y, colors{i}, 'LineWidth',2);
end
xlabel('Timed Path Error (m)','FontSize',12);
ylabel('Probability','FontSize',12);
grid on;
%legend('20 path', '5 paths', '3 paths', '1 paths','Location','SE');
%saveplot('figs/sim_greedyA_path');


%cfigure(14,8);


subplot(1, 3, 2);
hold on
for i = length(rankOfInterest):-1:1
    x = sort(topNShapeError(i,:));
    y = linspace(0, 1, length(x));
    %plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
    plot(x, y, colors{i}, 'LineWidth',2);
end

xlabel('Path Error (m)', 'FontSize',12);
ylabel('Probability', 'FontSize',12);
grid on;
%legend('20 path', '5 paths', '3 paths', '1 paths','Location','SE');
%saveplot('figs/sim_greedyA_shape');

% bi-shape

%cfigure(14,8);
subplot(1, 3, 3);
hold on
for i = length(rankOfInterest):-1:1
    x = sort(topNBiShapeError(i,:));
    y = linspace(0, 1, length(x));
    %plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
    plot(x, y, colors{i}, 'LineWidth',2);
end

xlabel('Bi-Path Error (m)', 'FontSize',12);
ylabel('Probability', 'FontSize',12);
grid on;
%legend('20 path', '5 paths', '3 paths', '1 paths','Location','SE');
%saveplot('figs/sim_greedyA_bishape');

