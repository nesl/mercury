%% Housekeeping
clc; close all; clear all;
add_paths


caseNames = {
'[Bo-Driving]_1-1_size4'
'[Bo-Driving]_1-2_size4'
'[Bo-Driving]_1-3_size4'
'[Bo-Driving]_1-4_size4'
'[Bo-Driving]_1-5_size4'
'[Bo-Driving]_1-6_size4'
'[Bo-Driving]_2-1_size4'
'[Bo-Driving]_2-2_size4'
'[Bo-Driving]_3-1_size4'
'[Bo-Driving]_3-2_size4'
'[Bo-Driving]_3-3_size4'
'[Bo-Driving]_3-4_size4'
'[Bo-Driving]_3-5_size4'
'[Bo-Driving]_3-6_size4'
'[Bo-Driving]_3-7_size4'
'[Bo-Driving]_3-8_size4'
'[Bo-Driving]_5-1_size4'
'[Bo-Driving]_5-2_size4'
'[Bo-Driving]_5-3_size4'
'[Bo-Driving]_6-1_size4'
'[Bo-Driving]_6-2_size4'
'[Bo-Driving]_7-1_size4'
'[Bo-Driving]_7-2_size4'
'[Bo-Driving]_7-3_size4'
'[Bo-Driving]_7-4_size4'
'[Bo-Driving]_7-5_size4'
'[Bo-Driving]_7-6_size4'
'[Bo-Driving]_7-7_size4'
'[Bo-Driving]_7-8_size4'
};

%% load for plotting

load ../../Data/tmpMatFiles/randomGuess/randomGuess6x6.mat
randomTopNPathError = topNPathError;  % numel(rankOfInterest) by num_available_solution
randomTopNShapeError = topNShapeError;  % numel(rankOfInterest) by num_available_solution
randomTopNBiShapeError = topNBiShapeError;  % numel(rankOfInterest) by num_available_solution

totalTime = [];
topNPathError = [];
topNShapeError = [];
topNBiShapeError = [];
rankOfInterest = [1 3 5];
for i = 1:size(caseNames, 1)
    solver = solutionResolver_dp4([caseNames{i} '_greedyA']);
    [scores, paths] = solver.getResults();
    % evaluation
    evaluator = Evaluator(solver.sensor_data, solver.map_data);
    
    pathError = zeros(numel(paths), 1);
    shapeError = zeros(numel(paths), 1);
    shapeErrorBi = zeros(numel(paths), 1);
    
    elevBaroWithTime = solver.sensor_data.getElevationTimeWindow();
    elevBaro = elevBaroWithTime(:,2);
    
    %pathsLatLng = cell(size(solver_results.paths));
    for j = 1:numel(paths)
        pathNodeIdxs = paths{j};
        pathLatLng = solver.map_data.getPathLatLng(pathNodeIdxs);
        pathElev = solver.map_data.getPathElev(pathNodeIdxs);
        [idxFrom, idxTo, ~] = dp_backtracking(elevBaro, pathElev);
        mapToPath = zeros(1, length(elevBaro));
        for k = 1:length(elevBaro)
            idxsOfInterest = (idxFrom == k);
            mapToPath(k) = round( mean(idxTo(idxsOfInterest)) );
        end
        estiLatLngs = pathLatLng(mapToPath, :);
        estiTimeLatLngs = [ elevBaroWithTime(:,1) estiLatLngs ];
        pathError(j) = evaluator.getPathSimilarityConsideringTime(estiTimeLatLngs);
        shapeError(j) = evaluator.getPathShapeSimilarity(estiLatLngs);
        shapeErrorBi(j) = evaluator.getPathShapeSimilarityBiDirection(estiLatLngs);
    end
    
    fprintf('min path error: %f\n', min(pathError)); 
    fprintf('min shape error: %f\n', min(shapeError)); 
    fprintf('min bi-dir shape error: %f\n', min(shapeErrorBi)); 
    
    totalTime = [totalTime solver.process_time];
    
    topNPathError(end+1, 1) = 0;
    topNShapeError(end+1, 1) = 0;
    topNBiShapeError(end+1, 1) = 0;
    for j = 1:numel(rankOfInterest)
        rank = min(rankOfInterest(j), numel(paths));
        topNPathError(end, j) = min( pathError(1:rank) );
        topNShapeError(end, j) = min( shapeError(1:rank) );
        topNBiShapeError(end, j) = min( shapeErrorBi(1:rank) );
    end
    fprintf('finish case %d\n', i);
end

fprintf('avg solving time = %f +/- %f sec\n', mean(totalTime), std(totalTime));

topNPathError = topNPathError';
topNShapeError = topNShapeError';
topNBiShapeError = topNBiShapeError';

%% merge
randomTopNPathError(3,:) = sort(randomTopNPathError(3,:));
randomTopNShapeError(3,:) = sort(randomTopNShapeError(3,:));
randomTopNBiShapeError(3,:) = sort(randomTopNBiShapeError(3,:));
idx = floor(linspace(1, size(randomTopNShapeError, 2) + 0.5, size(topNBiShapeError, 2)));
topNPathError(4,:) = randomTopNPathError(3,idx);
topNShapeError(4,:) = randomTopNShapeError(3,idx);
topNBiShapeError(4,:) = randomTopNBiShapeError(3,idx);

%% fast test
clf
subplot(1, 3, 1)
hold on
cdfplot(topNPathError(:,1));
cdfplot(topNPathError(:,2));
cdfplot(topNPathError(:,3));
subplot(1, 3, 2)
hold on
cdfplot(topNShapeError(:,1));
cdfplot(topNShapeError(:,2));
cdfplot(topNShapeError(:,3));
subplot(1, 3, 3)
hold on
cdfplot(topNBiShapeError(:,1));
cdfplot(topNBiShapeError(:,2));
cdfplot(topNBiShapeError(:,3));


%% store: for handover
save ../../Data/tmpMatFiles/drivingData/greedyA_handover.mat
return

%% load: for handover
load ../../Data/tmpMatFiles/drivingData/greedyA_handover.mat

%% Plotting

%dirSaveFigure = 'figs/';
dirSaveFigure = '~/Dropbox/mercuryWriting/mobicom15/figs/';
%
cfigure(14,6);

clf

colors = {'bs-', 'r^-', 'm*-', 'ko-'};
legendTexts = {'1 paths', '3 paths', '5 paths', 'Random'};
skip = 1;

lineOrder = [3 2 1 4];

%orderedLegendTexts = legendTexts{lineOrder};

%subplot(1, 3, 1);
hold on
for i = lineOrder
    x = sort(topNPathError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end
xlabel('Timed Path Error (m)','FontSize',12);
ylabel('Probability','FontSize',12);
grid on;
legend(legendTexts{lineOrder}, 'Location', 'SouthEast');
saveplot([dirSaveFigure 'real_driving_greedyA_path']);


cfigure(14,6);

hold on
for i = lineOrder
    x = sort(topNShapeError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end

xlabel('Path Error (m)', 'FontSize',12);
ylabel('Probability', 'FontSize',12);
grid on;
legend(legendTexts{lineOrder}, 'Location', 'SouthEast');
saveplot([dirSaveFigure 'real_driving_greedyA_shape']);

% bi-shape

cfigure(14,6);

hold on
for i = lineOrder
    x = sort(topNBiShapeError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end

xlabel('Bi-Path Error (m)', 'FontSize',12);
ylabel('Probability', 'FontSize',12);
grid on;
legend(legendTexts{lineOrder}, 'Location', 'SouthEast');
saveplot([dirSaveFigure 'real_driving_greedyA_bishape']);

