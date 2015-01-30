%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration). 

%% Housekeeping
clear all; clc; close all;

%% Inputs:
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
allPairDTW = cell(nrNode);
for i = 1:nrNode
    for j = 1:nrNode
        if numel(eleTrajs{i, j}) > 0
            fprintf('calculate dtw of traj(%d, %d)\n', i, j);
            allPairDTW{i, j} = all_pair_dtw_baro(eleTrajs{i,j}(:,1), height);
        end
    end
end
fprintf('finish calculating all pairs of dtw\n');

%% dp
dp = ones(nrNode, nrB+1) * inf;  % dp(node, baro step)
dp(:,1) = 0;
from = zeros(nrNode, nrB+1, 2);  % from(a, b) = [last node, last step]
for i = 1:nrB
    for j = 1:nrNode
        for k = 1:numel(nextNodes{j})
            tn = nextNodes{j}(k);
            ind = find( dp(j, i) + allPairDTW{j, tn}(i, i:nrB) < dp(tn, (i+1):(nrB+1)) );
            % ind has the same range size as <i to nrB>
            % ind + i  map to range (i+1):(nrB+1), 
            dp(tn, i+ind) = dp(j, i) + allPairDTW{j, tn}(i, ind+i-1);
            from(tn, i+ind, :) = ones(numel(ind), 1) * [j i];
        end
    end
    fprintf('%d\n', i)
end

%%
% back tracking
traces = [];
clear p
for i = 1:nrNode
    if dp(i, nrB+1) ~= inf
        p.score = dp(i, nrB+1);
        nn = i;
        ns = nrB+1;
        p.trace = [ind2nodeName(i) nrB+1];
        %fprintf('%d %d\n', nn, ns);
        while ns ~= 1
            pn = from(nn, ns, 1);
            ps = from(nn, ns, 2);
            %fprintf('%d %d\n', pn, ps);
            nn = pn;
            ns = ps;
            p.trace = [[ind2nodeName(pn) ps]; p.trace];
        end
        traces = [traces p];
    end
end
   
sortedTraces = nestedSortStruct(traces, {'score'});

fprintf('computation time %.2f\n', toc);


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
