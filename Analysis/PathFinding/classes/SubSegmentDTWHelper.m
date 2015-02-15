classdef SubSegmentDTWHelper < handle
    % calculating-on-demand DTW querier
    
    properties (SetAccess = public, GetAccess = public)
        % NOTE: as usual, the access is open for debugging purpose. As
        % usual, in regular case all the variables shouldn't be accessed
        % directly.
        
        % input
        elev_from_baro;
        map_data;
        
        % cache result
        segment_allSubSegmentDTW;
    end
    
    methods
        % CONSTRUCTOR
        function obj = SubSegmentDTWHelper(mapData, elevFromBaro)
            obj.map_data = mapData;
            obj.elev_from_baro = elevFromBaro;
            numNodes = mapData.getNumNodes();
            obj.segment_allSubSegmentDTW = cell(numNodes);
        end
        
        
        function score = query(obj, nodeAIdx, nodeBIdx, baroStartIdx, baroEndIdx)
            if numel( obj.segment_allSubSegmentDTW{nodeAIdx, nodeBIdx} ) == 0   % haven't created a matrix there
                obj.segment_allSubSegmentDTW{nodeAIdx, nodeBIdx} = nan( numel(obj.elev_from_baro) );
            end
            if isnan( obj.segment_allSubSegmentDTW{nodeAIdx, nodeBIdx}(baroStartIdx, end) )
                [ obj.segment_allSubSegmentDTW{nodeAIdx, nodeBIdx}(baroStartIdx, baroStartIdx:end), ~, ~] ...
                    = dtw_basic( obj.map_data.getSegElev([nodeAIdx nodeBIdx]), obj.elev_from_baro(baroStartIdx:end) );
            end
            score = obj.segment_allSubSegmentDTW{nodeAIdx, nodeBIdx}(baroStartIdx, baroEndIdx);
        end
        
        % statistics of DTW data storage ratio.
        %    - ratioOfDTWQuery = DTW requests / expected DTW query
        %    - ratioOfElements = valid results / all the subsegments of all segments
        function [ratioOfDTWQuery, ratioOfElements] = pruningRate(obj)
            numDTWRequest = 0;
            expectedDTWRequest = 0;
            validElements = 0;
            expectedTotalElements = 0;
            
            numElementElevFromBaro = numel(obj.elev_from_baro);
            segs = obj.map_data.getAllSegments();
            for segIdx = 1:size(segs, 1)
                seg = segs(segIdx, :);
                segNumElement = obj.map_data.getSegNumElement(seg);
                for flipIdx = 1:2
                    seg = fliplr(seg);
                    na_idx = seg(1);
                    nb_idx = seg(2);
                    
                    t = 0;
                    if numel( obj.segment_allSubSegmentDTW{na_idx, nb_idx} ) ~= 0   % there's a matrix there
                        for rowIdx = 1:segNumElement
                            if ~isnan( obj.segment_allSubSegmentDTW{na_idx, nb_idx}(rowIdx, end) )
                                numDTWRequest = numDTWRequest + 1;
                                validElements = validElements + sum(obj.segment_allSubSegmentDTW{na_idx, nb_idx}(rowIdx, rowIdx:end) < inf);
                                t = t + sum(obj.segment_allSubSegmentDTW{na_idx, nb_idx}(rowIdx, rowIdx:end) < inf);
                            end
                        end
                    end
                    expectedDTWRequest = expectedDTWRequest + numElementElevFromBaro;
                    expectedTotalElements = expectedTotalElements + (numElementElevFromBaro * (numElementElevFromBaro+1)) / 2;
                end
            end
            if expectedDTWRequest == 0
                ratioOfDTWQuery = 0;
                ratioOfElements = 0;
            else
                ratioOfDTWQuery = numDTWRequest / expectedDTWRequest;
                ratioOfElements = validElements / expectedTotalElements;
            end
        end
    end
    
end

