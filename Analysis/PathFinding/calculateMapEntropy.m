function mapEntropy = calculateMapEntropy(mapData, sequenceLen, numSliding)
    [latlngNE, latlngSW] = map_data.getBoundaryCoordinates();
    maxLat = latlngNE(1);
    maxLng = latlngNE(2);
    minLat = latlngSW(1);
    minLng = latlngSW(2);
    
    % let assumes later I'll narrow down into a smaller area, specified as
    % the above area
    
    % calculate entropy...
end

% test:
% map_data = MapData('../../Data/EleSegmentSets/ucla_small/')
% calculateMapEntropy(map_data, 1, 1)
% calculateMapEntropy(map_data, 2, 1)