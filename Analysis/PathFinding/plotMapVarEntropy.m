% Housekeeping
clear all; clc; close all;
add_paths

% knobs
mapSize = 3;
entropySequenceSize = 1;
cfigure(14,8);

names = {};
entropies = [];
variances = [];

% go!
hold on
mapManager = MapManager('../../Data/EleSegmentSets/');
for i = 1:44
    try
        [mapData, mapPath] = mapManager.getMapDataObject(i, mapSize, 1);
        terms = strsplit(mapPath, '/');
        mapName = terms{end}(1:end-8);
        mapName(mapName == '_') = ' ';
        mapEntropy = calculateMapEntropy(mapData, 0.5, entropySequenceSize, 1);
        mapVariation = calculateMapVariation(mapData);
        plot(mapVariation, mapEntropy, 'ob','MarkerFaceColor','b')
        text(mapVariation+5, mapEntropy, mapName,'FontSize',12);
        xlabel('Elevation Variation','FontSize',12);
        ylabel('Elevation Entropy','FontSize',12);
        grid on;
        pause(0.1);
        names = [names;
            mapName];
        entropies = [entropies;
            mapEntropy];
        variances = [variances;
            mapVariation];
        
    catch err
    end
end

%% save
save('cache/mapVarEntropy', 'names', 'entropies', 'variances');

%% plot
load('cache/mapVarEntropy');

cfigure(14,10);

[~, idx] = sort(variances);
names = names(idx);
entropies = entropies(idx);
variances = variances(idx);

for i=1:size(names,1)
    
    mapName = names{i};
    mapEntropy = entropies(i);
    mapVariation = variances(i);
    
    semilogy(i,mapVariation, 'ob','MarkerFaceColor','b',...
        'MarkerSize',5)
    hold on;
    if mod(i,2) == 0
        text(i+2, 3e1 + 1.4^(i+5), mapName,'FontSize',10);
        plot([i+2, i], [3e1 + 1.4^(i+5), mapVariation], 'k-');
    else
        text(i+4, mapVariation, mapName,'FontSize',10);
        plot([i+4, i], [mapVariation mapVariation], 'k-');
    end
    xlabel('Map Index','FontSize',12);
    ylabel('Elevation Variation (m^2)','FontSize',12);
    grid off;
    
end

xlim([0 35]);
saveplot('figs/mapVar');


