function [baroData, accData, gyroData, magData, gpsData, gps2eleData] = parseRawData(filepath, varargin)


% user only needs to specify one file of an entire data set, we'll find the
% rest.

%% find the basename of the filepath
[rootDir, filepath, ~] = fileparts(filepath);
tokens = regexp(filepath, '(.*)\.', 'tokens');
basename = tokens{1}{1};
rootDir = [rootDir '/'];


%% Read associated files
ext = {'baro', 'acc', 'gyro', 'mag', 'gps', 'gpsele'};
numExt = size(ext, 2);
dataSets = cell(1, numExt);
for i = 1:numExt
    filename = [ rootDir basename '.' ext{i} '.csv' ];
    if exist(filename, 'file')
        fprintf('parsing file: %s ... ', filename);
        dataSets{i} = csvread(filename);
        fprintf('DONE\n');
    else
        fprintf('skipping file: %s\n', filename);
        dataSets{i} = [];
    end
end


%% Timescaling to ensure seconds
for i = 1:numExt
    if size(dataSets{i}, 1) ~= 0
        if i <= 4
            tscale = 1e-9;
        else
            tscale = 1e-3;
        end
        dataSets{i}(:,1) = dataSets{i}(:,1)*tscale;
    end
end

baroData    = dataSets{1};
accData     = dataSets{2};
gyroData    = dataSets{3};
magData     = dataSets{4};
gpsData     = dataSets{5};
gps2eleData = dataSets{6};
