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
'[Bo-Driving]_4-1_size4'
'[Bo-Driving]_5-1_size4'
'[Bo-Driving]_5-2_size4'
'[Bo-Driving]_5-3_size4'
};

%for i = 1:size(caseNames, 1)
%for i = 27:size(caseNames, 1)
for i = 10:26
    fprintf('====== case %d: %s ======\n', i, caseNames{i});
    testCase = TestCase(caseNames{i});
    sensor_data = SensorData(testCase.sensorFilePath);
    sensor_data.setAbsoluteSegment(testCase.startAbsTime, testCase.stopAbsTime);
    sensor_data.setWindowSize(testCase.sensorWindowSize);
    map_data = MapData(testCase.mapFilePath, testCase.mapDataDownSampling);
    solver = Solver_dp5(map_data, sensor_data, 1);
    solver.solve();
    webOutputPath = ['../../Data/resultSets/(B)' caseNames{i} '_dp5.rset'];
    solver.setOutputFilePath(webOutputPath);
    solver.toWeb();
    
    solutionResolver_dp4(caseNames{i}, solver);
end

return

%% Paul solver
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
'[Bo-Driving]_4-1_size4'
'[Bo-Driving]_5-1_size4'
'[Bo-Driving]_5-2_size4'
'[Bo-Driving]_5-3_size4'
};

for i = 2:size(caseNames, 1)
    fprintf('====== case %d: %s ======\n', i, caseNames{i});
    testCase = TestCase(caseNames{i});
    sensor_data = SensorData(testCase.sensorFilePath);
    sensor_data.setAbsoluteSegment(testCase.startAbsTime, testCase.stopAbsTime);
    sensor_data.setWindowSize(testCase.sensorWindowSize);
    map_data = MapData(testCase.mapFilePath, testCase.mapDataDownSampling);
    solver = Solver_greedy(map_data, sensor_data);
    solver.setNumPathsToKeep(40);
    solver.useAbsoluteElevation();
    %solver.useTurns();
    
    solver.solve();
    tic;
    solver.solve();
    solvetime = toc;
    [scores, paths] = solver.getResults();
    solver_results.time = solvetime;
    solver_results.scores = scores;
    solver_results.paths = paths;
    
    webOutputPath = ['../../Data/resultSets/(B)' caseNames{i} '_greedyA.rset'];
    solver.setOutputFilePath(webOutputPath);
    solver.toWeb();
    
    solutionResolver_dp4([caseNames{i} '_greedyA'], solver);
end

return

