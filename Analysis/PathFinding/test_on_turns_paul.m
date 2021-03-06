% This code simply is a playground of turn detection. It gives me better
% intuition how the turn detection works.

%% Housekeeping
clear all; clc; close all;

%% Ensure library paths are added
add_paths;

%% Load Map and Data
caseNo = 3; % 1 to 5
mapSize = 2; % 2 to 4 (5 is coming soon)

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

% create objects
sensor_data = SensorData(sensorfile);
map_data = MapData(mapfile);
map_lines = map_data.getAllSegLatLng();

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

gps = sensor_data.getGps();

%% get turn estimates
turnAnalog = sensor_data.getTurns();
turnEvents = sensor_data.getTurnEvents();

plot(turnAnalog(:,1), turnAnalog(:,2));
hold on;
plot(turnEvents(:,1), turnEvents(:,2),'rx');

%% Get closest path from OSM map
map_path = [
       33
       36
      256
      269
      267
      268
      234
      153
       18
       16
       19
      194
       28
       26
       29
       31
      185
        5
      186
      187
      189
      128
      124
      127
      129
   ];
closest_gps = map_data.getPathLatLng(map_path);

%% Get map turns
map_turns = map_data.getPathTurns(map_path);


%% See the turn events on the map

maxTime = max( max(gps(:,1)), max(turnEvents(:,1)) );
minTime = min( min(gps(:,1)), min(turnEvents(:,1)) );
dTime = maxTime - minTime;

clf
hold on
for i = 1:size(gps, 1)
    plot(gps(i,3), gps(i,2), '*', 'Color', hsv2rgb( [ (gps(i,1) - minTime) / dTime, 1, 0.95 ] ) );
end
for i = 1:size(turnEvents, 1)
    closestGpsIdx = find(turnEvents(i,1) < gps(:,1)); 
    if numel(closestGpsIdx) == 0  % in case all the gps samples are earlier then the turn event
        closestGpsIdx = size(gps, 1);
    else
        closestGpsIdx = closestGpsIdx(1); % choose the earliest gps sample which just after this turn event
    end
    plot(gps(closestGpsIdx,3), gps(closestGpsIdx,2), 'o', 'MarkerSize', 14, 'Color', hsv2rgb( [ (turnEvents(i,1) - minTime) / dTime, 0.7, 0.4 ] ) );
    %[turnEvents(i,:) closestGpsIdx]
    text(gps(closestGpsIdx,3) + 1e-4, gps(closestGpsIdx,2) + 1e-4, num2str(turnEvents(i,2)))
end
axis equal