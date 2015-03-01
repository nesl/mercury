function mapEntropy = calculateMapEntropy(mapData, binWidth, sequenceLen, numSliding)
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
    signatures = [];
    for seg = 1:size(segments,1)                                            
        segElev = ceil(mapData.getSegElev(segments(seg,:))/binWidth);       % Bin all elevations
        for win=1:numSliding:size(segElev,1)-sequenceLen+1                  % For each window
            signatures = [signatures; segElev(win:win+sequenceLen-1)'];     % Store window bin
        end
    end
    [~,~,set] = unique(signatures, 'rows');                                 % Get indices
    tb = tabulate(set);                                                     % Get frequencies
    freqs = tb(:,3)/100;
    mapEntropy = sum(-freqs*log(freqs));                                    % Calculate entropy
end

% test:
% map_data = MapData('../../Data/EleSegmentSets/ucla_small/')
% calculateMapEntropy(map_data, 1, 1)
% calculateMapEntropy(map_data, 2, 1)
