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

%% Create a single map explorer
e = GraphExplorer(map_data, sensor_data, 100, 0.5);

%% Explore and plot
figure();

for i=1:100
    fprintf('Iteration: %d\n', i);
    
    % plot everything
    paths = e.getLinesToPlot();
    for p=1:length(paths);
        path = paths{p};
        % long, lat
        plot(path(:,2), path(:,1), 'r');
        hold on;
    end
    
    % explore
    e.exploreNewNodes();
    % prune
    
    pause();
    
    % clear plot
    hold off;
end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    