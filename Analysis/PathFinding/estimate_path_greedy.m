%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration).

%% Housekeeping
clear all; clc; close all;

%% Inputs:
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

%% Create Solver Object
DEBUG = true;
solver = Solver_greedy(map_data, sensor_data, DEBUG);
%solver.useAbsoluteElevation();

%% Solve !
solver.solve();
    
%% Plot best 3 results
[costs,paths] = solver.getResults();

% plot map
for l=1:length(map_lines)
    line = map_lines{l};
    plot(line(:,2), line(:,1), 'Color',[0.8 0.8 0.8]);
    hold on;
end

colors = {'r','m','b','g'};
for i=1:3
    path = paths{i};
    latlng = map_data.getPathLatLng(path);
    plot(latlng(:,2), latlng(:,1), colors{i}, 'LineWidth',2);
end
    
    
    
hold off;


























