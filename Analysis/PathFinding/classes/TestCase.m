classdef TestCase < handle
    
    properties (SetAccess = private, GetAccess = private)
        MAT_FOLDER = '../../Data/testCasesForSimulation/';
    end
    
    properties (SetAccess = public, GetAccess = public)
        % map set up
        simulated = false;
        mapFilePath = '';
        sensorFilePath = '';
        seaPressure = 0; 
        pressureScalar = 0;
        startAbsTime = 0; 
        stopAbsTime = 0;
        sensorWindowSize = 0;
        mapDataDownSampling = 1;
        
        % simulation data
        sim_elevations;
        sim_turns;
        sim_elevations_nonoise;
        sim_turns_nonoise;
        sim_path;
        sim_gps;
        sim_speed;

        % for all the rest:
        meta;
    end
    

    methods
        function obj = TestCase(varargin)  % if it is empty, then it creates a new one.
                                           % otherwise, it loads a mat file from MAT_FOLDER
            if numel(varargin) >= 1  % load mode
                matFilePath = [obj.MAT_FOLDER varargin{1}];
                load(matFilePath, 'obj');
            end
        end
        
        function save(obj, caseName)  % case name is very important, as it should always be unique,
                                      % also it treats as the mat file name
            % simple checking
            if isempty(caseName)
                error('caseName cannot be an empty string (save())')
            end
            if isempty(obj.mapFilePath)
                error('This test case is incomplete: unspecified mapFilePath (save())')
            end
            if isempty(obj.sensorFilePath)
                error('This test case is incomplete: unspecified sensorFilePath (save())')
            end
            if obj.stopAbsTime - obj.startAbsTime < 30
                error('Safety check: half-minute test case? (save())')
            end
            if obj.sensorWindowSize <= 0
                error('Didn''t specify sensor window size (save())')
            end
            matFilePath = [obj.MAT_FOLDER caseName];
            save(matFilePath, 'obj');
        end
        
        function saveTo(obj, fpath, caseName)  % case name is very important, as it should always be unique,
                                      % also it treats as the mat file name
            % simple checking
            if isempty(caseName)
                error('caseName cannot be an empty string (save())')
            end
            if isempty(obj.mapFilePath)
                error('This test case is incomplete: unspecified mapFilePath (save())')
            end

            if obj.stopAbsTime - obj.startAbsTime < 30
                warning('Safety check: half-minute test case? (save())')
            end
            if obj.sensorWindowSize <= 0
                error('Didn''t specify sensor window size (save())')
            end
            matFilePath = [obj.MAT_FOLDER caseName];
            save(fpath, 'obj');
        end
        
    end
end

