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
caseNo = 1; % 1 to 5
mapSize = 2; % 2 to 4 (5 is coming soon)

% some explanation on the map of ucla_small:
%    top_left corner: (34.080821, -118.470371)
%    bottom_right corner: (34.052816, -118.435204)
%    area: 3117m (horizontal) x 3242m (vertical) = 10.1 km^2 = 3.95 mile^2

% note for generate ucla_3x3, ucla_4x4 and ucla_5x5
%     34.085134, -118.477606
%     34.041619, -118.424563
% d    -.043515     0.053043
% x4  34.027114  -118.406882
% x5  34.012609  -118.389201
%
% ucla_small: 361 nodes, 519 segments
% ucla_4x4:  2080 nodes, 3255 segments

%% Inputs:

if mapSize == 2
    mapfile = '../../Data/EleSegmentSets/ucla_small/';
elseif mapSize == 3
    mapfile = '../../Data/EleSegmentSets/ucla_3x3/';
elseif mapSize == 4
    mapfile = '../../Data/EleSegmentSets/ucla_4x4/';
%elseif mapSize == 5
%    mapfile = '../../Data/EleSegmentSets/ucla_5x5/';
else
    error('Be patient. The map will come out soon.');
end

if caseNo == 1
    % around weyburn
    %    distance: 0.62 mile (1 km)
    %        time: 900 sec
    %   avg speed: 2.48mph / 4 km/h / 1.1 meter/sec
    sensorfile = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';
elseif caseNo == 2
    % sunset
    %    distance: 1.26 mile (2.02 km)
    %        time: 150 sec
    %   avg speed: 30mph / 48.5 km/h / 13.4 meter/sec
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
elseif caseNo == 3
    % sunset + hilgard
    %    distance: 2.59 mile (4.17 km)
    %        time: 445 sec
    %   avg speed: 20.95mph / 33.7 km/h / 9.36 meter/sec
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
elseif caseNo == 4
    % wilshire + gayley + sunset + hilgard
    %    distance: ?? mile (?? km)
    %        time: 819 sec
    %   avg speed: ??mph / ?? km/h / ?? meter/sec
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
elseif caseNo == 5
    % hill on east ucla 1
    %    distance: ?? mile (?? km)
    %        time: 444 sec
    %   avg speed: ??mph / ?? km/h / ?? meter/sec
    sensorfile = '../../Data/rawData/baro_n503_20150110_161641.baro.csv';
else
    error('Kidding me? You didn''t choose a correct test case!');
end

caseDesp = {'weyburn', 'sunset', 'sunset_hilgard', 'one_round_ucla', 'east_ucla_1'};
mapDesp = {'', 'ucla_small', 'ucla_3x3', 'ucla_4x4', 'ucla_5x5'};
outputWebFile = ['../../Data/resultSets/(B)case' num2str(caseNo) ...
    '_dp' num2str(solverVersion) '_' mapDesp{mapSize} ...
    '_' caseDesp{caseNo} '_results.rset'];

sensor_data = SensorData(sensorfile);

if caseNo == 1
    sensor_data.setSeaPressure(1020);
    sensor_data.setPressureScalar(-8.15);
    sensor_data.setAbsoluteSegment(1418102835, 1418103643);
    map_data = MapData(mapfile, 1);   % correct:1
elseif caseNo == 2
    sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.2);
    sensor_data.setAbsoluteSegment(1421002543, 1421002693);
    sensor_data.setWindowSize(0.5);   % correct:0.5
    map_data = MapData(mapfile, 1);   %correct:1
elseif caseNo == 3
    sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.2);
    sensor_data.setAbsoluteSegment(1421002543, 1421002988);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
elseif caseNo == 4
    sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.2);
    sensor_data.setAbsoluteSegment(1421002200, 1421003019);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
elseif caseNo == 5
    sensor_data.setSeaPressure(1016.0);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.3);
    sensor_data.setAbsoluteSegment(1420935640, 1420936084);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
end

if solverVersion == 2
    solver = Solver_dp2(map_data, sensor_data);
elseif solverVersion == 3
    solver = Solver_dp3(map_data, sensor_data);
else
    error('Concentrate. There''s no this kind of solver...');
end
   
if solverVersion == 2
    if caseNo == 1
        % use default
    elseif caseNo == 2
        % use default
    elseif caseNo == 3
        solver.setHardDTWScoreThreshold(2500);  % finer case: should it be smaller?
    elseif caseNo == 4
        solver.setHardDTWScoreThreshold(3500);  % have no idea about the threshold
    end
end        

%% to check the information very quickly
if 0  % to check elevation matching
    sensor_data.plotElevation();
    pause
end
if 0  % to pause and see map information
    fprintf('%d nodes, %d segments\n', map_data.getNumNodes(), map_data.getNumSegments());
    pause
end



%% test solver

solver.setOutputFilePath(outputWebFile);

tic
solver.solve();
toc

fprintf('Generate results....');
solver.getRawPath(1)
solver.plotPathComparison(1)
%solver.toWeb();
solver.toWebBeautiful();
fprintf('\n');

if solverVersion == 3  % CONSIDER: this violates the data encapsulation
    [ratioOfDTWQuery, ratioOfElements] = solver.dtw_helper.pruningRatio();
    fprintf('Pruning ratio in terms of DTW request: %.9f\n', ratioOfDTWQuery);
    fprintf('Pruning ratio in terms of result of sub-segments: %.9f\n', ratioOfElements);
end

% quick result of solver 3:
%    case  map  rank  time
%    3     3x3  2     37
%    4     3x3  1     1318
%    5     3x3  1     1300
%    3     4x4  2     34
%    4     4x4  2     1314
%    5     4x4  1     1508
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


