classdef SensorData < handle
    % Revision on Feb. 27: all the timestamps in raw sensor data are
    % aligned with absolute timestamps, unit in second
    
    properties (SetAccess = public, GetAccess = public)
        
        % raw data
        raw_baro;
        raw_acc;
        raw_gyro;
        raw_mag;
        raw_gps;
        raw_gpsele;
        raw_human_event;
        
        % sampling rates
        SR_baro;
        SR_acc;
        SR_gyro;
        SR_mag;
        SR_gps;
        
        % processed data from GPS as ground truth
        gps_speed;
        gps_angles;
        
        % estimated turns and related information from motion sensor
        est_turns;
        est_turn_events;  % MESSGAE TO PAUL from Bo-Jhang: I add this variable
        
        % signal segmentation
        segment_start;  % as the absolute time
        segment_stop;
        window_size = 5;  % seconds
        TRIM_SEC = 5; % seconds
        
        % filtering
        BARO_FNORM = 1e-5;
        
        % pressure to elevation conversion
        PRESSURE_SEALEVEL = 1020;
        PRESSURE_M2HPA = 8; % meter / hPa
        
        % downsampling
        DOWNSAMPLE = 100;
        
        % offset file name
        offset_file_name;
        
    end
    
    methods
        % CONSTRUCTOR
        function obj = SensorData(filepath)

            % parse raw data
            [baro, acc, gyro, mag, gps, gpsele, humanEvent] = parseRawData(filepath);
            
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
            obj.raw_human_event = humanEvent;
            
            % get sampling rates
            obj.SR_baro = mean(1./diff(obj.raw_baro(:,1)));
            obj.SR_acc =  mean(1./diff(obj.raw_acc(:,1)));
            obj.SR_gyro = mean(1./diff(obj.raw_gyro(:,1)));
            obj.SR_mag =  mean(1./diff(obj.raw_gps(:,1)));
            obj.SR_gps =  mean(1./diff(obj.raw_gps(:,1)));
            
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
            
            
            % by default, the segment is slightly trimmed
            % let's just use gps as the default time interval of interest.
            % Otherwise most likely there's no gps data in the beginning
            obj.segment_start = gps(1,1) + obj.TRIM_SEC;
            obj.segment_stop = gps(end,1) - obj.TRIM_SEC;
            
            
            % estimate turns
            [turn_events, turns_full] = estimateTurns(acc, gyro);
            
            % downsample estimated turns
            obj.est_turns = turns_full(1:obj.DOWNSAMPLE:end, :);

            obj.est_turn_events = turn_events;
        end
                
        % SIGNAL SEGMENTATION
        function obj = setAbsoluteSegment(obj, start_sec, stop_sec)
            % ensure we don't exceed the trim boundaries
            obj.segment_start = max( start_sec, obj.raw_baro(1,1) + obj.TRIM_SEC );
            obj.segment_stop  = min( stop_sec,  obj.raw_baro(end,1) - obj.TRIM_SEC );
        end
        
        function obj = setRelativeSegment(obj, start_sec, stop_sec)
            % convert into absolute segmentation, use first barometer sample as global starting time
            obj.setAbsoluteSegment(start_sec + obj.raw_baro(1,1), stop_sec + obj.raw_baro(1,1));
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

        % SEGMENTATION SETTINGS
        function obj = setWindowSize(obj, windowSize)
            obj.window_size = windowSize;
        end
        
        % ACCESSOR METHODS
        function start = getElevationStart(obj)
            elev_all = obj.getElevation();
            start = median(elev_all(1:5,2));
        end
        
        function elev = getElevation(obj)
            baro = obj.getBaro();
            elev = [baro(:,1), (baro(:,2) - obj.PRESSURE_SEALEVEL)*obj.PRESSURE_M2HPA];
        end
        
        function fElev = getElevationFiltered(obj)
           elev = obj.getElevation();
           [b,a] = butter(2, 0.1,'low');
           fElev = filtfilt(b,a,elev);
        end
        
        function dElev = getElevationDeriv(obj)
            % get filtered, estimated height
            elev = obj.getElevationFiltered();
            
            % take derivative of estimated height
            % scaling factor
            SCALE = 30;
            de = SCALE*diff( elev(:,2) );
            dElev = [elev(:,1) [de; de(end)]];
        end
        
        function elev = getElevationTimeWindow(obj)
            elevRaw = obj.getElevation();
            numWindow = floor( (elevRaw(end,1) - elevRaw(1,1)) / obj.window_size );
            elevSum = zeros(numWindow, 1);
            elevCnt = zeros(numWindow, 1);
            for i = 1:length(elevRaw)
                idx = floor((elevRaw(i,1) - elevRaw(1,1)) / obj.window_size) + 1;
                if 1 <= idx && idx <= numWindow
                    elevSum(idx) = elevSum(idx) + elevRaw(i,2);
                    elevCnt(idx) = elevCnt(idx) + 1;
                end
            end
            timestampAfterWindow = ( elevRaw(1,1) + ((1:numWindow) - 1) * obj.window_size )';
            elev = [  timestampAfterWindow  elevSum ./ elevCnt];
            indxs = setdiff( 1:numWindow, find(isnan(elev(:,2))) );  % there might be windows without any data points inside, remove these windows
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
            motion_start_time = obj.segment_start;
            motion_stop_time  = obj.segment_stop;
            data = obj.raw_baro( obj.raw_baro(:,1) >= motion_start_time & ...
                                 obj.raw_baro(:,1) <= motion_stop_time, : );
            data(:,1) = data(:,1) - motion_start_time;
        end
        
        function data = getAcc(obj)
            % find valid indices for this segment
            motion_start_time = obj.segment_start;
            motion_stop_time  = obj.segment_stop;
            data = obj.raw_acc( obj.raw_acc(:,1) >= motion_start_time & ...
                obj.raw_acc(:,1) <= motion_stop_time, : );
            data(:,1) = data(:,1) - motion_start_time;
        end
        
        function data = getGyro(obj)
            % find valid indices for this segment
            motion_start_time = obj.segment_start;
            motion_stop_time  = obj.segment_stop;
            data = obj.raw_gyro( obj.raw_gyro(:,1) >= motion_start_time & ...
                obj.raw_gyro(:,1) <= motion_stop_time, : );
            data(:,1) = data(:,1) - motion_start_time;
        end
        
        function data = getMag(obj)
            % find valid indices for this segment
            motion_start_time = obj.segment_start;
            motion_stop_time  = obj.segment_stop;
            data = obj.raw_mag( obj.raw_mag(:,1) >= motion_start_time & ...
                obj.raw_mag(:,1) <= motion_stop_time, : );
            data(:,1) = data(:,1) - motion_start_time;
        end
        
        function data = getTurns(obj)
            % find valid indices for this segment. the timestamps of raw
            % est_turns are motion-sensor time as it is derived from motion
            % sensors.
            motion_start_time = obj.segment_start;
            motion_stop_time  = obj.segment_stop;
            data = obj.est_turns( obj.est_turns(:,1) >= motion_start_time & ...
                          obj.est_turns(:,1) <= motion_stop_time, :);
            data(:,1) = data(:,1) - motion_start_time;
        end

        % MESSGAE TO PAUL from Bo-Jhang: I add this function
        function turnEvents = getTurnEvents(obj)
            % find valid indices for this segment. the timestamps of raw
            % est_turns are motion-sensor time as it is derived from motion
            % sensors.
            motion_start_time = obj.segment_start;
            motion_stop_time  = obj.segment_stop;
            turnEvents = obj.est_turn_events( obj.est_turn_events(:,1) >= motion_start_time & ...
                          obj.est_turn_events(:,1) <= motion_stop_time, :);
            turnEvents(:,1) = turnEvents(:,1) - motion_start_time;
        end
        
        function turnVector = spanTurnEventsToVector(obj)
            turnVector = obj.getElevationTimeWindow();  % we only curious about time
            turnVector(:,2) = 0;  % by default, the turn is 0
            turnEvents = obj.getTurnEvents();
            for i = 1:size(turnEvents, 1)
                candidates = find(turnVector(:,1) > turnEvents(i, 1));
                if numel(candidates) > 0
                    turnVector(candidates(1), 2) = turnEvents(i, 2);
                end
            end
        end
        
        function heading = getGpsHeading(obj)
