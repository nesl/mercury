%% Housekeeping
clc; close all; clear all;

%% Load CSV
fpath = '../ElevationAPI/cache/';
fname = 'Bishop_res_30e-4.csv';
%fname = 'Valley_res_50e-2.csv';
%fname = 'Hawaii_res_5e-2.csv';
%fname = 'steps_res_5e-5.csv';
%fname = 'UCLA_res_1e-4.csv';

data = csvread([fpath fname]);

lat = data(:,1);
lng = data(:,2);
alt = data(:,3);


% Reshape to find lat vector, lng vector, and elevation matrix
% x = lng, y = lat
len_lng = find(diff(lat), 1, 'first');
len_lat = length(alt)/len_lng;
alt_matrix = reshape(alt, len_lng, len_lat);
lat_vec = linspace(lat(1), lat(end), len_lat)';
lng_vec = linspace(lng(1), lng(end), len_lng)';

%% Surface Plot
%scatter3(lat,lng,alt)

cfigure(50,20);
surf(lng_vec, lat_vec, alt_matrix');
colormap hsv
alpha(.4)

xlabel('Longitude (E/W)','FontSize',14);
ylabel('Latitude (N/S)','FontSize',14);
zlabel('Elevation (m)','FontSize',14);
