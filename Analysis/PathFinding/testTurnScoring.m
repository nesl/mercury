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
     1    20
    11    22
    60    26
    75   164
    77   240
   104   253
   108   293
   116   298
   149   301
   154   323
   157   328
   167   332
   187   338
   217   317
   227   315
   230   316
   235   307
   243   303
   256   291
   263   275
   327   219
   345   230
   355   213
   386   204
   394   189
   401   162
   409   143
   413   130
   425   108
   443   100
   ];
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

%% Get map
ll = sensor_data.getGps();
gps = sensor_data.getGps();

plot(ll(:,3), ll(:,2));

%% Get the turn estimates
turns_sensor = sensor_data.getTurnEvents();
for i=1:size(turns_sensor,1)
    turn = turns_sensor(i,2);
    time = turns_sensor(i,1);
    gps_idx = find( gps(:,1) > time, 1, 'first');
    lat = gps(gps_idx, 2);
    lng = gps(gps_idx, 3);
    text(lng, lat+1e-4, num2str(turn), 'Color', 'r');
end

%% Get map turns
turns_map = map_data.getPathTurns(path_true);
ll_map = map_data.getPathLatLng(path_true);

for i=1:size(turns_map,1)
    turn = turns_map(i,2);
    idx = turns_map(i,1);
    latlng = ll_map(idx,:);
    text(latlng(2), latlng(1)-1e-4, num2str(turn), 'Color', 'b');

end


test = sensor_data.spanTurnEventsToVector();

return;





















