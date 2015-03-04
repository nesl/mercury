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
    mapfile = '../../Data/EleSegmentSets/ucla_small.map';
elseif mapSize == 3
    mapfile = '../../Data/EleSegmentSets/ucla_3x3.map';
elseif mapSize == 4
    mapfile = '../../Data/EleSegmentSets/ucla_4x4.map';
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

%% Choose paths to examine
% correct path (true only under mapSize=2, case=2)
path_true = [
         1    33
    21    36
   118   256
   146   269
   149   267
   208   268
   215   234
   230   153
   300    18];
path_true = path_true(:,2);

% multiple bad paths
tmp1 = [122773634
122773638
122643265
122773641
122752265
122752261
122752257
122824159
123161854
];
tmp1 = map_data.nodesToIdxs(tmp1);

tmp2 = [122584740
122584748
122584755
122584764
122584789
496202094
496202095
122914625
123526804
122584823
];
tmp2 = map_data.nodesToIdxs(tmp2);

tmp3 = [122978990
123036806
123148520
123191897
123191894
122867535
122867533
122867531
123138234
122681075
122914606
];
tmp3 = map_data.nodesToIdxs(tmp3);

tmp4 = [122914625
122914624
122914622
1717288137
123370940
592635874
122978981
123148498
122681080
122914608
122762246
122914606
122867526
];
tmp4 = map_data.nodesToIdxs(tmp4);

path_bad = {tmp1 tmp2 tmp3 tmp4};

%% Get the turn estimates
turns_sensor = sensor_data.getTurnEvents();
turns_map_true = map_data.getPathTurns(path_true);
turns_map_bad = {};
for i=1:length(path_bad)
    turns_map_bad = [turns_map_bad;
        map_data.getPathTurns(path_bad{i})];
end


%% Plot
close all;
subplot(4,1,1);
stem(turns_sensor(:,2),'m','LineWidth',3);
subplot(4,1,2);
stem(turns_map_true, 'r','LineWidth',3);

for i=1:2
    subplot(4,1,2+i);
    stem(turns_map_bad{i+2}, 'b','LineWidth',3);
end


fprintf('Correct cost: %.2f\n', 1e-4*DTW_MSE(turns_sensor(:,2), turns_map_true));
fprintf('BAD1 cost: %.2f\n', 1e-4*DTW_MSE(turns_sensor(:,2), turns_map_bad{3}));
fprintf('BAD2 cost: %.2f\n', 1e-4*DTW_MSE(turns_sensor(:,2), turns_map_bad{4}));























