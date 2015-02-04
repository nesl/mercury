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

%% Timing information
tic;


%% all pair DTW
%elevFromBaro = sensor_data.getElevationTimeWindow();
%map_data.preProcessAllPairDTW(elevFromBaro(:,2));
%fprintf('finish calculating all pairs of dtw\n');

%% dp
%{
numMapNodes = map_data.getNumNodes();
numElevBaro = size(elevFromBaro, 1);
dp = ones(numMapNodes, numElevBaro+1) * inf;  % dp(node idx, elev step)
dp(:,1) = 0;
from = zeros(numMapNodes, numElevBaro+1, 2);  % from(a, b) = [last node, last step]
for i = 1:numElevBaro
    for j = 1:numMapNodes
        neighbors = map_data.getNeighbors(j);
        for k = 1:numel(neighbors)
            nn = neighbors(k);  % neighbor node
            dtwArr = map_data.queryAllPairDTW(j, nn, i);  % all pair DTW from (i,i) to (i,end)
            ind = find( dp(j, i) + dtwArr < dp(nn, (i+1):end) );
            % ind spans the same range as <i to numElevBaro>
            % (ind + i) maps to range (i+1):(numElevBaro+1), 
            dp(nn, i+ind) = dp(j, i) + dtwArr(ind);
            from(nn, i+ind, :) = repmat([j i], length(ind), 1);
        end
    end
    fprintf('%d\n', i)
end
%}

%%
% back tracking
%{
traces = [];
clear p
for i = 1:numMapNodes
    if dp(i, numElevBaro+1) ~= inf
        p.score = dp(i, numElevBaro+1);
        nn = i;
        ns = numElevBaro+1;
        %p.trace = [ind2nodeName(i) nrB+1];
        p.trace = [i numElevBaro+1];
        %fprintf('%d %d\n', nn, ns);
        while ns ~= 1
            pn = from(nn, ns, 1);
            ps = from(nn, ns, 2);
            %fprintf('%d %d\n', pn, ps);
            nn = pn;
            ns = ps;
            p.trace = [ [pn ps] ; p.trace];
        end
        traces = [traces p];
    end
end
   
sortedTraces = nestedSortStruct(traces, {'score'});

fprintf('computation time %.2f\n', toc);
%}

%% test solver
tic
solver = Solver_v1(map_data, sensor_data);
solver.solve();
solver.getRawPath(1)
solver.plotPathComparison(1)
toc
return;

%% Output settings
% (eventually will be removed and placed in calling script)
% output files
MAX_RESULTS = 20;
OUTPATH = '../../Data/resultSets/';
OUTFILENAME = 'case1_ucla_west_results.rset';


%% Generate result output
fid = fopen([OUTPATH OUTFILENAME], 'w');

for i=1:min( MAX_RESULTS, length(sortedTraces) )
    score = sortedTraces(i).score;
    t = sortedTraces(i).trace(:,1);
    fprintf(fid, '%.1f,', score);
    for j=1:length(t)
        fprintf(fid, '%d', t(j));
        if j ~= length(t)
            fprintf(fid, ',');
        end
    end
    fprintf(fid,'\n');
end

return

%% convert trace back to geography trace
% CONSIDER: wrapped as a function (has difficulity as parameter import) or
% the class method

TRACE_NO = 1;
nodeSeries = sortedTraces(TRACE_NO).trace;
latLngs = [];
for i = 1:length(nodeSeries)-1
    a = nodeName2ind(num2str(nodeSeries(i   , 1)));
    b = nodeName2ind(num2str(nodeSeries(i+1 , 1)));
    eleTraj = eleTrajs{a, b};
    
    a = nodeSeries(i  , 2);
    b = nodeSeries(i+1, 2) - 1;
    baroHeightTraj = height(a:b);
    
    eleInds = dtw_find_path(eleTraj(:,1), baroHeightTraj);
    latLngs = [latLngs ; eleTraj(eleInds, 2:3)];
end

numLatLngs = length(latLngs);
estimatedTraj = [ ((1:numLatLngs) * WINDOW)' latLngs ];
groundTruthTraj = gpsRaw(:,1:3);
groundTruthTraj(:,1) = groundTruthTraj(:,1) - gpsRaw(1,1);  % make time offset of first gps record as 0
gpsSeriesCompare(groundTruthTraj, estimatedTraj)

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
