% Housekeeping
clear all; clc; close all;

% test on specified map
map_data = MapData('../../Data/EleSegmentSets/Chicago_6x6.map');
[latlngNE, latlngSW] = map_data.getBoundaryCoordinates()
[meterHorizontal, meterVertical] = map_data.getBoundaryDistance()  % expected 6x6 mile, which should be roughly 9600 each
area = map_data.getBoundingBoxArea()
totalDistanceInMeter = map_data.getTotalDistanceOfAllSegments()

% also test MapManager
map_manager = MapManager();
[map_data, map_path] = map_manager.getMapDataObject(2, 6, 1)
[latlngNE, latlngSW] = map_data.getBoundaryCoordinates()
[meterHorizontal, meterVertical] = map_data.getBoundaryDistance()  % expected 6x6 mile, which should be roughly 9600 each
area = map_data.getBoundingBoxArea()
totalDistanceInMeter = map_data.getTotalDistanceOfAllSegments()

%% test rescale.py / tmpBatchFinalChecking.py
map_manager = MapManager();

[map_data, map_path] = map_manager.getMapDataObject(1, 6, 1);
[meterHorizontal, meterVertical] = map_data.getBoundaryDistance()  % expected 6x6 mile, which should be roughly 9600 each
[latlngNE, latlngSW] = map_data.getBoundaryCoordinates()

[map_data, map_path] = map_manager.getMapDataObject(1, 2, 1);
[meterHorizontal, meterVertical] = map_data.getBoundaryDistance()  % expected 2x2 mile, which should be roughly 3200 each
[latlngNE, latlngSW] = map_data.getBoundaryCoordinates()