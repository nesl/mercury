%% Bo solver, dp5L
clear all; clc; close all;
add_paths

caseNames = {
'[Sample]_WeyburnWalking'
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
%%

total_dist = 0;
total_time = 0;

%for i = 1:size(caseNames, 1)
%for i = 27:size(caseNames, 1)
for i = 1:1:size(caseNames, 1)
    fprintf('====== case %d: %s ======\n', i, caseNames{i});
    testCase = TestCase(caseNames{i});
    sensor_data = SensorData(testCase.sensorFilePath);
    sensor_data.setAbsoluteSegment(testCase.startAbsTime, testCase.stopAbsTime);
    sensor_data.setWindowSize(testCase.sensorWindowSize);
    %map_data = MapData(testCase.mapFilePath, testCase.mapDataDownSampling);
    %solver = Solver_dp5(map_data, sensor_data, 1);
    %solver.solve();
    %webOutputPath = ['../../Data/resultSets/(B)' caseNames{i} '_dp5.rset'];
    %solver.setOutputFilePath(webOutputPath);
    %solver.toWeb();
    
    %solutionResolver_dp4(caseNames{i}, solver);
    
    % calculate dist / time tested
    gps = sensor_data.getGps();
    
    t = gps(end,1) - gps(1,1);
    total_time = total_time + t;
    d = 0;
    for i=2:size(gps,1)
        dm = latlng2m(gps(i,2:3), gps(i-1,2:3));
        total_dist = total_dist + dm;
    end
    
end

return

%% load result of Bo solver, dp5L

totalTime = [];
topNpathError = [];
topNshapeError = [];
topNbiShapeError = [];
rankOfInterest = [1 3 5];
for i = 2:size(caseNames, 1)
    solver = solutionResolver_dp4(caseNames{i});
    totalTime = [totalTime solver.getProcessingTime()];
    tmp = solver.summarizeResult('pathError',  'shapeError',  'biShapeError');
    topNpathError(end+1, 1) = 0;
    topNshapeError(end+1, 1) = 0;
    topNbiShapeError(end+1, 1) = 0;
    for j = 1:numel(rankOfInterest)
        rank = min(rankOfInterest(j), size(tmp, 1));
        topNpathError(end, j) = min( tmp(1:rank, 1) );
        topNshapeError(end, j) = min( tmp(1:rank, 2) );
        topNbiShapeError(end, j) = min( tmp(1:rank, 3) );
    end
    fprintf('finish case %d\n', i);
end


fprintf('avg solving time = %f +/- %f sec\n', mean(totalTime), std(totalTime));
%
clf
subplot(1, 3, 1)
hold on
cdfplot(topNpathError(:,1));
cdfplot(topNpathError(:,2));
cdfplot(topNpathError(:,3));
subplot(1, 3, 2)
hold on
cdfplot(topNshapeError(:,1));
cdfplot(topNshapeError(:,2));
cdfplot(topNshapeError(:,3));
subplot(1, 3, 3)
hold on
cdfplot(topNbiShapeError(:,1));
cdfplot(topNbiShapeError(:,2));
cdfplot(topNbiShapeError(:,3));
return

%% Paul solver, greedyA

for i = 2:numel(caseNames)
    fprintf('====== case %d: %s ======\n', i, caseNames{i});
    testCase = TestCase(caseNames{i});
    sensor_data = SensorData(testCase.sensorFilePath);
    sensor_data.setAbsoluteSegment(testCase.startAbsTime, testCase.stopAbsTime);
    sensor_data.setWindowSize(testCase.sensorWindowSize);
    sensor_data.setSeaPressure(testCase.seaPressure);
    sensor_data.setPressureScalar(testCase.pressureScalar);
    map_data = MapData(testCase.mapFilePath, testCase.mapDataDownSampling);
    solver = Solver_greedy(map_data, sensor_data);
    solver.setNumPathsToKeep(40);
    solver.useAbsoluteElevation();
    %solver.useTurns();
    
    tic;
    solver.solve();
    solvetime = toc;
    [scores, paths] = solver.getResults();
    % evaluation
    evaluator = Evaluator(sensor_data, map_data);
    
    pathError = zeros(numel(paths), 1);
    shapeError = zeros(numel(paths), 1);
    shapeErrorBi = zeros(numel(paths), 1);
    
    elevBaroWithTime = sensor_data.getElevationTimeWindow();
    elevBaro = elevBaroWithTime(:,2);
    
    %pathsLatLng = cell(size(solver_results.paths));
    for j = 1:numel(paths)
        pathNodeIdxs = paths{j};
        pathLatLng = map_data.getPathLatLng(pathNodeIdxs);
        pathElev = map_data.getPathElev(pathNodeIdxs);
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
    
    webOutputPath = ['../../Data/resultSets/(B)' caseNames{i} '_greedyA.rset'];
    reportAttributes =      {'pathError', 'shapeError', 'shapeErrorBi', 'rawScore'};
    reportAttributeValues = [ pathError    shapeError    shapeErrorBi,   scores];
    evaluator.toWeb(webOutputPath, 1, reportAttributes, reportAttributeValues, paths);
    fprintf('min path error: %f\n', min(pathError)); 
    fprintf('min shape error: %f\n', min(shapeError)); 
    fprintf('min bi-dir shape error: %f\n', min(shapeErrorBi)); 
    
    solutionResolver_dp4([caseNames{i} '_greedyA'], solver);
end

return

%% load result of Paul solver, greedyA

totalTime = [];
topNpathError = [];
topNshapeError = [];
topNbiShapeError = [];
rankOfInterest = [1 3 5];
for i = 2:size(caseNames, 1)
    solver = solutionResolver_dp4([caseNames{i} '_greedyA']);
    [scores, paths] = solver.getResults();
    % evaluation
    evaluator = Evaluator(sensor_data, map_data);
    
    pathError = zeros(numel(paths), 1);
    shapeError = zeros(numel(paths), 1);
    shapeErrorBi = zeros(numel(paths), 1);
    
    elevBaroWithTime = sensor_data.getElevationTimeWindow();
    elevBaro = elevBaroWithTime(:,2);
    
    %pathsLatLng = cell(size(solver_results.paths));
    for j = 1:numel(paths)
        pathNodeIdxs = paths{j};
        pathLatLng = map_data.getPathLatLng(pathNodeIdxs);
        pathElev = map_data.getPathElev(pathNodeIdxs);
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
    
    topNpathError(end+1, 1) = 0;
    topNshapeError(end+1, 1) = 0;
    topNbiShapeError(end+1, 1) = 0;
    for j = 1:numel(rankOfInterest)
        rank = min(rankOfInterest(j), numel(paths));
        topNpathError(end, j) = min( pathError(1:rank, 1) );
        topNshapeError(end, j) = min( shapeError(1:rank, 2) );
        topNbiShapeError(end, j) = min( shapeErrorBi(1:rank, 3) );
    end
    fprintf('finish case %d\n', i);
end


fprintf('avg solving time = %f +/- %f sec\n', mean(totalTime), std(totalTime));
%
clf
subplot(1, 3, 1)
hold on
cdfplot(topNpathError(:,1));
cdfplot(topNpathError(:,2));
cdfplot(topNpathError(:,3));
subplot(1, 3, 2)
hold on
cdfplot(topNshapeError(:,1));
cdfplot(topNshapeError(:,2));
cdfplot(topNshapeError(:,3));
subplot(1, 3, 3)
hold on
cdfplot(topNbiShapeError(:,1));
cdfplot(topNbiShapeError(:,2));
cdfplot(topNbiShapeError(:,3));
return
