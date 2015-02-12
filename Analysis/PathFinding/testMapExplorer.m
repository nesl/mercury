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

% correct path indices
%     1    72
%     15    70
%     27    49
%     37    46
%     56    50
%     67   254
%     78   251
%     88   248
%    118   247
%    162   250

%% Create a single map explorer
e_good = GraphExplorer(map_data, sensor_data, 72, 0.5);
e_bad  = GraphExplorer(map_data, sensor_data, 259, 0.5);

%% Explore and plot
figure();

for i=1:100
    fprintf('Iteration: %d\n', i);
    
    % explore
    e_good.exploreNewNodes();
    e_bad.exploreNewNodes();
    % prune
    e_good.prunePaths();
    e_bad.prunePaths();
    
    % best cost score
    fprintf('good = %.2f, bad = %.2f\n', e_good.cost, e_bad.cost);
    
    
    %pause();
    
    % clear plot
    %hold off;
end


    

























