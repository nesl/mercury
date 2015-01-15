%% Housekeeping
clc; close all; clear all;
addpaths;

%% Load Elevation Matrix
felev = '../../Services/Elevation/storage/Ucla/';
fmeta = 'meta.txt';
[ res, latvec, lngvec, npts ] = parseElevationGridMetafile([felev fmeta]);
fname = 'data.csv';
alt = csvread([felev fname]);

%% Load Candidate Sensory Data
[baroRaw, accRaw, gyroRaw, magRaw, gpsRaw, gpsSpeed] = ...
    parsesensors('n501_20150108_221546');

%% Crop Sensory Data
start_time = 0;
end_time = 0;

%% Estimate Candidate Path
[path_est, speed_est] = estimatePath(baroRaw, accRaw, gyroRaw);
plot(speed_est);
hold on;
plot(gpsSpeed,'r');
grid on;

%% Surface Plot
% cfigure(50,20);
% surf(lngvec, latvec, alt);
% colormap hsv
% alpha(0.4);
% 
% xlabel('Longitude (E/W)','FontSize',14);
% ylabel('Latitude (N/S)','FontSize',14);
% zlabel('Elevation (m)','FontSize',14);
