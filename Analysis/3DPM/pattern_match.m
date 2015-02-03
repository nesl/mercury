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
[turn_angles] = estimateTurns(baroRaw, accRaw, gyroRaw);
% cfigure(30,12);
% stem(turn_angles(:,1)/1e9 - turn_angles(1,1)/1e9, turn_angles(:,2),'or','LineWidth',2);
% xlabel('Time (sec)','FontSize',12);
% ylabel('Turn angle (degrees)','FontSize',12);
% grid on;

%% Surface Plot
% cfigure(50,20);
% surf(lngvec, latvec, alt);
% colormap hsv
% alpha(0.4);
% 
% xlabel('Longitude (E/W)','FontSize',14);
% ylabel('Latitude (N/S)','FontSize',14);
% zlabel('Elevation (m)','FontSize',14);
