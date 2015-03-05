classdef SensorDataSim < handle
    % Revision on Feb. 27: all the timestamps in raw sensor data are
    % aligned with absolute timestamps, unit in second
    
    properties (SetAccess = public, GetAccess = public)
        
        elevations;
        turns;
        
    end
    
    methods
        % CONSTRUCTOR
        function obj = SensorDataSim(elev, turns)

            obj.elevations = elev;
            obj.turns = turns;
            
        end
        
        function elev = getElevationTimeWindow(obj)
            elev = obj.elevations;
        end
        
        function elev = getElevationStart(obj)
            elev = obj.elevations(1);
        end

        function data = getBaro(obj)
            % TODO
            data = 0;
        end
      
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






