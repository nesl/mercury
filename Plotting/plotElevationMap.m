%% Housekeeping
clc; close all; clear all;

%% Data storage path
fpath = '../Services/Elevation/storage/Ucla/';

%% Load meta data
fname = 'meta.txt';
[ res, latvec, lngvec, npts ] = parseElevationGridMetafile([fpath fname]);

%% Load elevation
fname = 'data.csv';
alt = csvread([fpath fname]);


%% Surface Plot
cfigure(50,20);
surf(lngvec, latvec, alt);
colormap hsv
alpha(0.4);

xlabel('Longitude (E/W)','FontSize',14);
ylabel('Latitude (N/S)','FontSize',14);
zlabel('Elevation (m)','FontSize',14);
