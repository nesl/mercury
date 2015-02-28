classdef TestCase < handle
    properties (SetAccess = private, GetAccess = private)
        MAT_FOLDER = '../../Data/testCasesForSimulation/';
    end
    
    properties (SetAccess = public, GetAccess = public)  % treat this as a structure only. Thus all the attributes are public
        mapFilePath = '';
        sensorFilePath = '';   % still, all the sensor files should stored under the same folder
        %seaPressure = 0;  % PAUL: my solver won't take this parameter, delete or uncomment based on whether you need these
        %setPressureScalar = 0;
        startAbsTime = 0;  % if the case is manually generated, I guess it's always 0
        stopAbsTime = 0;
        useFakeTurnEvent = 0;  % 0 or (not 0)
        sensorWindowSize = 0;
        mapDataDownSampling = 1;  % as by default
        meta;  % can be anything, cell, structure, whatever
        % PAUL: if you any attribute I didn't consider, just add into the
        % list
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
    end
end

