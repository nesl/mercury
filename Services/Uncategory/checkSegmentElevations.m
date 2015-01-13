dir = '../../Data/eleSegments/ucla_west/';

nodeSets = {};
outputNames = {};

% case 1 ground
nodeSets{end+1} = [
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
outputNames{end+1} = 'case1_ac.csv';

nodeSets{end+1} = [
122584740
122584748
122584755
122584764
122584789
496202094
496202095
122914625
122914624
122914622
566568258
];
outputNames{end+1} = 'case1_aw1.csv';

nodeSets{end+1} = [
122584789
123396586
122624759
343301146
123206570
123206567
123113758
122624739
123113760
122584755
122584748
122584740
];
outputNames{end+1} = 'case1_aw2.csv';

nodeSets{end+1} = [
123113760
122624739
123113758
123206567
123206570
343301146
122624759
123396586
122584789
496202094
496202095
122914625
122914624
122914622
1717288137
122914616
122914612
122978977
];
outputNames{end+1} = 'case1_aw3.csv';

nodeSets{end+1} = [
123396564
123206570
123206567
122624749
122624739
123113760
122584755
122584764
122584789
123396586
122624759
343301146
566568258
122914622
122914624
122914625
496202095
];
outputNames{end+1} = 'case1_aw4.csv';

for j = 1:numel(nodeSets)
    datat = [];
    p = nodeSets{j};
    for i = 1:(size(p,1)-1)
        if p(i) < p(i+1)
            name = [ int2str(p(i)) '_' int2str(p(i+1)) ];
        else
            name = [ int2str(p(i+1)) '_' int2str(p(i)) ];
        end
        data = csvread([dir name]);
        if p(i) > p(i+1)
            data = flipud(data);
        end

        %subplot(5, 1, i)
        %plot(data)
        datat = [datat; data];
    end
    %subplot(5, 1, 4)
    %plot(datat)

    dlmwrite(['../../Data/eleSegments/test_case/' outputNames{j}], datat, 'delimiter', ',', 'precision', 9);
end