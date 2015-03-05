classdef SensorDataSim < handle
    % Revision on Feb. 27: all the timestamps in raw sensor data are
    % aligned with absolute timestamps, unit in second
    
    properties (SetAccess = public, GetAccess = public)
        
        elevations;
        turns;
        gps;
        
    end
    
    methods
        % CONSTRUCTOR
        function obj = SensorDataSim(elev, turns, gps)

            obj.elevations = elev;
            obj.turns = turns;
            obj.gps = gps;
            
        end
        
        function elev = getElevationTimeWindow(obj)
            elev = obj.elevations;
        end
        
        function elev = getElevationStart(obj)
            elev = obj.elevations(1);
        end

        function gps = getGps()
            gps = obj.gps;
        end
      
        % MESSGAE TO PAUL from Bo-Jhang: I add this function
        function turnEvents = getTurnEvents(obj)
            turnEvents = obj.turns;
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
        
    end
    
end






