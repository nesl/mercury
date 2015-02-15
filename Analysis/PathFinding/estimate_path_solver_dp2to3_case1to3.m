%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration). 

%% Housekeeping
clear all; clc; close all;

%% Ensure library paths are added
add_paths;

%% knot
solverVersion = 3;  % 2 or 3
caseNo = 1; % 1 or 2 or 3

% some explanation on the map of ucla_small:
%    top_left corner: (34.080821, -118.470371)
%    bottom_right corner: (34.052816, -118.435204)
%    area: 3117m (horizontal) x 3242m (vertical) = 10.1 km^2 = 3.95 mile^2

%% Inputs:
if caseNo == 1
    % around weyburn
    %    distance: 0.62 mile (1 km)
    %        time: 900 sec
    %   avg speed: 2.48mph / 4 km/h / 1.1 meter/sec
    mapfile =    '../../Data/EleSegmentSets/ucla_small/';
    sensorfile = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';
    outputWebFile = ['../../Data/resultSets/case1_dp' num2str(solverVersion) '_ucla_small_weyburn_results.rset'];
    % Create SensorData object
    sensor_data = SensorData(sensorfile);
    % test-specific settings
    sensor_data.setSeaPressure(1020);
    sensor_data.setPressureScalar(-8.15);
    sensor_data.setAbsoluteSegment(1418102835, 1418103643);
    %sensor_data.setWindowSize(5);   % default window size is 5
    map_data = MapData(mapfile, 1);   % correct:1
    if solverVersion == 2
        solver = Solver_dp2(map_data, sensor_data);
    elseif solverVersion == 3
        solver = Solver_dp3(map_data, sensor_data);
    else
        error('Concentrate. There''s no this kind of solver...');
    end
elseif caseNo == 2
    % sunset
    %    distance: 1.26 mile (2.02 km)
    %        time: 150 sec
    %   avg speed: 30mph / 48.5 km/h / 13.4 meter/sec
    mapfile =    '../../Data/EleSegmentSets/ucla_small/';
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
    outputWebFile = ['../../Data/resultSets/case2_dp' num2str(solverVersion) '_ucla_small_sunset_results.rset'];
    % Create SensorData object
    sensor_data = SensorData(sensorfile);
    % test-specific settings
    %sensor_data.setSeaPressure(1019.5);
    %sensor_data.setPressureScalar(-7.97);
    sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.2);
    sensor_data.setAbsoluteSegment(1421002543, 1421002693);
    sensor_data.setWindowSize(0.5);   % correct:0.5
    map_data = MapData(mapfile, 1);   %correct:1
        
    if solverVersion == 2
        solver = Solver_dp2(map_data, sensor_data);
    elseif solverVersion == 3
        solver = Solver_dp3(map_data, sensor_data);
    else
        error('Concentrate. There''s no this kind of solver...');
    end
elseif caseNo == 3
    % sunset + hilgard
    %    distance: 2.59 mile (4.17 km)
    %        time: 445 sec
    %   avg speed: 20.95mph / 33.7 km/h / 9.36 meter/sec
    mapfile =    '../../Data/EleSegmentSets/ucla_small/';
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
    outputWebFile = ['../../Data/resultSets/case3_dp' num2str(solverVersion) '_ucla_small_sunset_hilgard_results.rset'];
    % Create SensorData object
    sensor_data = SensorData(sensorfile);
    % test-specific settings
    sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.2);
    sensor_data.setAbsoluteSegment(1421002543, 1421002988);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
        
    if solverVersion == 2
        solver = Solver_dp2(map_data, sensor_data);
        solver.setHardDTWScoreThreshold(2500);  % finer case: to smaller?
    elseif solverVersion == 3
        solver = Solver_dp3(map_data, sensor_data);
    else
        error('Let me say that again. Specify the correct solver, okay?');
    end
else
    error('Kidding me? You didn''t choose a correct test case!');
end


%% test solver

solver.setOutputFilePath(outputWebFile);

tic
solver.solve();
toc

solver.getRawPath(1)
solver.plotPathComparison(1)
solver.toWeb();


if solverVersion == 3  % CONSIDER: this violates the data encapsulation
    [ratioOfDTWQuery, ratioOfElements] = solver.dtw_helper.pruningRatio();
    fprintf('Pruning ratio in terms of DTW request: %f\n', ratioOfDTWQuery);
    fprintf('Pruning ratio in terms of result of sub-segments: %f\n', ratioOfElements);
end

return;

%% test and insert the oracle path based on the true gps
tic
solver.forceInsertingOraclePath();
solver.toWeb();
toc

%% see the dtw trend
solver.plotPathDTWScore(1);

%% test on coefficient of test case 3
sensor_data = SensorData(sensorfile);

% test-specific settings

%% continue
sensor_data.setSeaPressure(1018.7);
sensor_data.setPressureScalar(-8.2);
sensor_data.setAbsoluteSegment(1421002543, 1421002988);
sensor_data.plotElevation();
