%% Housekeeping
clc; close all; clear all;
add_paths

%SOLVER = 'dp3';
%SOLVER = 'dp4';
%SOLVER = 'dp5o';
SOLVER = 'dp5L';

if ~strcmp(SOLVER, 'dp3') && ~strcmp(SOLVER, 'dp4') && ~strcmp(SOLVER, 'dp5o') && ~strcmp(SOLVER, 'dp5L')
    error('Which solver are you choosing?')
end

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

%% Loop through all test cases

order = 1:length(test_files);
order = reshape(reshape(order, 10, [])', 1, []);
order = order(1:2:end);

for tidx = order
%for tidx = 270
    tfile = test_files{tidx};
    solfile = [tfile(1:(end-4)) '_' SOLVER '.mat'];
    solpath = [soldir solfile];
    
    if exist(solpath)
        fprintf('skip test caes %s\n', tfile);
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
    if strcmp(SOLVER, 'dp3')
        solver = Solver_dp3(map_data, sensor_data);
    elseif strcmp(SOLVER, 'dp4')
        solver = Solver_dp4(map_data, sensor_data, 0);
    elseif strcmp(SOLVER, 'dp5o')
        solver = Solver_dp5(map_data, sensor_data, 0);
        solver.setUncertaintyRange(0);
    elseif strcmp(SOLVER, 'dp5L')
        solver = Solver_dp5(map_data, sensor_data, 1);
    end
    
    outputWebFile = ['../../Data/resultSets/(B)[TEST_SIM]_' tfile(14:end-4) '_' SOLVER '.rset'];
    solver.setOutputFilePath(outputWebFile);

    tic
    solver.solve();
    totalTime = toc;
    fprintf('Elapsed time is %f seconds.\n', totalTime);

    fprintf('Generate results....');
    if solver.getNumResults() > 0
        solver.getRawPath(1)
        solver.plotPathComparison(1)
        pause(0.1)
        solver.toWeb();
    end
    
    % save results
    
    save(solpath, 'solver');
    fprintf('\n');
    
end

return

%% debug session (see the path gps elevation)
gps = sensor_data.getGps();
refinedGpsEle = map_data.rawGpsAlignment(gps(:,2:3));

clf
hold on
plot(testcase.sim_elevations_nonoise(:,1), testcase.sim_elevations_nonoise(:,2), 'b')
plot(gps(:,1), refinedGpsEle(:,3), 'r');

%% force to insert
solver.forceInsertingAPath(testcase.sim_path);  % failed??

%% plot elevation over map
pathElev = map_data.getPathElev(testcase.sim_path);
figure
plot(pathElev)

%%
baroElev = sensor_data.getElevationTimeWindow();
testcase.sim_speed
size(baroElev)
%size(testcase.sim_gps)
size(map_data.getPathElev(testcase.sim_path))





