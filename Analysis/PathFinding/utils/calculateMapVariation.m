function mapVariation = calculateMapVariation(mapData)
    %[latlngNE, latlngSW] = mapData.getBoundaryCoordinates();
    %maxLat = latlngNE(1);
    %maxLng = latlngNE(2);
    %minLat = latlngSW(1);
    %minLng = latlngSW(2);
    
    % let assumes later I'll narrow down into a smaller area, specified as
    % the above area
    
    % calculate entropy...
    % for each segment
    %   ...
    
    segments = mapData.getAllSegments();                                    % Grab all segments
    elev = [];
    for seg = 1:size(segments,1)                                            
        segElev = mapData.getSegElev(segments(seg,:))';
        elev = [elev segElev];
    end
    mapVariation = var(elev);
end