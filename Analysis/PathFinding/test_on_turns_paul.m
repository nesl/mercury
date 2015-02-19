% This code simply is a playground of turn detection. It gives me better
% intuition how the turn detection works.

%% Housekeeping
clear all; clc; close all;

%% Ensure library paths are added
add_paths;

%% load data
% borrow from case 3
mapfile =    '../../Data/EleSegmentSets/ucla_small/';
sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
sensor_data = SensorData(sensorfile);
sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
sensor_data.setPressureScalar(-8.2);
sensor_data.setAbsoluteSegment(1421002543, 1421002988);
sensor_data.setWindowSize(0.5);   % correct:0.5
map_data = MapData(mapfile, 1);   %correct:1
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
map_turns = map_data.getTurnsFromNodes(map_path);


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