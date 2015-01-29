classdef SensorData < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private, GetAccess = private)
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
        segment_stop;
        TRIM_SEC = 5; % seconds
        
        % time alignment
        gps_offset;
        
        % filtering
        BARO_FNORM = 1e-5;
        
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
            
            % by default, the segment is slightly trimmed
            obj.segment_start = baro(1,1) + obj.TRIM_SEC;
            obj.segment_stop = baro(end,1) - obj.TRIM_SEC;
            
            % Calculate gpsSpeed
            obj.gps_speed = zeros(size(obj.raw_gps,1), 2);
            obj.gps_speed(:,1) = obj.raw_gps(:,1);
            for i=1:( size(obj.gps_speed,1) - 1 )
                dist = latlng2m(gps(i,2:3), gps(i+1,2:3));
                dt = gps(i+1,1) - gps(i,1);
                obj.gps_speed(i,2) = dist/dt;
            end
            % assign last index in speed to duplicate second to last
            obj.gps_speed(end,2) = obj.gps_speed(end-1,2);

            % Calculate gpsAngles
            obj.gps_angles = 0;
            % TODO: !!!
            
            % GPS time alignment - assume that the baro and gps samples at
            % the END are roughly matched up in time
            obj.gps_offset = gps(end,1) - baro(end,1);

        end
        
        % SIGNAL SEGMENTATION
        
        function obj = setAbsoluteSegment(obj, start_sec, stop_sec)
            % ensure we don't exceed the trim boundaries
            obj.segment_start = max( start_sec, obj.raw_baro(1,1) + obj.TRIM_SEC );
            obj.segment_stop  = min( stop_sec,  obj.raw_baro(end,1) - obj.TRIM_SEC );

        end
        
        function obj = setRelativeSegment(obj, start_sec, stop_sec)
            % convert into absolute segmentation
            t0 = obj.raw_baro(1,1) + obj.TRIM_SEC;
            start_abs = t0 + start_sec;
            stop_abs = t0 + stop_sec;
            
            obj.setAbsoluteSegment(start_abs, stop_abs);
            
        end

        % ACCESSOR METHODS
        function filtered = getFilteredBaro(obj)
            % get raw barometer data
            baro = obj.getBaro();
            filtered(:,1) = baro(:,1);
            % filter raw data
            [B,A] = butter(1,obj.BARO_FNORM, 'high');
            filtered(:,2) = filtfilt(B, A, baro(:,2));
        end
        
        function data = getBaro(obj)
            % find valid indices for this segment
            data = obj.raw_baro( obj.raw_baro(:,1) >= obj.segment_start & ...
                                 obj.raw_baro(:,1) <= obj.segment_stop, : );
        end
        
        function data = getAcc(obj)
            % find valid indices for this segment
            data = obj.raw_acc( obj.raw_acc(:,1) >= obj.segment_start & ...
                obj.raw_acc(:,1) <= obj.segment_stop, : );
        end
        
        function data = getGyro(obj)
            % find valid indices for this segment
            data = obj.raw_gyro( obj.raw_gyro(:,1) >= obj.segment_start & ...
                obj.raw_gyro(:,1) <= obj.segment_stop, : );
        end
        
        function data = getMag(obj)
            % find valid indices for this segment
            data = obj.raw_mag( obj.raw_mag(:,1) >= obj.segment_start & ...
                obj.raw_mag(:,1) <= obj.segment_stop, : );
        end
        
        function latlng = getGps(obj)
            % find valid indices for this segment
            indxs =  (obj.raw_gps(:,1)-obj.gps_offset) >= obj.segment_start & ...
                          (obj.raw_gps(:,1)-obj.gps_offset) <= obj.segment_stop ;
            latlng = obj.raw_gps(indxs,:);
        end
        
        function speed = getGpsSpeed(obj)
            % find valid indices for this segment
            indxs =  (obj.raw_gps(:,1)-obj.gps_offset) >= obj.segment_start & ...
                          (obj.raw_gps(:,1)-obj.gps_offset) <= obj.segment_stop ;
            speed = obj.gps_speed(indxs,:);
        end
        
    end
    
end






