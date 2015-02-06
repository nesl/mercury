%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration). 

%% Housekeeping
clear all; clc; close all;

%% Inputs:
% case 1:
mapfile =    '../../Data/EleSegmentSets/ucla_small/';
sensorfile = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';
outputWebFile = '../../Data/resultSets/case1_ucla_west_results.rset';
% also seaPressure, pressureScalar, range

%% Ensure library paths are added
add_paths;

%% Create SensorData object
sensor_data = SensorData(sensorfile);
% test-specific settings
sensor_data.setSeaPressure(1020);
sensor_data.setPressureScalar(-8.15);
sensor_data.setAbsoluteSegment(1418102835, 1418103643);

%% test deriv. of elevation
% e = sensor_data.getElevation();
% ef = sensor_data.getElevationFiltered();
% plot(ef(:,2) - mean(ef(:,2)));
% hold on;
% plot(e(:,2) - mean(e(:,2)), 'k');
% ed = gradient(ef(:,2), ef(:,1));
% plot(ed*30, 'r');
% plot([0 length(ed)], [0 0], 'k--');


%% Create MapData object
map_data = MapData(mapfile);

%% test map angles
osm_list = [
    122762254
    122568569
    566556466
    122762256
    122762258
    122579087
    1956573659
    122762229
    1717275967
    122762231
    122762234
    122762238
    122762242
    122762246
    122681077
    122681080
    122681083
];


nlist = map_data.getNodeIdxs(osm_list);
angles = map_data.getPathAngles(nlist);
turns = map_data.getPathTurns(nlist);

plot(angles - mean(angles));
hold on;
plot(turns,'r');

return;


%% Timing information
tic;

%% test solver
solver = Solver_greedy(map_data, sensor_data);

solver.setOutputFilePath(outputWebFile);
solver.solve();
solver.getRawPath(1)
solver.plotPathComparison(1)
solver.toWeb();
toc
return;


%% debug
detrace = sortedTraces(1).trace;
deele = [];
for i = 1:length(detrace)-1
    a = nodeName2ind(num2str(detrace(i,   1)));
    b = nodeName2ind(num2str(detrace(i+1, 1)));
    deele = [deele; eleTrajs{a, b}];
end

clf
hold on
plot(deele, 'r')
plot(height)

case1trajList = [
    343301146
    122624759
    123396586
    122584789
    496202094
    496202095
    122914625
    122914624
    122914622
    566568258
];

case2trajList = [
    122762254
    122568569
    566556466
    122762256
    122762258
    122579087
    1956573659
    122762229
    1717275967
    122762231
    122762234
    122762238
    122762242
    122762246
    122681077
    122681080
    122681083
];

deeleG = [];
for i = 1:length(case1trajList)-1
    a = nodeName2ind(num2str(case1trajList(i)));
    b = nodeName2ind(num2str(case1trajList(i+1)));
    deeleG = [deeleG; eleTrajs{a, b}];
end
plot(deeleG, 'g')

%% debug session 2
x = all_pair_dtw_baro(deeleG', height');
x(1,end)
