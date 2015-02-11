%% Housekeeping
clc; close all; clear all;

%% Input files
% case 1:
mapfile =    '../../Data/EleSegmentSets/ucla_small/';
sensorfile = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';
outputWebFile = '../../Data/resultSets/case1_ucla_west_results.rset';
% also seaPressure, pressureScalar, range

%% Ensure library paths are added
add_paths;

%% Create SensorData object
sensor_data = SensorData(sensorfile);
% test-specific settings
sensor_data.setSeaPressure(1025);
sensor_data.setPressureScalar(-8.15);
sensor_data.setAbsoluteSegment(1418102835, 1418103643);

%% Create MapData object
map_data = MapData(mapfile);
map_lines = map_data.getAllSegLatLng();

% correct path
true_idxs = [
72
70
49
46
50
254
251
248
247
250
];
    
%% Full map elevation
elev_map_full = map_data.getPathElev(true_idxs);

%% Full sensor elevation
elev_est_full = sensor_data.getElevation();
elev_est_full = elev_est_full(:,2);
delta = elev_est_full(1) - elev_map_full(1);

plot(elev_map_full + delta);
hold on;
plot(elev_est_full,'r');





