%             gps = obj.getGps();
%             % extract instantaneous compass heading
%             headings = [];
%             for i=2:size(gps,1)
%                 angle = atan2d( gps(i,2) - gps(i-1,2), gps(i,3) - gps(i-1,3) );
%                 headings = [headings; angle];
%             end
        end
        
        function heading = getMagHeading(obj)
%             mag = obj.getMag();
%             acc = obj.getAcc();
%             heading = [];
%             % mag is smaller than acc
%             mag2acc_idx = size(acc,1)/size(mag,1);
%             for i=1:size(mag,1)
%                 acc_idx = min(size(acc,1), round(i*mag2acc_idx));
%                 r = vrrotvec(mag(i,2:end), acc(acc_idx,2:end));
%                 R = vrrotvec2mat(r);
%                 angle = 
%             end
%             % convert mag reading to compass heading
%             
         end
        
        function data = getGps(obj)
            % 7 columns: time, lat, lng, elev, error, speed, source
            % find valid indices for this segment
            gps_start_time = obj.segment_start;
            gps_stop_time  = obj.segment_stop;
            data = obj.raw_gps( obj.raw_gps(:,1) >= gps_start_time & ...
                obj.raw_gps(:,1) <= gps_stop_time, : );
            data(:,1) = data(:,1) - gps_start_time;
        end
        
        function speed = getGpsSpeed(obj)
            % find valid indices for this segment
            gps_start_time = obj.segment_start;
            gps_stop_time  = obj.segment_stop;
            indxs = obj.raw_gps(:,1) >= gps_start_time & obj.raw_gps(:,1) <= gps_stop_time; % use raw_gps to get time information
            speed = obj.gps_speed(indxs,:);
            speed(:,1) = speed(:,1) - gps_start_time;
        end
        
        function gps2ele = getGps2Ele(obj)
            % find valid indices for this segment
            gps_start_time = obj.segment_start;
            gps_stop_time  = obj.segment_stop;
            gps2ele = obj.raw_gpsele( obj.raw_gpsele(:,1) >= gps_start_time & ...
                obj.raw_gpsele(:,1) <= gps_stop_time, : );
            gps2ele(:,1) = gps2ele(:,1) - gps_start_time;
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






