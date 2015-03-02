clear all; clc; close all;
add_paths

caseNames = {
'[Sample]_WeyburnWalking'
'[Bo-Driving]_1-1'
'[Bo-Driving]_1-2'
'[Bo-Driving]_1-3'
'[Bo-Driving]_1-4'
'[Bo-Driving]_1-5'
'[Bo-Driving]_1-6'
'[Bo-Driving]_2-1'
'[Bo-Driving]_2-2'
'[Bo-Driving]_2-3'
'[Bo-Driving]_2-4'
'[Bo-Driving]_2-5'
'[Bo-Driving]_2-6'
'[Bo-Driving]_2-7'
'[Bo-Driving]_2-8'
'[Bo-Driving]_2-9'
'[Bo-Driving]_2-10'
'[Bo-Driving]_2-11'
'[Bo-Driving]_3-1'
'[Bo-Driving]_3-2'
'[Bo-Driving]_3-3'
'[Bo-Driving]_3-4'
'[Bo-Driving]_3-5'
'[Bo-Driving]_3-6'
'[Bo-Driving]_3-7'
'[Bo-Driving]_3-8'
'[Bo-Driving]_4-1'
'[Bo-Driving]_4-2'
'[Bo-Driving]_4-3'
'[Bo-Driving]_5-1'
'[Bo-Driving]_5-2'
'[Bo-Driving]_5-3'
};

%for i = 1:size(caseNames, 1)
for i = 7:7
    fprintf('====== case %d: %s ======\n', i, caseNames{i});
    testCase = TestCase(caseNames{i});
    sensor_data = SensorData(testCase.sensorFilePath);
    sensor_data.setAbsoluteSegment(testCase.startAbsTime, testCase.stopAbsTime);
    sensor_data.setWindowSize(testCase.sensorWindowSize);
    map_data = MapData(testCase.mapFilePath, testCase.mapDataDownSampling);
    solver = Solver_dp4(map_data, sensor_data, 0);
    solver.solve();
    webOutputPath = ['../../Data/resultSets/(B)' caseNames{i} '_dp4.rset'];
    solver.setOutputFilePath(webOutputPath);
    solver.toWebBeautiful();
    
    solutionResolver_dp4(caseNames{i}, solver);
end