classdef SensorData
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        % raw data
        raw_baro;
        raw_acc;
        raw_gyro;
        raw_mag;
        raw_gps;
        
        % additional data
        gps_speed;
        gps_angles;
        
        % signal segmentation
        segment_start;
        segment_duration;
        
    end
    
    methods
        % CONSTRUCTOR
        function obj = SensorData(filepath)
            
            % parse raw data
            [baro, acc, gyro, mag, gps] = parseRawData(filepath);
            
            % ensure at least baro and gps are not empty
            if isempty(baro) || isempty(gps)
                error('Error: Baro or GPS data supplied to SensorData constructor is empty');
            end
            
            % assign raw data
            obj.raw_baro = baro;
            obj.raw_acc = acc;
            obj.raw_gyro = gyro;
            obj.raw_mag = mag;
            obj.raw_gps = gps;
            
            % by default, the segmentation is the entire sensor data
            obj.segment_start = 1;
            obj.segment_duration = size(baro,1);
            
            
            % Calculate gpsSpeed
            obj.gps_speed = zeros(size(obj.raw_gps,1), 2);
            obj.gps_speed(:,1) = obj.raw_gps(:,1);
            for i=1:( size(obj.gps_speed,1) - 1 )
                dist = latlng2m(gpsData(i,2:3), gpsData(i+1,2:3));
                dt = gpsData(i+1,1) - gpsData(i,1);
                obj.gps_speed(i,2) = dist/dt;
            end
            % assign last index in speed to duplicate second to last
            obj.gps_speed(end,2) = obj.gps_speed(end-1,2);

            % Calculate gpsAngles
            obj.gps_angles = 0;
            % TODO: !!!
            
            % perform timing alignment on all data
            % TODO: !!!
        end
        
        % SIGNAL SEGMENTATION
        function obj = setSegmentStart(obj, start_sec)
            obj.segment_start = start_sec;
        end
        
        function obj = setSegmentDuration(obj, dur_sec)
            obj.segment_duration = dur_sec;
        end
        
        % ACCESSOR METHODS
        function data = getBaro(obj)
            % TODO: segment !!!
            data = obj.raw_baro;
        end
        
        
    end
    
end

