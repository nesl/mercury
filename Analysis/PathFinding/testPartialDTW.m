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
sensor_data.setSeaPressure(1020);
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

bad_idxs = [
    
];

%% Full map elevation
elev_map_full = map_data.getPathElev(true_idxs);

%% Full sensor elevation
elev_est_full = sensor_data.getElevation();
elev_est_full = elev_est_full(:,2);
delta = elev_map_full(1) - elev_est_full(1);
elev_est_full = elev_est_full + delta;

plot(elev_map_full);
hold on;
plot(elev_est_full,'r');

figure();

costs = [];

for L=1:5:length(elev_map_full)
    partial = elev_map_full(1:L);
    
    cost = DTW_greedy(elev_est_full, partial);
    
    costs = [costs; cost];
    
%     plot(elev_est_full);
%     hold on;
%     plot(partial,'r','LineWidth',2);
    
    fprintf('L = %d / %d, score = %.2f\n', L, length(elev_map_full), cost);
    
    %pause()
    
    
end


plot(costs);


























