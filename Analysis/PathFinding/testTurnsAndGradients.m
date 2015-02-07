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
sensor_data.setAbsoluteSegment(1418102835, 1418106643);

%% Create MapData object
map_data = MapData(mapfile);

%% test a certain path
nlist = [
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


%% Map change in elevation and angles
mapElevDeriv = map_data.getPathElev(nlist);
mapTurns = map_data.getPathTurns(nlist);

%% Sensor change in elevation and angles
estElevDeriv = sensor_data.getElevation();
estTurns = sensor_data.getTurns();

%% PLOTS
close all
plot(mapElevDeriv, 'b');
hold on;
plot(estElevDeriv(:,2),'--r');
xlabel('index (not equal timing)');
ylabel('Change in Elevation');
