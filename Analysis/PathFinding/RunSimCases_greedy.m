%% Housekeeping
clc; close all; clear all;

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

%% Get solved test cases
soldir = '../../Data/SimResults/';
all_files = dir(testdir);
solve_files = {};
for i=1:length(all_files)
    fname = all_files(i).name;
    if isempty( regexp(fname, 'greedy') )
        continue;
    end
    solve_files = [solve_files; fname];
end


%% Loop through all test cases
for tidx=1:length(test_files)
    tfile = test_files{tidx};
    
    % have we run this one yet?
    already_done = false;
    for sidx=1:length(solve_files)
        sfile = solve_files{sidx};
        % get rid of the .mat
        match_str = tfile(1:(end-4));
        if ~isempty( regexp(sfile, match_str) ) 
            fprintf('Skipping file: %s\n', tfile);
            already_done = true;
        end
    end
    if already_done
        continue;
    end
    
    fprintf('Simulating file: %s\n', tfile);
    
    % solve this test case w/ greedy solver
    loaded = load([testdir tfile]);
    testcase = loaded.obj;
    
    % sensor data
    sensor_data = SensorDataSim(testcase.sim_elevations, ...
        testcase.sim_turns, testcase.sim_gps);
    % map data
    map_data = MapData(testcase.mapFilePath{1}, testcase.mapDataDownSampling);
    % solver
    solver = Solver_greedy(map_data, sensor_data);
    solver.setNumPathsToKeep(40);
    solver.useAbsoluteElevation();
    %solver.useTurns();
    
    % solve
    tic;
    solver.solve();
    solvetime = toc;
    [scores, paths] = solver.getResults();
    solver_results.time = solvetime;
    solver_results.scores = scores;
    solver_results.paths = paths;
    
    % save results
    outpath = strcat(soldir, tfile(1:(end-4)), '_greedy.mat');
    save(outpath, 'solver_results');
    
    
end















