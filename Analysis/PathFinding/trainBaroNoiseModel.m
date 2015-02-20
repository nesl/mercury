%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration).

%% Housekeeping
clear all; clc; close all;

%% Ensure library paths are added
add_paths;

%% Load Map and Data
caseNo = 3; % 1 to 5
mapSize = 2; % 2 to 4 (5 is coming soon)

%% Inputs:

if mapSize == 2
    mapfile = '../../Data/EleSegmentSets/ucla_small/';
elseif mapSize == 3
    mapfile = '../../Data/EleSegmentSets/ucla_3x3/';
elseif mapSize == 4
    mapfile = '../../Data/EleSegmentSets/ucla_4x4/';
%elseif mapSize == 5
%    mapfile = '../../Data/EleSegmentSets/ucla_5x5/';
else
    error('Be patient. The map will come out soon.');
end

if caseNo == 1
    % around weyburn
    %    distance: 0.62 mile (1 km)
    %        time: 900 sec
    %   avg speed: 2.48mph / 4 km/h / 1.1 meter/sec
    sensorfile = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';
elseif caseNo == 2
    % sunset
    %    distance: 1.26 mile (2.02 km)
    %        time: 150 sec
    %   avg speed: 30mph / 48.5 km/h / 13.4 meter/sec
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
elseif caseNo == 3
    % sunset + hilgard
    %    distance: 2.59 mile (4.17 km)
    %        time: 445 sec
    %   avg speed: 20.95mph / 33.7 km/h / 9.36 meter/sec
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
elseif caseNo == 4
    % wilshire + gayley + sunset + hilgard
    %    distance: ?? mile (?? km)
    %        time: 819 sec
    %   avg speed: ??mph / ?? km/h / ?? meter/sec
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
elseif caseNo == 5
    % hill on east ucla 1
    %    distance: ?? mile (?? km)
    %        time: 444 sec
    %   avg speed: ??mph / ?? km/h / ?? meter/sec
    sensorfile = '../../Data/rawData/baro_n503_20150110_161641.baro.csv';
else
    error('Kidding me? You didn''t choose a correct test case!');
end

% create objects
sensor_data = SensorData(sensorfile);
map_data = MapData(mapfile);
map_lines = map_data.getAllSegLatLng();

if caseNo == 1
    sensor_data.setSeaPressure(1020);
    sensor_data.setPressureScalar(-8.15);
    sensor_data.setAbsoluteSegment(1418102835, 1418103643);
    map_data = MapData(mapfile, 1);   % correct:1
elseif caseNo == 2
    sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.2);
    sensor_data.setAbsoluteSegment(1421002543, 1421002693);
    sensor_data.setWindowSize(0.5);   % correct:0.5
    map_data = MapData(mapfile, 1);   %correct:1
elseif caseNo == 3
    sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.2);
    sensor_data.setAbsoluteSegment(1421002543, 1421002988);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
elseif caseNo == 4
    sensor_data.setSeaPressure(1018.7);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.2);
    sensor_data.setAbsoluteSegment(1421002200, 1421003019);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
elseif caseNo == 5
    sensor_data.setSeaPressure(1016.0);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.3);
    sensor_data.setAbsoluteSegment(1420935640, 1420936084);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
end

%% Get elevations
elev_est = sensor_data.getElevation();
elev_map = sensor_data.getGps2Ele();

% time align signals
elev_est_rsz = zeros( size(elev_map,1), 2);
for i=1:size(elev_map,1)
    % transfer time over
    elev_est_rsz(i,1) = elev_map(i,1);
    % find closest idx in elev_est
    idx_near = round( size(elev_est,1)*i/size(elev_map,1) );
    idx_near = min( max(1, idx_near), size(elev_est,1) );
    elev_est_rsz(i,2) = elev_est(idx_near, 2);
end


%% Plot elevations
figure();
subplot(2,1,1);
plot(elev_est_rsz(:,1), elev_est_rsz(:,2));
hold on;
plot(elev_map(:,1), elev_map(:,4), 'b');

%% Plot error
subplot(2,1,2);
estError = elev_est_rsz(:,2) - elev_map(:,4);
plot(elev_est_rsz(:,1), estError,'r');




















