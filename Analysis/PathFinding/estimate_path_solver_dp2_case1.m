%% NOTE of NOTE:
% This code has been replaced by estimate_path_solver_dp2to3_case1to3.m .
% The reason that I don't delete this file is there are some debug
% information inside for case 1.

%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration). 

%% Housekeeping
clear all; clc; close all;

%% Inputs:
% case 0:
%mapfile =    '../../Data/EleSegmentSets/ucla_west/';
%sensorfile = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';
%outputWebFile = '../../Data/resultSets/case1_ucla_west_results.rset';

% case 1:
mapfile =    '../../Data/EleSegmentSets/ucla_small/';
sensorfile = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';
outputWebFile = '../../Data/resultSets/case1_ucla_small_results.rset';
% also seaPressure, pressureScalar, range

%% Ensure library paths are added
add_paths;

%% Create SensorData object
sensor_data = SensorData(sensorfile);
% test-specific settings
sensor_data.setSeaPressure(1020);
sensor_data.setPressureScalar(-8.15);
sensor_data.setAbsoluteSegment(1418102835, 1418103643);

%% Create MapData object
map_data = MapData(mapfile);

%% test solver
tic
solver = Solver_v2(map_data, sensor_data);
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

%% tmp script for solver_v2 - explore the elevation difference between map nodes and both ends of barometer data
beginElev = solver.elevFromBaro(1,2);
endElev = solver.elevFromBaro(end,2);
closeToBegin = find( abs( beginElev - solver.map_data.getNodeIdxsElev(1:solver.map_data.num_nodes) ) <= 2 )
closeToEnd = find( abs( endElev - solver.map_data.getNodeIdxsElev(1:solver.map_data.num_nodes) ) <= 2 )

%% tmp script for solver_v2 - find the true solution
startEndLatLng = [ 34.06440998442042 -118.45083475112915    % for correct path
    34.06352119394332 -118.45004081726074
]
idxa = solver.map_data.getNearestNodeIdx(startEndLatLng(1,:))
idxb = solver.map_data.getNearestNodeIdx(startEndLatLng(2,:))
numSol = numel(solver.res_traces)
for i = 1:numSol
    rawData = solver.getRawPath(i);
    if rawData(1,2) == idxa && rawData(end,2) == idxb
        i
    end
end

%% tmp script explore the weight function
x = 0.1:0.1:10;
y1 = x .^ 2;
y2 = exp(x);
clf
hold on
plot(x, y1, 'r');
plot(x, y2, 'g');
plot(x, y1+y2, 'b');

%% tmp script for solver_v2 - it seems dtw is strange
startEndLatLng = [ 34.06440998442042 -118.45083475112915    % for correct path
    34.06352119394332 -118.45004081726074
];
idxa = solver.map_data.getNearestNodeIdx(startEndLatLng(1,:));
idxb = solver.map_data.getNearestNodeIdx(startEndLatLng(2,:));
rank = 31;
hele = solver.map_data.getSegElev( [247 250] );
tmp = all_pair_dtw_baro(hele, solver.elevFromBaro(118:161,1));