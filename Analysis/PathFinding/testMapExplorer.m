%% NOTE:
% This will eventually be converted into a function, but for debugging
% I'll keep it as a script for now. Inputs will be map file, sensor file,
% and sensor segmentation (start and duration).

%% Housekeeping
clear all; clc; close all;

%% Inputs:
% case 1:
mapfile =    '../../Data/EleSegmentSets/ucla_small/';
sensorfile = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';
outputWebFile = '../../Data/resultSets/case1_ucla_west_results.rset';
% also seaPressure, pressureScalar, range

%% Ensure library paths are added
add_paths;

%% Create SensorData object
sensor_data = SensorData(sensorfile);
% test-specific settings
sensor_data.setSeaPressure(1020);
sensor_data.setPressureScalar(-8.15);
sensor_data.setAbsoluteSegment(1418102835, 1418103643);

%% Create MapData object
map_data = MapData(mapfile);
map_lines = map_data.getAllSegLatLng();

% correct path indices
%     1    72
%     15    70
%     27    49
%     37    46
%     56    50
%     67   254
%     78   251
%     88   248
%    118   247
%    162   250

%% Create a single map explorer
e_good = GraphExplorer(map_data, sensor_data, 72, 0.5);
e_bad  = GraphExplorer(map_data, sensor_data, 290, 0.5);

%% Explore and plot
close all;
figure();
pause(0.1);

for i=1:100
    fprintf('Iteration: %d\n', i);
    
    
    % explore
    e_good.exploreNewNodes();
    %e_bad.exploreNewNodes();
    % prune
    e_good.pruneUntilMaxPaths();

    %e_bad.pruneUntilMaxPaths();
    
    hold off;
    for l=1:length(map_lines)
        line = map_lines{l};
        plot(line(:,2), line(:,1), 'Color',[0.8 0.8 0.8]);
        hold on;
    end
    
    [paths,scores,latlngs,leaves] = e_good.getAllPaths();
    % plot paths
    for p=1:length(latlngs)
        path = latlngs{p};
        score = scores(p);
        if score == min(scores)
            color = 'm';
            width = 2;
        else
            color = 'b';
            width = 1;
        end
        plot(path(:,2), path(:,1), color, 'LineWidth',width);
        text(path(end,2), path(end,1), num2str(score));
    end
    % plot leaves
    for l=1:length(leaves)
        latlng = map_data.getNodeIdxLatLng(leaves(l));
        plot(latlng(2), latlng(1), 'sr', 'MarkerFaceColor','g', 'LineWidth',2);
    end
    
    %best cost score
    fprintf('good = %.2f, bad = %.2f\n', e_good.cost, e_bad.cost);
    pause(0.1);
    
        
    clear plot
    hold off;
end

return;
    


%%
true = [
    72
    70
    49
    46
    50
    254
    251
    248
    247
    250];

wrong = [
    72
    305
    306
    307
    310
    63
    308
    ];

gt = sensor_data.getElevationTimeWindow();
ele_true = map_data.getPathElev(true);
ele_wrong = map_data.getPathElev(wrong);
test = 124*ones(1,100);
plot(ele_true);
hold on;
plot(ele_wrong,'r');
plot(gt(:,2),'k');

%% 
grdy_true = [];
grdy_wrong = [];

for L=1:5:length(ele_true)
    partial = ele_true(1:L);
    cost = DTW_greedy(gt(:,2), partial);
    grdy_true = [grdy_true; cost];
end


for L=1:5:length(ele_wrong)
    partial = ele_wrong(1:L);
    cost = DTW_greedy(gt(:,2), partial);
    grdy_wrong = [grdy_wrong; cost];
end


plot(grdy_true);
hold on;
plot(grdy_wrong,'r');
















