baroFile = '../../../Data/BaroTrajTestCases/case1_surround_weyburn/case1_baro_query.csv';
dataq = csvread(baroFile);

% plot(dataq(:,1), dataq(:,2) is the first figure

seaPre = 1020.394;
sca = -7.9736;
height = dataq;
height(:,2) = (dataq(:,2) - seaPre) * sca;

% plot(height) is the second figure


all=[
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

segInd = [1 4 7 9 10];

eleTrajDir = '../../../Data/EleSegmentSets/ucla_west/';

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

clf
hold on
xind = ones(1, 10);
ele = [];
for i = 1:9
    a = num2str(all(i  ));
    b = num2str(all(i+1));
    numElev = length(eleTrajs{nodeName2ind(a), nodeName2ind(b)}) / 3;
    elevs = eleTrajs{nodeName2ind(a), nodeName2ind(b)}(2:numElev)
    eleTrajs{nodeName2ind(a), nodeName2ind(b)}
    ele = [ele eleTrajs{nodeName2ind(a), nodeName2ind(b)}(2:numElev)];
    xind(i+1) = length(ele);
    pause
end

hue = [0, 0.3, 0.8, 0.15];
for j = 1:4
    ind = xind(segInd(j)):(xind(segInd(j+1)));
    plot(ind*1.8, ele(ind), 'Color', hsv2rgb([hue(j), 1, 0.5]), 'LineWidth', 2)
end

ylim([90 130])
plot(xind(segInd(:))*1.8, ele(xind(segInd(:))), 'k+', 'MarkerSize', 6)

hind = [0 150 480 660 900];
pflag = 1;
for j = 1:4
    ind = (hind(j) <= height(:,1) & height(:,1) <= hind(j+1));
    s1 = height(ind,2);
    ind = xind(segInd(j)):(xind(segInd(j+1)));
    s2 = ele(ind);
    dtw(s1,s2,pflag,hsv2rgb([hue(j), 1, 0.5]));
end