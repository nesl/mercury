% Housekeeping
clear all; clc; close all;
add_paths

% knobs
mapSize = 3;
entropySequenceSize = 16;

% go!
hold on
mapManager = MapManager();
for i = 1:44
    try
        [mapData, mapPath] = mapManager.getMapDataObject(i, mapSize, 1);
        terms = strsplit(mapPath, '/');
        mapName = terms{end}(1:end-8);
        mapName(mapName == '_') = ' ';
        mapEntropy = calculateMapEntropy(mapData, 0.5, entropySequenceSize, 1);
        mapVariation = calculateMapVariation(mapData);
        plot(mapVariation, mapEntropy, 'x')
        text(mapVariation, mapEntropy, mapName);
    catch err
    end
end
xlabel('variation')
ylabel(['entropy, with sequence size ' num2str(entropySequenceSize)])