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

%% Get true turns
path = [
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

path = path(:,2);

real_turns = map_data.getPathTurns(path);


%%

% get the lat/lng first
latlngs = map_data.getPathLatLng(path);
plot(latlngs(:,2), latlngs(:,1), 'bo-','MarkerSize',3);
hold on;
axis equal;

% now find absolute angles
angles = [];
for i=2:size(latlngs,1)
    % if latlng didn't change, continue
    if latlngs(i,1) - latlngs(i-1,1) == 0 &&...
       latlngs(i,2) - latlngs(i-1,2) == 0
       continue;
    end
    angle = atan2d( latlngs(i,1)-latlngs(i-1,1), latlngs(i,2)-latlngs(i-1,2) );
    angles = [angles; [i, angle]];
end


% find turns
turns = [];
thresh = 30;
decay = 7;
angle_last = angles(1,2);

for i=2:size(angles,1)
    change_since_last = angles(i,2) - angle_last;
    decay_idx = max(1, i-decay);
    change_since_decay = angles(i,2) - angles(decay_idx,2);
    
    if abs(change_since_last) > abs(change_since_decay)
        change = change_since_decay;
    else
        change = change_since_last;
    end
    

    if abs(change) > thresh
        turns = [turns; [angles(i,1) change]];
        angle_last = angles(i,2);
    end
end


% combine clusters of turns
csize = 7;

for i=1:size(turns,1)
    if i > size(turns,1)
        break;
    end
    idx = turns(i,1);
    close_idxs = find( turns(:,1) > idx & turns(:,1) - idx < csize);
    total = sum(turns([i close_idxs],2));
    total = mod( total+180, 360) - 180;
    turns(i,:) = [idx,total];
    turns(close_idxs,:) = [];
   
end

turns( abs(turns(:,2)) < 30, :) = [];


for i=1:size(turns,1)
    idx = turns(i,1);
    angle = turns(i,2);
    text(latlngs(idx,2), latlngs(idx,1)+0.0001, num2str(angle));
    
end



return;

%% Get estimated turns
est_turns = sensor_data.getTurnEvents();


%% 
% let's roughly say our turn detection error is Gaussian with a std of 
% ...


E = [
    54 - 35
    29 - 30
    49 - 31
    61 - 37
    48 - 30
    69 - 48
    31 - 30
    ];

% 10 deg.



