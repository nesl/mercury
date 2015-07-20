%% Housekeeping
clc; close all; clear all;
add_paths

%SOLVER = 'greedyA';
%SOLVER = 'greedyAT';
%SOLVER = 'greedyR';
%SOLVER = 'greedyRT';
SOLVER = 'greedyOnline';

%if ~strcmp(SOLVER, 'greedyA') && ~strcmp(SOLVER, 'greedyAT') && ~strcmp(SOLVER, 'greedyR') && ~strcmp(SOLVER, 'greedyRT')
%    error('Which solver are you choosing?')
%end

%% Get test cases
testdir = '../../Data/SimTestCases/';
all_files = dir(testdir);
test_files = {};
for i=1:length(all_files)
    fname = all_files(i).name;
    if isempty( regexp(fname, 'SIM_ucla') )
        continue;
    end
    test_files = [test_files; fname];
end

%% Get solved test cases
soldir = '../../Data/SimResults/';

%% Loop through all test cases

order = 1:length(test_files);
order = reshape(reshape(order, 10, [])', 1, []);
order = order(10:10:end);


for tidx=1:length(test_files)
%for tidx = 500;
    tfile = test_files{tidx};
    
    solfile = [tfile(1:(end-4)), '_' SOLVER '.mat'];
    solpath = [soldir solfile];
    
    if exist(solfile)
        fprintf('skipping test case %s\n', tfile);
        continue;
    end
    
    fprintf('Simulating file: %s\n', tfile);
    
    % solve this test case w/ online solver
    loaded = load([testdir tfile]);
    testcase = loaded.obj;
        
    % sensor data
    sensor_data = SensorDataSim(testcase.sim_elevations, ...
        testcase.sim_turns, testcase.sim_gps);
    % map data
    map_data = MapData(testcase.mapFilePath{1}, testcase.mapDataDownSampling);
    
    % ground truth data
    gt_path = testcase.sim_path;
    gt_t = testcase.stopAbsTime - testcase.startAbsTime;
    
    % solver
    solver = Solver_online(map_data, sensor_data, gt_path, gt_t);
    solver.setNumPathsToKeep(40);
    
    % solve
    tic;
    solver.solve();
    solvetime = toc;
    [scores, paths] = solver.getResults();
    solver_results.time = solvetime;
    solver_results.scores = scores;
    solver_results.paths = paths;
    
    % save results
    save(solpath, 'solver_results');
    
end















