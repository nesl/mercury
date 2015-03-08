%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration).

%% Housekeeping
clear all; clc; close all;

%% Ensure library paths are added
add_paths;

%% Load Map and Data
caseNo = 4; % 1 to 5
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
    %sensor_data.setSeaPressure(1020);  % correct coefficient
    %sensor_data.setPressureScalar(-8.15);
    sensor_data.setSeaPressure(1020);
    sensor_data.setPressureScalar(-8.1);
    sensor_data.setAbsoluteSegment(1418102835, 1418103643);
    map_data = MapData(mapfile, 1);   % correct:1
elseif caseNo == 2
    sensor_data.setSeaPressure(1018.3);  % correct coefficient hand-tuned
    sensor_data.setPressureScalar(-8.4);
    sensor_data.setAbsoluteSegment(1421002543, 1421002693);
    sensor_data.setWindowSize(0.5);   % correct:0.5
    map_data = MapData(mapfile, 1);   %correct:1
elseif caseNo == 3
    sensor_data.setSeaPressure(1018.3);  % correct coefficient hand-tuned
    sensor_data.setPressureScalar(-8.4);
    sensor_data.setAbsoluteSegment(1421002543, 1421002988);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
elseif caseNo == 4
    sensor_data.setSeaPressure(1018.3);  % correct coefficient hand-tuned
    sensor_data.setPressureScalar(-8.4);
    %sensor_data.setSeaPressure(1019.3);  % test different coefs. scalar shouldn't matter that much
    %sensor_data.setPressureScalar(-7.8);
    sensor_data.setAbsoluteSegment(1421002200, 1421003019);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
elseif caseNo == 5
    sensor_data.setSeaPressure(1016.0);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.3);
    sensor_data.setAbsoluteSegment(1420935640, 1420936084);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
elseif caseNo == 6
    sensor_data.setSeaPressure(1019.6);  % coefficient hand-tuned
    sensor_data.setPressureScalar(-8.3);
    sensor_data.setAbsoluteSegment(1420998405, 1420998803);
    sensor_data.setWindowSize(1);  % finer case: 0.5
    map_data = MapData(mapfile, 2);  % finer case: 1
end

map_lines = map_data.getAllSegLatLng();


%% Create Solver Object
DEBUG = true;
solver = Solver_greedy(map_data, sensor_data);
solver.setNumPathsToKeep(40);
solver.useAbsoluteElevation();
solver.useTurns();

%% Solve !
tic;
solver.solve();
toc;
    
%% Plot best 3 results
[costs,paths] = solver.getResults();
figure
% plot map
for l=1:length(map_lines)
    line = map_lines{l};
    plot(line(:,2), line(:,1), 'Color',[0.8 0.8 0.8]);
    hold on;
end

colors = {'m','r','b','g', 'y'};
for i=4:-1:1
    path = paths{i};
    latlng = map_data.getPathLatLng(path);
    plot(latlng(:,2), latlng(:,1), colors{i}, 'LineWidth',2);
end

hold off;

return;

%% Compare elevation / DTW for the top results
[costs,paths] = solver.getResults();

elev_true = sensor_data.getElevationTimeWindow();

colors = {'m','r','b','g', 'y'};
for i=4:-1:1
    path = paths{i};
    elev = map_data.getPathElev(path);
    delta = 0;
    if solver.use_absolute_elevation
        plot(elev, colors{i}, 'LineWidth',2);
        xend = length(elev);
        text( xend, elev(xend)+0.1, num2str(costs(i)) );
    else
        delta = elev(1) - elev_true(1,2);
        plot(elev - delta, colors{i}, 'LineWidth',2);
        xend = length(elev);
        text( xend+2, elev(xend) - delta+0.1, num2str(costs(i)) );
    end
    hold on;
    
    fprintf(' Path [%d] has DTW score: %.2f\n', i, DTW_greedy(elev_true(:,2) + delta, elev) );

end
plot(elev_true(:,2),'k--');


hold off;

return;


%% get weight function
% y = C * log(x-A) + B
% 0.5         0
% 0.9         20
% 1           1000

exp21 = exp(0.4);
exp32 = exp(0.1);

%ax^2 + bx + c
coefl = conv([-1 0], [-1 1000]) * exp21;
coefr = conv([-1 20], [-1 20]) * exp32;
coeff = coefl - coefr;
fa = coeff(1);
fb = coeff(2);
fc = coeff(3);
fD = sqrt(fb * fb - 4 * fa * fc);
fx1 = (-fb + fD) / 2 / fa;
fx2 = (-fb - fD) / 2 / fa;
% we want nagative one
A = fx2;
C = 0.4 / log((20-A) / -A);
B = 0.5 - C * log(-A);
[A B C];
x = 0:1000;
y = C * log(x-A) + B

plot(x, y)

%% test case 3 under map size 2

rank1 = [
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

elev = map_data.getPathElev(rank1(:,2));
