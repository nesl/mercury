function [baroData, accData, gyroData, magData, gpsData, gps2eleData, eventData] = parseRawData(filepath, varargin)


% user only needs to specify one file of an entire data set, we'll find the
% rest.

% all the timestamps of all streams of data will aligned to absolute time.

%% find the basename of the filepath
[rootDir, filepath, ~] = fileparts(filepath);
tokens = regexp(filepath, '(.*)\.', 'tokens');
basename = tokens{1}{1};
rootDir = [rootDir '/'];


%% Read associated files
ext    =     {'baro', 'acc',  'gyro',  'mag',  'gps', 'gpsele', 'event', 'offset'};
% time system: motion  motion  motion   motion  gps    gps       abs      ref

numExt = numel(ext);
dataSets = cell(1, numExt);
for i = 1:numExt
    filename = [ rootDir basename '.' ext{i} '.csv' ];
    if exist(filename, 'file')
        try
            fprintf('parsing file: %s ... ', filename);
            dataSets{i} = csvread(filename);
            fprintf('DONE\n');
        catch err
            % consider the error will only be read an empty csv file error.
            fprintf('empty\n');
            dataSets{i} = [];
        end
    else
        fprintf('skipping file: %s\n', filename);
        dataSets{i} = [];
    end
end

motionOffset = dataSets{8}(1);
gpsOffset = dataSets{8}(2);

%% Timescaling to ensure seconds
for i = 1:numExt
    if size(dataSets{i}, 1) ~= 0
        if i <= 4
            dataSets{i}(:,1) = dataSets{i}(:,1) * 1e-9 - motionOffset;
        elseif i <= 6
            dataSets{i}(:,1) = dataSets{i}(:,1) * 1e-3 - gpsOffset;
        end
        
    end
end

baroData    = dataSets{1};
accData     = dataSets{2};
gyroData    = dataSets{3};
magData     = dataSets{4};
gpsData     = dataSets{5};
gps2eleData = dataSets{6};
eventData   = dataSets{7};
