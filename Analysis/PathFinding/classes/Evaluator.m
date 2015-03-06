classdef Evaluator < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensor_data;
        map_data;
    end
    
    methods
        function obj = Evaluator(sensorData, mapData)
            obj.sensor_data = sensorData;
            obj.map_data = mapData;
        end
        
        function latLngSeries = getPathLatLng(obj, elevBaro, costFunction, varargin)
            % Each varargin serves as a path, or <time, nodeIdx> series, which should be a Nx2 matrix.
            % Thus, return value is a row cell of latlngs whose size is the same as number of paths.
            % latlngs is a <lat, lng> series.
            latLngSeries = cell(1, numel(varargin));
            for i = 1:numel(varargin)
                rawPath = varargin{i};
                latlngs = [];
                for j = 1:size(rawPath, 1) - 1
                    elevMapSeg = obj.map_data.getSegElev( rawPath(j:j+1, 2) );
                    latlngMapSeg = obj.map_data.getSegLatLng( rawPath(j:j+1, 2) );
                    a = rawPath(j  , 1);
                    b = rawPath(j+1, 1) - 1;
                    elevBaroSeg = elevBaro(a:b, 2);
                    [~, dtwIdxBaro2Map, ~] = dtw_basic( elevMapSeg, elevBaroSeg, costFunction, @(x) (inf) );
                    latlngs = [latlngs ; latlngMapSeg(dtwIdxBaro2Map,:)];
                end
                latLngSeries{i} = latlngs;
            end
        end
        
        function timeLatLngSeries = getTimeLatLngPath(obj, elevBaro, costFunction, varargin)
            % Each varargin serves as a path, or <time, nodeIdx> series, which should be a Nx2 matrix.
            % Thus, return value is a row cell of timeLatLngs whose size is the same as number of paths.
            % timeLatLngs is a <time, lat, lng> series.
            timeLatLngSeries = cell(1, numel(varargin));
            for i = 1:numel(varargin)
                tmpTimeLatLng = obj.getPathLatLng(elevBaro, costFunction, varargin{i});
                timeLatLngSeries{i} = [ elevBaro(:,1)  tmpTimeLatLng{1} ];
            end
        end
        
        function rmsInMeter = getPathShapeSimilarity(obj, varargin)
            % Each varargin serves as a <lat, lng> series, which should be a Nx2 matrix.
            % Thus, return value is a row vector whose size is the same as number of paths.
            rmsInMeter = [];
            for i = numel(varargin)
                estimatedTimeLatLngs = varargin{i};  
                groundTruthTimeLatLngs = obj.sensor_data.getGps();
                groundTruthLatLngs = groundTruthTimeLatLngs(:, 2:3);
                rmsInMeter = [rmsInMeter; ...
                    gps_series_compare(groundTruthLatLngs, estimatedTimeLatLngs)];
            end
        end
        
        function rmsInMeter = getPathSimilarityConsideringTime(obj, varargin) 
            % Each varargin serves as a <time, lat, lng> series, which should be a Nx3 matrix.
            % Thus, return value is a row vector whose size is the same as number of paths.
            rmsInMeter = [];
            for i = numel(varargin)
                estimatedTimeLatLngs = varargin{i};
                groundTruthTimeLatLngs = obj.sensor_data.getGps();
                groundTruthTimeLatLngs = groundTruthTimeLatLngs(:, 1:3);
                rmsInMeter = [rmsInMeter; ...
                    time_gps_series_compare(groundTruthTimeLatLngs, estimatedTimeLatLngs)];
            end
        end
        
        function toWeb(obj, outputPath, flagBeautiful, attributes, attributeValues, paths)
            % outputPath: the path to save .rset file
            % flagBeautiful: segment style (0) or smooth style (1)
            % attributes: a cell of strings to specify attribute names
            % attributeValues: a 2d matrix, each row stands for the attribute values of the corresponcing path
            % paths: a cell of path, each path is nodeIdx list
            
            % dimension checking
            if numel(attributes) ~= size(attributeValues, 2)
                error('The number of attributes (%d) and number of attribute values of each row (%d) are not agreed.', numel(attributes), size(attributeValues, 2));
            end
            if numel(paths) ~= size(attributeValues, 1)
                error('The number of paths (%d) and number of sets of attribute values (%d) are not agreed.', numel(paths), size(attributeValues, 1));
            end
            
            % ground truth gps
            fid = fopen(outputPath, 'w');
            gpsData = obj.sensor_data.getGps();
            for i = 1:size(gpsData, 1)
                fprintf(fid, '%f,%f,', gpsData(i,2), gpsData(i,3) );
            end
            fprintf(fid, '-1\n');
            
            % attributes
            fprintf(fid, '%d\n', numel(attributes));
            for i = 1:numel(attributes)
                fprintf(fid, '%s\n', attributes{i});
            end
            
            % paths
            fprintf(fid, '%d\n', numel(paths));
            for i = 1:numel(paths)
                for j = 1:numel(attributes)
                    fprintf(fid, '%.2f,', attributeValues(i,j));
                end
                
                rawPath = paths{i};
                if size(rawPath, 2) == 2
                    for j=1:size(rawPath, 1)
                        fprintf(fid, '%f,%f,', rawPath(j,1), rawPath(j,2));
                    end
                else
                    if flagBeautiful == 0
                        for j=1:size(rawPath, 1)
                            latlngs = obj.map_data.getNodeIdxLatLng( rawPath(j,2) );
                            fprintf(fid, '%f,%f,', latlngs(1), latlngs(2));
                        end
                    elseif flagBeautiful == 1
                        estiLatLng = obj.map_data.getPathLatLng(rawPath);
                        for j=1:size(estiLatLng, 1)
                            fprintf(fid, '%f,%f,', estiLatLng(j,1), estiLatLng(j,2));
                        end
                    else
                        error('Unsupported mode of generating result (in private_toWeb())');
                    end
                end
                
                fprintf(fid, '-1\n');
            end
            fclose(fid);
            fprintf(['File created. Please check file "' outputPath '"\n']);
        end
    end
    
end

