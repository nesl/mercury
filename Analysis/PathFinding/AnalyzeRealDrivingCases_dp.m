%% Housekeeping
clc; close all; clear all;
add_paths


caseNames = {
'[Bo-Driving]_1-1_size4'
'[Bo-Driving]_1-2_size4'
'[Bo-Driving]_1-3_size4'
'[Bo-Driving]_1-4_size4'
'[Bo-Driving]_1-5_size4'
'[Bo-Driving]_1-6_size4'
'[Bo-Driving]_2-1_size4'
'[Bo-Driving]_2-2_size4'
'[Bo-Driving]_3-1_size4'
'[Bo-Driving]_3-2_size4'
'[Bo-Driving]_3-3_size4'
'[Bo-Driving]_3-4_size4'
'[Bo-Driving]_3-5_size4'
'[Bo-Driving]_3-6_size4'
'[Bo-Driving]_3-7_size4'
'[Bo-Driving]_3-8_size4'
'[Bo-Driving]_5-1_size4'
'[Bo-Driving]_5-2_size4'
'[Bo-Driving]_5-3_size4'
'[Bo-Driving]_6-1_size4'
'[Bo-Driving]_6-2_size4'
'[Bo-Driving]_7-1_size4'
'[Bo-Driving]_7-2_size4'
'[Bo-Driving]_7-3_size4'
'[Bo-Driving]_7-4_size4'
'[Bo-Driving]_7-5_size4'
'[Bo-Driving]_7-6_size4'
'[Bo-Driving]_7-7_size4'
'[Bo-Driving]_7-8_size4'
};

%% load for plotting

load ../../Data/tmpMatFiles/randomGuess/randomGuess6x6.mat
randomTopNPathError = topNPathError;  % numel(rankOfInterest) by num_available_solution
randomTopNShapeError = topNShapeError;  % numel(rankOfInterest) by num_available_solution
randomTopNBiShapeError = topNBiShapeError;  % numel(rankOfInterest) by num_available_solution

totalTime = [];
topNPathError = [];
topNShapeError = [];
topNBiShapeError = [];
rankOfInterest = [1 3 5];
for i = 2:size(caseNames, 1)
    solver = solutionResolver_dp4(caseNames{i});
    totalTime = [totalTime solver.getProcessingTime()];
    tmp = solver.summarizeResult('pathError',  'shapeError',  'biShapeError');
    topNPathError(end+1, 1) = 0;
    topNShapeError(end+1, 1) = 0;
    topNBiShapeError(end+1, 1) = 0;
    for j = 1:numel(rankOfInterest)
        rank = min(rankOfInterest(j), size(tmp, 1));
        topNPathError(end, j) = min( tmp(1:rank, 1) );
        topNShapeError(end, j) = min( tmp(1:rank, 2) );
        topNBiShapeError(end, j) = min( tmp(1:rank, 3) );
    end
    fprintf('finish case %d\n', i);
end


fprintf('avg solving time = %f +/- %f sec\n', mean(totalTime), std(totalTime));

return;

topNPathError = topNPathError';
topNShapeError = topNShapeError';
topNBiShapeError = topNBiShapeError';

%% merge
idx = floor(linspace(1, size(randomTopNShapeError, 2) + 0.5, size(topNBiShapeError, 2)));
topNPathError(4,:) = randomTopNPathError(3,idx);
topNShapeError(4,:) = randomTopNShapeError(3,idx);
topNBiShapeError(4,:) = randomTopNBiShapeError(3,idx);

%% Plotting

%dirSaveFigure = 'figs/';
dirSaveFigure = '~/Dropbox/mercuryWriting/mobicom15/figs/';
%
cfigure(14,6);

clf

colors = {'bs-', 'r^-', 'm*-', 'ko-'};
legendTexts = {'1 paths', '3 paths', '5 paths', 'Random'};
skip = 2;

lineOrder = [3 2 1 4];

%orderedLegendTexts = legendTexts{lineOrder};

%subplot(1, 3, 1);
hold on
for i = lineOrder
    x = sort(topNPathError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end
xlabel('Timed Path Error (m)','FontSize',12);
ylabel('Probability','FontSize',12);
grid on;
xlim([0 2000])
legend(legendTexts{lineOrder}, 'Location', 'SouthEast');
saveplot([dirSaveFigure 'real_driving_dp_path']);


%{
cfigure(14,6);

hold on
for i = lineOrder
    x = sort(topNShapeError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end

xlabel('Path Error (m)', 'FontSize',12);
ylabel('Probability', 'FontSize',12);
grid on;
xlim([0 2000])
legend(legendTexts{lineOrder}, 'Location', 'SouthEast');
saveplot([dirSaveFigure 'real_driving_dp_shape']);
%}

% bi-shape

cfigure(14,6);

hold on
for i = lineOrder
    x = sort(topNBiShapeError(i,:));
    y = linspace(0, 1, length(x));
    plot(x(1:skip:end), y(1:skip:end), colors{i}, 'LineWidth',2);
end

xlabel('Path Error (m)', 'FontSize',14);
ylabel('Probability', 'FontSize',14);
grid on;
xlim([0 2000])
legend(legendTexts{lineOrder}, 'Location', 'SouthEast');
saveplot([dirSaveFigure 'real_driving_dp_bishape']);

