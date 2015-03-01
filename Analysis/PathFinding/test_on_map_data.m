% Housekeeping
clear all; clc; close all;

% test on specified map
map_data = MapData('../../Data/EleSegmentSets/Albuquerque_6x6/');
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