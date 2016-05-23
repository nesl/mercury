%% Housekeeping
clc; close all; clear all;
add_paths

%% settings
testdir = '../../Data/SimTestCasesMap/';
soldir =  '../../Data/SimResultsMap/';

%% Get test cases
all_files = dir(testdir);
test_files = {};
for i=1:length(all_files)
    fname = all_files(i).name;
    if isempty( regexp(fname, 'SIM') )
        continue;
    end
    test_files = [test_files; fname];
end

%% plotting

rankOfInterest = [1 3 5];
topNPathError = [];  % numel(rankOfInterest) by num_available_solution
topNShapeError = [];  % numel(rankOfInterest) by num_available_solution
topNBiShapeError = [];  % numel(rankOfInterest) by num_available_solution
pathLength = [];

for tidx=1:length(test_files)
    tfile = test_files{tidx};
    loaded = load([testdir tfile]);
    testcase = loaded.obj;
    
    pathLength(end+1) = size(testcase.sim_gps, 1);
    
    solfile = [tfile(1:(end-4)) '_dp5o.mat'];
    solpath = [soldir solfile];
    load(solpath, 'solver');
    fprintf([solpath '\n']);
    
    tmp = solver.summarizeResult('pathError',  'shapeError',  'biShapeError');
    numPaths = size(tmp, 1);
    for i = 1:length(rankOfInterest)
        rank = min(rankOfInterest(i), numPaths);
        topNPathError(i, tidx) = min(tmp(1:rank, 1));
        topNShapeError(i, tidx) = min(tmp(1:rank, 2));
        topNBiShapeError(i, tidx) = min(tmp(1:rank, 3));
    end
end


%% Plotting

%dirSaveFigure = 'figs/';
dirSaveFigure = '~/Dropbox/mercuryWriting/mobicom15/figs/';
%


colors = {'bs-', 'r^-', 'g*-', 'mo-', 'kv-'};
legendTexts = {'10 km^2', '23 km^2', '41 km^2', '64 km^2', '92 km^2'};
skip = 1;

lineOrder = 1:5;

%{
cfigure(14,6);

hold on
for i = lineOrder
    x = sort(topNShapeError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end
xlabel('Path Error (m)','FontSize',12);
ylabel('Probability','FontSize',12);
grid on;
xlim([0 1001]);
ylim([0 1.01]);
legend(legendTexts{lineOrder}, 'Location', 'SouthEast');
%saveplot([dirSaveFigure 'sim_dp_shape']);
%}

cfigure(14,6);
hold on
for i = lineOrder
    s = (i-1) * 20 + 1;
    e = i * 20;
    x = sort(topNBiShapeError(2,s:e));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end
xlabel('Path Error (m)','FontSize',14);
ylabel('Probability','FontSize',14);
grid on;
xlim([0 201]);
ylim([0 1.01]);
legend(legendTexts{lineOrder}, 'Location', 'SouthEast');
saveplot([dirSaveFigure 'sim_map_size_dp_bishape']);

%{
cfigure(14,6);
hold on
for i = lineOrder
    x = sort(topNPathError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end
xlabel('Timed Path Error (m)','FontSize',12);
ylabel('Probability','FontSize',12);
grid on;
xlim([0 1001]);
ylim([0 1.01]);
legend(legendTexts{lineOrder}, 'Location', 'SouthEast');
saveplot([dirSaveFigure 'sim_dp_path']);
%}
return

%% prelimilary plot
clf
hold on
plot(sort(topNBiShapeError(2,  1:20) ), '-b*');
plot(sort(topNBiShapeError(2, 21:40) ), '-r*');
plot(sort(topNBiShapeError(2, 41:60) ), '-g*');
plot(sort(topNBiShapeError(2, 61:80) ), '-m*');
plot(sort(topNBiShapeError(2, 81:100)), '-k*');



