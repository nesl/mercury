%% Housekeeping
clc; close all; clear all;
add_paths

%% settings
testdir = '../../Data/SimTestCases/';
soldir = '../../Data/SimResults/';

%% knobs

%SOLVER = 'dp5o';
SOLVER = 'dp5L';

if ~strcmp(SOLVER, 'dp5o') && ~strcmp(SOLVER, 'dp5L')
    error('Which solver are you choosing?')
end

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

load('../../Data/tmpMatFiles/simPathKLVar.mat', 'resultEV');


rankOfInterest = [1 3 10];
topNPathError = [];  % numel(rankOfInterest) by num_available_solution
topNShapeError = [];  % numel(rankOfInterest) by num_available_solution
topNBiShapeError = [];  % numel(rankOfInterest) by num_available_solution

pathVSshapeError = [];

atidx = 0;
for tidx=1:length(test_files)
%for tidx=538
    tfile = test_files{tidx};
    outputWebFile = ['../../Data/resultSets/(B)[TEST_SIM]_' tfile(14:end-4) '_' SOLVER '.rset'];
    
    if ~exist(outputWebFile)
        continue;
    end
    
    atidx = atidx + 1;
    
    fprintf([outputWebFile '\n']);
    
    fid = fopen(outputWebFile);
    for i = 1:8
        tline = fgets(fid);
    end
    
    tline = fgets(fid)
    numPaths = str2num( tline(1:end-1) );
    pathError = zeros(numPaths, 1);
    shapeError = zeros(numPaths, 1);
    biShapeError = zeros(numPaths, 1);
    
    for i = 1:numPaths
    	tline = fgets(fid);
        tline = tline(1:end-1);
        terms = strsplit(tline, ',');
        pathError(i) = str2num(terms{1});
        shapeError(i) = str2num(terms{2});
        biShapeError(i) = str2num(terms{3});
    end
    fclose(fid);
    
    for i = 1:length(rankOfInterest)
        rank = min(rankOfInterest(i), numPaths);
        topNPathError(i, atidx) = min(pathError(1:rank));
        topNShapeError(i, atidx) = min(shapeError(1:rank));
        topNBiShapeError(i, atidx) = min(biShapeError(1:rank));
    end
    
    pathVSshapeError = [pathVSshapeError; [pathError biShapeError]];
end

%

clf

subplot(2, 2, 1);
hold on
for i = 1:length(rankOfInterest)
    x = sort(topNShapeError(i,:));
    y = linspace(0, 1, length(x));
    plot(x, y, 'Color', hsv2rgb([ i/length(rankOfInterest) 1 0.9 ]));
end
xlabel('shape error');

subplot(2, 2, 2);
hold on
for i = 1:length(rankOfInterest)
    x = sort(topNBiShapeError(i,:));
    y = linspace(0, 1, length(x));
    plot(x, y, 'Color', hsv2rgb([ i/length(rankOfInterest) 1 0.9 ]));
end
xlabel('bi-shape error');

subplot(2, 2, 3);
hold on
for i = 1:length(rankOfInterest)
    x = sort(topNPathError(i,:));
    y = linspace(0, 1, length(x));
    plot(x, y, 'Color', hsv2rgb([ i/length(rankOfInterest) 1 0.9 ]));
end
xlabel('path error');

subplot(2, 2, 4);
plot(pathVSshapeError(:,1), pathVSshapeError(:,2), '.');
xlabel('path error');
ylabel('shape error');



return

%% what are the standard deviation?

stdAll = zeros( length(test_files), 1 );

clf
for tidx=1:length(test_files)
    tfile = test_files{tidx};
    loaded = load([testdir tfile]);
    testcase = loaded.obj;
    stdAll(tidx) = std( testcase.sim_elevations(:,2) );
end

%plot(1:length(test_files), stdAll);  % according to city index
sortedStdAll = sort(stdAll);
plot(1:length(test_files), sortedStdAll)  % according to cdf

%% what are the current test case statistics?


clf
hold on

numCasePerCity = 10;
symbols = 'so^*+x>';

for tidx=1:length(test_files)
    if mod(tidx, numCasePerCity) == 1
        color = rand(1, 3) * 0.8;
        symbol = symbols(ceil( numel(symbols) * rand() ));
    end
    tfile = test_files{tidx};
    loaded = load([testdir tfile]);
    testcase = loaded.obj;
    plot( std( testcase.sim_elevations(:,2) ) ,  size(testcase.sim_turns, 1), symbol, 'Color', color )
end
xlabel('std')
ylabel('num of turns')


%% variance v.s. processing time?

clf
hold on

numCasePerCity = 10;
symbols = 'so^*+x>';

