%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration). 

%% Housekeeping
clear all; clc; close all;

%% Ensure library paths are added
add_paths;

%% knot
caseNo = 3;

%% Inputs:


if caseNo == 2
    % sunset
    %    distance: 1.26 mile (2.02 km)
    %        time: 150 sec
    %   avg speed: 30mph / 48.5 km/h / 13.4 meter/sec
    mapfile =    '../../Data/EleSegmentSets/ucla_small/';
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
    outputWebFile = '../../Data/resultSets/case2_ucla_small_sunset_results.rset';
    % Create SensorData object
    sensor_data = SensorData(sensorfile);
    % test-specific settings
    sensor_data.setSeaPressure(1019.5);
    sensor_data.setPressureScalar(-7.97);
    sensor_data.setAbsoluteSegment(1421002543, 1421002693);
    sensor_data.setWindowSize(3);   % correct:0.5
    % Create MapData object
    map_data = MapData(mapfile, 6);   %correct:1
    solver = Solver_dp2(map_data, sensor_data);
elseif caseNo == 3
    % sunset + hilgard
    %    distance: 1.26+1.33 mile (2.02 km)
    %        time: 445 sec
    %   avg speed: ?mph / 48.5 km/h / 13.4 meter/sec
    mapfile =    '../../Data/EleSegmentSets/ucla_small/';
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
    outputWebFile = '../../Data/resultSets/case3_ucla_small_sunset_hilgard_results.rset';
    % Create SensorData object
    sensor_data = SensorData(sensorfile);
    % test-specific settings
    sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.2);
    sensor_data.setAbsoluteSegment(1421002543, 1421002988);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    % Create MapData object
    map_data = MapData(mapfile, 2);  % finer case: 1
    solver = Solver_dp2(map_data, sensor_data);
    solver.setHardDTWScoreThreshold(2500);  % finer case: to smaller?
else
    error('Kidding me? You didn''t choose a correct test case!');
end



%% test solver
tic

solver.setOutputFilePath(outputWebFile);
solver.solve();
solver.getRawPath(1)
solver.plotPathComparison(1)
solver.toWeb();
toc

return;

%% test and insert the oracle path based on the true gps
solver.forceInsertOraclePath();  

%% test on coefficient of test case 3
sensor_data = SensorData(sensorfile);

% test-specific settings

%% continue
sensor_data.setSeaPressure(1018.7);
sensor_data.setPressureScalar(-8.2);
sensor_data.setAbsoluteSegment(1421002543, 1421002988);
sensor_data.plotElevation();

