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

%% Result vector
estimate = [
    34.0706085,-118.4577168
    34.0708475,-118.4568747
    34.0721430,-118.4559683
    34.0721934,-118.4551704
    34.0703256,-118.4549958
    34.0689644,-118.4548780
    34.0684249,-118.4548267
    34.0683189,-118.4536522
    34.0682265,-118.4525286
    34.0664273,-118.4519261
    34.0661942,-118.4507079
    34.0656797,-118.4505131
    34.0644757,-118.4499587
    34.0636214,-118.4491386
    34.0628512,-118.4483215
    34.0619693,-118.4479670
    34.0625329,-118.4470263
    34.0607063,-118.4457055
    ];

estimate_heights = zeros(size(estimate,1), 1);
for i=1:length(estimate_heights)
    lat = estimate(i,1);
    lng = estimate(i,2);
    [~,close_lat_idx] = min( abs(latvec-lat) );
    [~,close_lng_idx] = min( abs(lngvec-lng) );
    estimate_heights(i) = alt(close_lat_idx, close_lng_idx);
end

%% Surface Plot
cfigure(50,20);
surf(lngvec, latvec, alt, 'LineWidth',0.2); %, 'EdgeColor','none');
colormap jet
alpha(0.5);
hold on;
plot3(estimate(:,2), estimate(:,1), estimate_heights+3, 'm','LineWidth',5);
plot3(estimate(:,2), estimate(:,1), estimate_heights, 'Color',[0.1 0 0.1],'LineWidth',5);


camorbit(50,20);

xlabel('Longitude (E/W)','FontSize',14);
ylabel('Latitude (N/S)','FontSize',14);
zlabel('Elevation (m)','FontSize',14);
grid off;
axis off;


%% Save figure
saveplot('output/ElevationGridWithEstimatedPath');