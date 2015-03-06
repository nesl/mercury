%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration). 

%% Housekeeping
clear all; clc; close all;

%% Ensure library paths are added
add_paths;

%% knot
solverVersion = 5;  % 2 to 5
caseNo = 6; % 1 to 5
mapSize = 6; % 1 to 5

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

%1420998405000
%1420998803000
%% Inputs:

if mapSize == 1
    mapfile = '../../Data/EleSegmentSets/ucla_west.map';
elseif mapSize == 2
    mapfile = '../../Data/EleSegmentSets/ucla_small.map';
elseif mapSize == 3
    mapfile = '../../Data/EleSegmentSets/ucla_3x3.map';
elseif mapSize == 4
    mapfile = '../../Data/EleSegmentSets/ucla_4x4.map';
elseif mapSize == 5
    mapfile = '../../Data/EleSegmentSets/ucla_5x5.map';
elseif mapSize == 6
    mapfile = '../../Data/EleSegmentSets/Los_Angeles_4x4.map';
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
elseif caseNo == 6
    % driving in Los Angeles, with only one turn, keep moving
    %    distance: ?? mile (?? km)
    %        time: 444 sec
    %   avg speed: ??mph / ?? km/h / ?? meter/sec
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
else
    error('Kidding me? You didn''t choose a correct test case!');
end

caseDesp = {'weyburn', 'sunset', 'sunset_hilgard', 'one_round_ucla', 'east_ucla_1', 'los_angeles'};
mapDesp = {'ucla_west', 'ucla_small', 'ucla_3x3', 'ucla_4x4', 'ucla_5x5', 'la_4x4'};
outputWebFile = ['../../Data/resultSets/(B)case' num2str(caseNo) ...
    '_dp' num2str(solverVersion) '_' mapDesp{mapSize} ...
    '_' caseDesp{caseNo} '_results.rset'];

sensor_data = SensorData(sensorfile);

% Note: the setSeaPressure() and setPressureScalar() just has no effect to Solver_dp4.
if caseNo == 1
    %sensor_data.setSeaPressure(1020);  % correct coefficient
    %sensor_data.setPressureScalar(-8.15);
    sensor_data.setSeaPressure(1020);
    sensor_data.setPressureScalar(-8.1);
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
    sensor_data.setSeaPressure(1018.3);  % correct coefficient hand-tuned
    sensor_data.setPressureScalar(-8.4);
    %sensor_data.setSeaPressure(1019.3);  % test different coefs. scalar shouldn't matter that much
    %sensor_data.setPressureScalar(-7.8);
    sensor_data.setAbsoluteSegment(1421002200, 1421003019);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
elseif caseNo == 5
    sensor_data.setSeaPressure(1016.0);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.3);
    sensor_data.setAbsoluteSegment(1420935640, 1420936084);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
elseif caseNo == 6
    sensor_data.setSeaPressure(1019.6);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.3);
    sensor_data.setAbsoluteSegment(1420998405, 1420998803);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
end

if solverVersion == 2
    solver = Solver_dp2(map_data, sensor_data);
elseif solverVersion == 3
    solver = Solver_dp3(map_data, sensor_data);
elseif solverVersion == 4
    solver = Solver_dp4(map_data, sensor_data, 0);
elseif solverVersion == 5
    solver = Solver_dp5(map_data, sensor_data, 0);
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
elseif solverVersion == 5
    solver.setUncertaintyRange(0);
end        

%% to check the information very quickly
pauseFlag = 0;
if 0  % to check elevation matching
    sensor_data.plotElevation();
    pause
end
if 0  % characteristics of sensor data
    tmpElev = sensor_data.getElevationTimeWindow();
    fprintf('Barometer: max elev=%f, min elev=%f\n', max(tmpElev(:,2)), min(tmpElev(:,2)));
    pauseFlag = 0;
end
if 0  % see cdf of elevation of map nodes
    map_data.plotCDFofNodeElevs();
    pause
end
if 0  % to pause and see map information
    fprintf('%d nodes, %d segments\n', map_data.getNumNodes(), map_data.getNumSegments());
    pauseFlag = 0;
end


if pauseFlag == 1
    pause
end


%% test solver

solver.setOutputFilePath(outputWebFile);

tic
solver.solve();
totalTime = toc;
fprintf('Elapsed time is %f seconds.\n', totalTime);

fprintf('Generate results....');
solver.getRawPath(1)
solver.plotPathComparison(1)
solver.toWeb();
%solver.toWebBeautiful();
fprintf('\n');

% for solver statistics
if solverVersion == 3  % CONSIDER: this violates the data encapsulation
    [ratioOfDTWQuery, ratioOfElements] = solver.dtw_helper.pruningRatio();
    fprintf('Pruning ratio in terms of DTW request: %.9f\n', ratioOfDTWQuery);
    fprintf('Pruning ratio in terms of result of sub-segments: %.9f\n', ratioOfElements);
elseif solverVersion == 4
    [ratioOfDTWQuery, ratioOfElements] = solver.queryPruningRatio();
    fprintf('Pruning ratio in terms of DTW request: %.9f\n', ratioOfDTWQuery);
    fprintf('Pruning ratio in terms of result of sub-segments: %.9f\n', ratioOfElements);
end

return;

% quick result of solvers:
%    solver case  map    rank  time
%    3      3     3x3    2     37
%    3      4     3x3    1     1318
%    3      5     3x3    1     1300
%    3      3     4x4    2     34
%    3      4     4x4    2     1314
%    3      5     4x4    1     1508
%    3t     4     4x4    1     1434
%    3t     5     5x5    1     1505
%    4      1     small  1     120
%    4      3     4x4    3     1143
%    4      4     3x3    1     28806
%    4      4     4x4    1*,4  30361
%    4      5     4x4    4     16080
%    4      5     5x5    4     13596
%    4p     2     small  1     97
%    5      4     4x4    1     314


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


%% answers


nodes = rank2(:,2);
nodes = nodes(1:end-2);  % even more correct
numNodes = numel(nodes);
clf
hold on
mapAngle = []
for i = 1:(numNodes-2)
    latlng = map_data.getNodeIdxLatLng(nodes(i+1));
    ang = map_data.getAdjacentSegmentsAngle(nodes(i:(i+2)))
    mapAngle = [mapAngle; ang];
    markerSize = max(ceil( (abs(ang) - 20) / 5 ), 3);
    if ang > 0
        plot(latlng(2), latlng(1), 'bo', 'MarkerSize', markerSize);
    else
        plot(latlng(2), latlng(1), 'bx', 'MarkerSize', markerSize);
    end
end

gpsLatLng = sensor_data.getGps();
turns = sensor_data.spanTurnEventsToVector();
for i = 1:(length(gpsLatLng)-10)
    if turns(i, 2) ~= 0
        markerSize = max(ceil( (abs( turns(i,2) ) - 20) / 5 ), 3);
        if turns(i, 2) > 0
            plot(gpsLatLng(i,3), gpsLatLng(i,2), 'ro', 'MarkerSize', markerSize);
        else
            plot(gpsLatLng(i,3), gpsLatLng(i,2), 'rx', 'MarkerSize', markerSize);
        end
    end
end

%%
%34.023412, -118.248511
%34.064590, -118.254948