%% Get test cases
testdir = '../../Data/SimTestCases/';
all_files = dir(testdir);
test_files = {};
for i=1:length(all_files)
    fname = all_files(i).name;
    if isempty( regexp(fname, 'SIM') )
        continue;
    end
    test_files = [test_files; fname];
end

%% choose a lucky case as ground truth and compare with all the other ones
luckyIdx = 3;

elev_from_seg = cell(numel(test_files), 1);

for tidx = 1:length(test_files)
    tfile = test_files{tidx};
    
    % solve this test case w/ greedy solver
    loaded = load([testdir tfile]);
    testcase = loaded.obj;
    
    % map data
    map_data = MapData(testcase.mapFilePath{1}, testcase.mapDataDownSampling);
    elev_from_seg{tidx} = map_data.getPathElev( testcase.sim_path );
    
    fprintf('%d is done\n', tidx);
end