for tidx=1:length(test_files)
%for tidx = 1:1
    if mod(tidx, numCasePerCity) == 1
        color = hsv2rgb( [rand(), rand() * 0.5 + 0.5, rand() * 0.1 + 0.9] );
        symbol = symbols(ceil( numel(symbols) * rand() ));
    end
    
    tfile = test_files{tidx};
    
    solfile = [tfile(1:(end-4)) '_' SOLVER '.mat'];
    solpath = [soldir solfile];
    
    if ~exist(solpath)
        continue;
    end
    
    fprintf('Retrieve solver: %s\n', solpath);
    load(solpath, 'solver');
    
    loaded = load([testdir tfile]);
    testcase = loaded.obj;
    plot( std( testcase.sim_elevations(:,2) ) , solver.getProcessingTime() , symbol, 'Color', color )
end
xlabel('std')
ylabel('num of turns')

%% relation between relative entropy/variation -> difficulty?

load('../../Data/tmpMatFiles/simPathKLVar.mat', 'resultEV');

rankOfInterest = 3;

errorSP = nan(length(test_files), 2);

atidx = 0;
for tidx=1:length(test_files)
%for tidx=538
    tfile = test_files{tidx};
    outputWebFile = ['../../Data/resultSets/(B)[TEST_SIM]_' tfile(14:end-4) '_' SOLVER '.rset'];
    
    if ~exist(outputWebFile)
        continue;
    end
    
    atidx = atidx + 1;
    
    fprintf([outputWebFile '\n']);
    
    fid = fopen(outputWebFile);
    for i = 1:8
        tline = fgets(fid);
    end
    
    tline = fgets(fid);
    numPaths = str2num( tline(1:end-1) );
    pathError = zeros(numPaths, 1);
    biShapeError = zeros(numPaths, 1);
    
    for i = 1:numPaths
    	tline = fgets(fid);
        tline = tline(1:end-1);
        terms = strsplit(tline, ',');
        pathError(i) = str2num(terms{1});
        biShapeError(i) = str2num(terms{3});
    end
    fclose(fid);
    
    for i = 1:length(rankOfInterest)
        rank = min(rankOfInterest(i), numPaths);
        errorSP(tidx, 1) = min(biShapeError(1:rank));
        errorSP(tidx, 2) = min(pathError(1:rank));
    end
end

%

clf

availableIdx = ~isnan( errorSP(:, 1) );

ytext = {'3rd shape error', '3rd path error'};
xtext = {'path variance', 'kl', 'map entropy', 'map variance'};
%%
for i = 1:8
    subplot(2, 4, i)
    r = ceil(i / 4);
    c = i - 4 * (r-1);
    plot(resultEV(availableIdx,c), errorSP(availableIdx,r), '+');
end

%%
clf
hold on
for i = find(availableIdx)'
    i
    plot([resultEV(i,1) resultEV(i,4)], [errorSP(i,1) errorSP(i,1)], '-')
    pause
end


%% patch: add biShape to rset

%{
all fixed
for tidx=1:length(test_files)
    tfile = test_files{tidx};
    
    outputWebFile = ['../../Data/resultSets/(B)[TEST_SIM]_' tfile(14:end-4) '_' SOLVER '.rset'];
    
    solfile = [tfile(1:(end-4)), '_' SOLVER '.mat'];
    solpath = [soldir solfile];
    
    fprintf('\n');
    
    if ~exist(solpath) || ~exist(outputWebFile)
        continue;
    end
    
    fprintf('Retrieve solver: %s\n', solpath);
    load(solpath, 'solver');
    
    fprintf(['Modify result ' outputWebFile '\n']);
    
    modifiedContent = {};
    fid = fopen(outputWebFile);

    modifiedContent{end+1} = fgets(fid);
    fgets(fid);
    modifiedContent{end+1} = ['6' char(10)];
    for i = 2:3
        modifiedContent{end+1} = fgets(fid);
    end
    modifiedContent{end+1} = ['Bi shape error' char(10)];
    for i = 4:6
        modifiedContent{end+1} = fgets(fid);
    end

    tline = fgets(fid);
    numPaths = str2num( tline(1:end-1) );
    pathError = zeros(numPaths, 1);
    shapeError = zeros(numPaths, 1);

    modifiedContent{end+1} = tline;

    groundTruthTimeLatLngs = solver.sensor_data.getGps();
    groundTruthLatLngs = groundTruthTimeLatLngs(:, 2:3);
    for i = 1:numPaths
    	tline = fgets(fid);
        commaIdxs = find(tline == ',');
        insertIdx = commaIdxs(2) + 1;
        scoreGndEsti = gps_series_compare(groundTruthLatLngs, solver.final_res_traces(i).latlng);
        scoreEstiGnd = gps_series_compare(solver.final_res_traces(i).latlng, groundTruthLatLngs);
        finalScore = rms([scoreGndEsti scoreEstiGnd]);
        modifiedContent{end+1} = [ tline(1:(insertIdx-1)) num2str(finalScore) ',' tline(insertIdx:end) ];
    end
    fclose(fid);
    
    outputWebFile = ['../../Data/resultSets/(B)[TEST_SIM]_' tfile(14:end-4) '_' SOLVER '.rset'];
    fid = fopen(outputWebFile, 'w');
    for i = 1:numel(modifiedContent)
        fprintf(fid, '%s', modifiedContent{i});
    end
    fclose(fid);
end
%}