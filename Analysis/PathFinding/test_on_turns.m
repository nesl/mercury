% This code simply is a playground of turn detection. It gives me better
% intuition how the turn detection works.

%% Housekeeping
clear all; clc; close all;

%% Ensure library paths are added
add_paths;

%% load data
% borrow from case 3

mapfile =    '../../Data/EleSegmentSets/ucla_small.map';
sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
sensor_data = SensorData(sensorfile);
%{
sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
sensor_data.setPressureScalar(-8.2);
sensor_data.setAbsoluteSegment(1421002543, 1421002988);
sensor_data.setWindowSize(0.5);   % correct:0.5
map_data = MapData(mapfile, 1);   %correct:1
%}

sensor_data.setSeaPressure(1018.7);  % correct coefficient hand-tuned
sensor_data.setPressureScalar(-8.2);
%sensor_data.setSeaPressure(1019.3);  % test different coefs. scalar shouldn't matter that much
%sensor_data.setPressureScalar(-7.8);
sensor_data.setAbsoluteSegment(1421002200, 1421003019);
sensor_data.setWindowSize(1);  % finer case: 0.5
map_data = MapData(mapfile, 2);  % finer case: 1

    
%% Playground
turns = sensor_data.getTurns();
turnEvents = sensor_data.getTurnEvents();

%% See the turn events on the map
gps = sensor_data.getGps();
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


%% see the turn events from the sensor and also from the path

% 
% path = map_data.getRandomWalk(-1, 1000, 0);
% for i = 1:10
%     i
%     path(i:(i+2))
%     segLatLngA = map_data.getSegLatLng([path(i  ) path(i+1)]);
%     segLatLngB = map_data.getSegLatLng([path(i+1) path(i+2)]);
%     map_data.segment_end_orientation(path(i), path(i+1))
%     map_data.segment_start_orientation(path(i+1), path(i+2))
%     map_data.getAdjacentSegmentsAngle(path(i:(i+2)))
%     clf
%     hold on
%     plot(segLatLngA(:,2), segLatLngA(:,1), 'r-o');
%     plot(segLatLngB(:,2), segLatLngB(:,1), 'g-o');
%     axis equal
%     pause
% end
% 

