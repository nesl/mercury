%% Housekeeping
clc; close all; clear all;
add_paths

%SOLVER = 'greedyA';
%SOLVER = 'greedyAT';
%SOLVER = 'greedyR';
SOLVER = 'greedyA';

if ~strcmp(SOLVER, 'greedyA') && ~strcmp(SOLVER, 'greedyAT') && ~strcmp(SOLVER, 'greedyR') && ~strcmp(SOLVER, 'greedyRT')
    error('Which solver are you choosing?')
end

%% Get test cases
testdir = '../../Data/SimTestCases/';
all_files = dir(testdir);
test_files = {};
for i=1:length(all_files)
    fname = all_files(i).name;
    if isempty( regexp(fname, 'SIM') )
        continue;
    end
    test_files = [test_files; fname];
end

%% Get solved test cases
soldir = '../../Data/SimResults/';

%{

%% Loop through all test cases
for tidx=1:length(test_files)
%for tidx=28
    tfile = test_files{tidx};
    
    solfile = [tfile(1:(end-4)), '_' SOLVER '.mat'];
    solpath = [soldir solfile];
    
    fprintf('\n');
    
    if ~exist(solpath)
        fprintf('cannot find result of test caes %s, skip\n', tfile);
        continue;
    end
    
    fprintf('retrieve result from: %s\n', solfile);
    
    % solve this test case w/ greedy solver
    loaded = load([testdir tfile]);
    testcase = loaded.obj;
    
    % sensor data
    sensor_data = SensorDataSim(testcase.sim_elevations, ...
        testcase.sim_turns, testcase.sim_gps);
    elevBaroWithTime = sensor_data.getElevationTimeWindow();
    elevBaro = elevBaroWithTime(:,2);
    
    % map data
    map_data = MapData(testcase.mapFilePath{1}, testcase.mapDataDownSampling);
    
    % load result
    load(solpath, 'solver_results');
    numPaths = numel(solver_results.paths);
    
    fprintf('%d paths retrieved, solving time: %f\n', numel(solver_results.paths), solver_results.time);
    
    if numPaths == 0
        fprintf('no path, skip...\n');
    end
    % for reference
    %solver_results.scores = scores;
    %solver_results.paths = paths;
    
    % evaluation
    evaluator = Evaluator(sensor_data, map_data);
    
    pathError = zeros(numPaths, 1);
    shapeError = zeros(numPaths, 1);
    shapeErrorBi = zeros(numPaths, 1);
    
    %pathsLatLng = cell(size(solver_results.paths));
    for i = 1:numel(solver_results.paths)
        pathNodeIdxs = solver_results.paths{i};
        pathLatLng = map_data.getPathLatLng(pathNodeIdxs);
        pathElev = map_data.getPathElev(pathNodeIdxs);
        %[~, dtwIdxBaro2Map, ~] = dtw_basic( pathElev, elevBaro, @(x) (x.^2), @(x) (inf) );
        [idxFrom, idxTo, ~] = dp_backtracking(elevBaro, pathElev);
        mapToPath = zeros(1, length(elevBaro));
        for j = 1:length(elevBaro)
            idxsOfInterest = (idxFrom == j);
            mapToPath(j) = round( mean(idxTo(idxsOfInterest)) );
        end
        estiLatLngs = pathLatLng(mapToPath, :);
        estiTimeLatLngs = [ elevBaroWithTime(:,1) estiLatLngs ];
        pathError(i) = evaluator.getPathSimilarityConsideringTime(estiTimeLatLngs);
        shapeError(i) = evaluator.getPathShapeSimilarity(estiLatLngs);
        shapeErrorBi(i) = evaluator.getPathShapeSimilarityBiDirection(estiLatLngs);
    end
    
    outputWebFile = ['../../Data/resultSets/(B)[TEST_SIM]_' tfile(14:end-4) '_' SOLVER '.rset'];
    reportAttributes =      {'pathError', 'shapeError', 'shapeErrorBi', 'rawScore'};
    reportAttributeValues = [ pathError    shapeError    shapeErrorBi,   solver_results.scores];
    evaluator.toWeb(outputWebFile, 1, reportAttributes, reportAttributeValues, solver_results.paths);
    fprintf('min path error: %f\n', min(pathError)); 
    fprintf('min shape error: %f\n', min(shapeError)); 
    fprintf('min bi-dir shape error: %f\n', min(shapeErrorBi)); 
end


return;

%}


%% load for plotting

%rankOfInterest = [1 3 5 10 15 20 30 50 inf];
rankOfInterest = [1 3 5];
topNPathError = [];  % numel(rankOfInterest) by num_available_solution
topNShapeError = [];  % numel(rankOfInterest) by num_available_solution
pathVSshapeError = [];
topNBiShapeError = [];  % numel(rankOfInterest) by num_available_solution


atidx = 0;
for tidx=1:length(test_files)
    tfile = test_files{tidx};
    outputWebFile = ['../../Data/resultSets/(B)[TEST_SIM]_' tfile(14:end-4) '_' SOLVER '.rset'];
    
    if ~exist(outputWebFile)
        continue;
    end
    
    atidx = atidx + 1;
    
    fprintf([outputWebFile '\n']);
    
    fid = fopen(outputWebFile);
    for i = 1:6
        tline = fgets(fid);
    end
    
    tline = fgets(fid);
    numPaths = str2num( tline(1:end-1) );
    pathError = zeros(numPaths, 1);
    shapeError = zeros(numPaths, 1);
    biShapeError = zeros(numPaths, 1);
    
    for i = 1:numPaths
    	tline = fgets(fid);
        tline = tline(1:end-1);
        terms = strsplit(tline, ',');
        pathError(i) = str2num(terms{1});
        shapeError(i) = str2num(terms{2});
        biShapeError(i) = str2num(terms{3});
    end
    fclose(fid);
    
    for i = 1:length(rankOfInterest)
        rank = min(rankOfInterest(i), numPaths);
        topNPathError(i, atidx) = min(pathError(1:rank));
        topNShapeError(i, atidx) = min(shapeError(1:rank));
        topNBiShapeError(i, atidx) = min(biShapeError(1:rank));
    end
    
    pathVSshapeError = [pathVSshapeError; [pathError biShapeError]];
end

%% Plotting

%
cfigure(14,8);

clf

colors = {'bs-', 'r^-', 'ko-', 'm*-'};
skip = 20;

%subplot(1, 3, 1);
hold on
for i = length(rankOfInterest):-1:1
    x = sort(topNPathError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end
xlabel('Timed Path Error (m)','FontSize',12);
ylabel('Probability','FontSize',12);
grid on;
legend('5 paths', '3 paths', '1 paths','Random');
saveplot('figs/sim_greedyRT_path');


cfigure(14,8);

hold on
for i = length(rankOfInterest):-1:1
    x = sort(topNShapeError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end

xlabel('Path Error (m)', 'FontSize',12);
ylabel('Probability', 'FontSize',12);
grid on;
legend('5 paths', '3 paths', '1 paths','Random');
saveplot('figs/sim_greedyRT_shape');

% bi-shape

cfigure(14,8);

hold on
for i = length(rankOfInterest):-1:1
    x = sort(topNBiShapeError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end

xlabel('Bi-Path Error (m)', 'FontSize',12);
ylabel('Probability', 'FontSize',12);
grid on;
legend('5 paths', '3 paths', '1 paths','Location','SE');
saveplot('figs/sim_greedyA_bishape');

