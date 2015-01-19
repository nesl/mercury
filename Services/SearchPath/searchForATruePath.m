% input files
eleTrajDir = '../../Data/eleSegments/ucla_small/';
baroFile = '../../Data/eleSegments/test_case/case2_baro_query.csv';

% output files
MAX_RESULTS = 20;
outPath = '../../Data/resultSets/';
outFileName = 'case2_ucla_small_hilgard_results.rset';

tic

% load all the segments
fileProfile = dir(eleTrajDir);
fileProfile = fileProfile(3:end);
endNodePairs = [];
nrNode = 0;
nodeName2ind = containers.Map;
ind2nodeName = [];

for i = 1:size(fileProfile)
    f = fileProfile(i).name;
    n = find(f == '_');
    p.na = f(1:(n-1));
    p.nb = f((n+1):end);
    endNodePairs = [endNodePairs p];
    if ~isKey(nodeName2ind, p.na)
        nrNode = nrNode + 1;
        nodeName2ind(p.na) = nrNode;
        ind2nodeName = [ind2nodeName str2num(p.na)];
    end
    if ~isKey(nodeName2ind, p.nb)
        nrNode = nrNode + 1;
        nodeName2ind(p.nb) = nrNode;
        ind2nodeName = [ind2nodeName str2num(p.nb)];
    end
end

eleTrajs = cell(nrNode);
nextNodes = cell(nrNode, 1);
for i = 1:numel(endNodePairs)
    nna = nodeName2ind( endNodePairs(i).na );
    nnb = nodeName2ind( endNodePairs(i).nb );
    eleTrajs{nna, nnb} = csvread([eleTrajDir fileProfile(i).name]);
    eleTrajs{nna, nnb} = eleTrajs{nna, nnb}(1:2:numel(eleTrajs{nna, nnb}));
    eleTrajs{nnb, nna} = flipud(eleTrajs{nna, nnb});
    nextNodes{nna} = [nextNodes{nna} nnb];
    nextNodes{nnb} = [nextNodes{nnb} nna];
end
fprintf('finish reading all the trajectories, %d nodes, %d segments\n', nrNode, numel(endNodePairs))

% segment barometer trajectory into window
dataq = csvread(baroFile);
WINDOW = 5; % sec
nrB = floor((dataq(end,1) - dataq(1,1)) / WINDOW);
baros = zeros(nrB, 1);
baroc = zeros(nrB, 1);
for i = 1:size(dataq,1)
    ind = floor((dataq(i,1) - dataq(1,1)) / WINDOW) + 1;
    if 1 <= ind && ind <= nrB
        baros(ind) = baros(ind) + dataq(i,2);
        baroc(ind) = baroc(ind) + 1;
    end
end
baros = baros ./ baroc;
baros = baros(setdiff(1:nrB, find(isnan(baros))));
nrB = length(baros);   % since some invalid windows are taken out thus total # of windows changes

seaPre = 1019.394;
sca = -7.9736;
height = (baros - seaPre) * sca;

% all pair DTW
allPairDTW = cell(nrNode);
for i = 1:nrNode
    for j = 1:nrNode
        if numel(eleTrajs{i, j}) > 0
            fprintf('calculate dtw of traj(%d, %d)\n', i, j);
            allPairDTW{i, j} = all_pair_dtw_baro(eleTrajs{i,j}', height');
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

%% Generate result output
fid = fopen([outPath outFileName], 'w');
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

%% debug
detrace = sortedTraces(1).trace;
deele = [];
for i = 1:length(detrace)-1
    a = nodeName2ind(num2str(detrace(i)));
    b = nodeName2ind(num2str(detrace(i+1)));
    deele = [deele; eleTrajs{a, b}];
end

clf
hold on
plot(deele, 'r')
plot(height)

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
for i = 1:length(case2trajList)-1
    a = nodeName2ind(num2str(case2trajList(i)));
    b = nodeName2ind(num2str(case2trajList(i+1)));
    deeleG = [deeleG; eleTrajs{a, b}];
end
plot(deeleG, 'g')

%% debug session 2
x = all_pair_dtw_baro(deeleG', height');
x(1,end)