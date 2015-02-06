classdef SensorData < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = public, GetAccess = public)
        % raw data
        raw_baro;
        raw_acc;
        raw_gyro;
        raw_mag;
        raw_gps;
        raw_gpsele;
        
        % additional data
        gps_speed;
        gps_angles;
        est_turns;
        
        % signal segmentation
        segment_start;
        segment_stop;
        TRIM_SEC = 5; % seconds
        
        % time alignment
        gps_offset;
        
        % filtering
        BARO_FNORM = 1e-5;
        
        % pressure to elevation conversion
        PRESSURE_SEALEVEL = 1020;
        PRESSURE_M2HPA = 8; % meter / hPa
        
    end
    
    methods
        % CONSTRUCTOR
        function obj = SensorData(filepath)

            % parse raw data
            [baro, acc, gyro, mag, gps, gpsele] = parseRawData(filepath);
            
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
            obj.raw_gpsele = gpsele;
            
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
            
            % estimate turns
            obj.est_turns = estimateTurns(acc, gyro);

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
        
        % ACCESS TURNS
        % TODO !!!
        
        % PRESSURE TO ELEVATION CONVERSION
        function obj = setSeaPressure(obj, sea_level)
            obj.PRESSURE_SEALEVEL = sea_level;
        end
        
        function obj = setPressureScalar(obj, scalar)
            obj.PRESSURE_M2HPA = scalar;
        end

        % ACCESSOR METHODS
        function elev = getElevation(obj)
            baro = obj.getBaro();
            elev = [baro(:,1), (baro(:,2) - obj.PRESSURE_SEALEVEL)*obj.PRESSURE_M2HPA];
        end
        
        function elev = getElevationTimeWindow(obj)
            elevRaw = obj.getElevation();
            numWindow = floor( (elevRaw(end,1) - elevRaw(1,1)) / obj.TRIM_SEC );
            elevSum = zeros(numWindow, 1);
            elevCnt = zeros(numWindow, 1);
            for i = 1:length(elevRaw)
                idx = floor((elevRaw(i,1) - elevRaw(1,1)) / obj.TRIM_SEC) + 1;
                if 1 <= idx && idx <= numWindow
                    elevSum(idx) = elevSum(idx) + elevRaw(i,2);
                    elevCnt(idx) = elevCnt(idx) + 1;
                end
            end
            timestampAfterWindow = ( elevRaw(1,1) + ((1:numWindow) - 1) * obj.TRIM_SEC )';
            elev = [  timestampAfterWindow  elevSum ./ elevCnt];
            indxs = setdiff( 1:numWindow, find(isnan(elev(:,2))) );  % there might be windows which has no data points, remove them
            elev = elev(indxs,:);  
        end
        
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
            data(:,1) = data(:,1) - obj.segment_start;
        end
        
        function data = getAcc(obj)
            % find valid indices for this segment
            data = obj.raw_acc( obj.raw_acc(:,1) >= obj.segment_start & ...
                obj.raw_acc(:,1) <= obj.segment_stop, : );
            data(:,1) = data(:,1) - obj.segment_start;
        end
        
        function data = getGyro(obj)
            % find valid indices for this segment
            data = obj.raw_gyro( obj.raw_gyro(:,1) >= obj.segment_start & ...
                obj.raw_gyro(:,1) <= obj.segment_stop, : );
            data(:,1) = data(:,1) - obj.segment_start;
        end
        
        function data = getMag(obj)
            % find valid indices for this segment
            data = obj.raw_mag( obj.raw_mag(:,1) >= obj.segment_start & ...
                obj.raw_mag(:,1) <= obj.segment_stop, : );
            data(:,1) = data(:,1) - obj.segment_start;
        end
        
        function data = getGps(obj)
            % find valid indices for this segment
            % time, lat, lng, speed, error, source (maybe...)
            indxs =  (obj.raw_gps(:,1)-obj.gps_offset) >= obj.segment_start & ...
                          (obj.raw_gps(:,1)-obj.gps_offset) <= obj.segment_stop ;
            data = obj.raw_gps(indxs,:);
            data(:,1) = data(:,1) - (obj.segment_start + obj.gps_offset);
        end
        
        function speed = getGpsSpeed(obj)
            % find valid indices for this segment
            indxs =  (obj.raw_gps(:,1)-obj.gps_offset) >= obj.segment_start & ...
                          (obj.raw_gps(:,1)-obj.gps_offset) <= obj.segment_stop ;
            speed = obj.gps_speed(indxs,:);
            speed(:,1) = speed(:,1) - (obj.segment_start + obj.gps_offset);
        end
        
        function gps2ele = getGps2Ele(obj)
            % find valid indices for this segment
            indxs =  (obj.raw_gpsele(:,1)-obj.gps_offset) >= obj.segment_start & ...
                          (obj.raw_gpsele(:,1)-obj.gps_offset) <= obj.segment_stop ;
            gps2ele = obj.raw_gpsele(indxs,:);
            gps2ele(:,1) = gps2ele(:,1) - (obj.segment_start + obj.gps_offset);
        end
        
        % VISUALIZATION
        function plotElevation(obj)
            gps2ele = obj.getGps2Ele();
            baro = obj.getBaro();
            elevFromBaro = obj.getElevation();
            
            clf
                
            subplot(2, 2, 1)
            title('Barometer data');
            plot(baro(:,1), baro(:,2), 'r-');
            ylabel('Pressure (hPa)');
            xlabel('Time (sec)');
            
            subplot(2, 2, 3)
            title('Elevation from GPS lat/lng');
            if size(gps2ele, 1) == 0
                text(0, 0, 'Sorry, gpsele file have not generated');
            else
                plot(gps2ele(:,1), gps2ele(:,4), 'b-');
            end
            xlabel('Time (sec)');
            ylabel('Elevation (meter)');
            
            subplot(2, 2, 2)
            title('Use configured scaling coefficients');
            if size(gps2ele, 1) == 0
                text(0, 0, 'Sorry, gpsele file have not generated');
            else
                hold on
                plot(gps2ele(:,1), gps2ele(:,4), 'b-');
                plot(elevFromBaro(:,1), elevFromBaro(:,2), 'r-');
            end
            xlabel('Time (sec)');
            ylabel('Elevation (meter)');
            
            subplot(2, 2, 4)
            title('Best fit');
            %TODO
            text(0, 0, 'To be done.......');
            xlabel('Time (sec)');
            ylabel('Elevation (meter)');
        end
    end
    
end





