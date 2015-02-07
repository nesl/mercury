%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration). 

%% Housekeeping
clear all; clc; close all;

%% Ensure library paths are added
add_paths;

%% knot
caseNo = 2;

%% Inputs:


if caseNo == 2
    % sunset
    %    distance: 1.26 mile (2.02 km)
    %        time: 150 sec
    %   avg speed: 30mph / 48.5 km/h / 13.4 meter/sec
    mapfile =    '../../Data/EleSegmentSets/ucla_small/';
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
    outputWebFile = '../../Data/resultSets/case2_ucla_small_sunset_results.rset';
    % Create SensorData object
    sensor_data = SensorData(sensorfile);
    % test-specific settings
    sensor_data.setSeaPressure(1019.5);
    sensor_data.setPressureScalar(-7.97);
    sensor_data.setAbsoluteSegment(1421002543, 1421002693);
    sensor_data.setWindowSize(0.5);
elseif caseNo == 3
    % sunset + hilgard
    %    distance: 1.26+1.33 mile (2.02 km)
    %        time: 445 sec
    %   avg speed: ?mph / 48.5 km/h / 13.4 meter/sec
    mapfile =    '../../Data/EleSegmentSets/ucla_small/';
    sensorfile = '../../Data/rawData/baro_n503_20150111_091333.baro.csv';
    outputWebFile = '../../Data/resultSets/case3_ucla_small_sunset_hilgard_results.rset';
    % Create SensorData object
    sensor_data = SensorData(sensorfile);
    % test-specific settings
    sensor_data.setSeaPressure(1019.5);
    sensor_data.setPressureScalar(-7.97);
    sensor_data.setAbsoluteSegment(1421002543, 1421002988);
    sensor_data.setWindowSize(0.5);
else
    error('Kidding me? You didn''t choose a correct test case!');
end

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

%% tmp script for solver_v2 - it seems dtw is strange
startEndLatLng = [ 34.06440998442042 -118.45083475112915    % for correct path
    34.06352119394332 -118.45004081726074
];
idxa = solver.map_data.getNearestNodeIdx(startEndLatLng(1,:));
idxb = solver.map_data.getNearestNodeIdx(startEndLatLng(2,:));
rank = 31;
hele = solver.map_data.getSegElev( [247 250] );
tmp = all_pair_dtw_baro(hele, solver.elevFromBaro(118:161,1));