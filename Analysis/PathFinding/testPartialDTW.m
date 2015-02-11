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
    344
    336
    257
    3
    1
];

%% Full map elevation
true_elev_map = map_data.getPathElev(true_idxs);
bad_elev_map = map_data.getPathElev(bad_idxs);

%% Full sensor elevation
elev_est_full = sensor_data.getElevation();
elev_est_full = elev_est_full(:,2);
delta_good = true_elev_map(1) - elev_est_full(1);
delta_bad = bad_elev_map(1) - elev_est_full(1);
good_elev_est = elev_est_full + delta_good;
bad_elev_est = elev_est_full + delta_bad;

% plot(true_elev_map, 'b');
% hold on;
% plot(bad_elev_map,'r');
% plot(good_elev_est,'k');


figure();

costs_g = [];
costs_b = [];

for L=1:5:100
    partial_good = true_elev_map(1: round(L/100*length(true_elev_map)) );
    partial_bad = bad_elev_map(1: round(L/100*length(bad_elev_map)) );
    
    cg = DTW_greedy(elev_est_full, partial_good);
    cb = DTW_greedy(elev_est_full, partial_bad);
    
    costs_g = [costs_g; cg];
    costs_b = [costs_b; cb];
    
%     plot(elev_est_full);
%     hold on;
%     plot(partial,'r','LineWidth',2);
    
    fprintf('L = %d / %d\n', L, 100);
    
    %pause()
    
    
end


plot(costs_g, 'b');
hold on;
plot(costs_b, 'r');


























