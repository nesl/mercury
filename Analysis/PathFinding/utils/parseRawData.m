function [baroData, accData, gyroData, magData, gpsData] = parseRawData(filepath, varargin)

% output is SensorData object

% user only needs to specify one file of an entire data set, we'll find the
% rest.

%% find the basename of the filepath
[rootDir, filepath, ~] = fileparts(filepath);
tokens = regexp(filepath, '(.*)\.', 'tokens');
basename = tokens{1}{1};
rootDir = [rootDir '/'];

%% Read associated files
ext = {'baro', 'acc', 'gyro', 'mag', 'gps', 'gpsele'};
nrExt = size(ext, 2);
dataSets = cell(1, nrExt);
for i = 1:nrExt
    filename = [ rootDir 'baro_' basename '.' ext{i} '.csv' ];
    if exist(filename, 'file')
        fprintf('parsing file: %s', filename);
        dataSets{i} = csvread(filename);
        fprintf('DONE\n');
    else
        dataSets{i} = [];
    end
end

%% Align data in time

% et = inf;
% bt = dataSets{1}(1,1) * 1e-9;
% if numel(varargin) == 2
%     bt = varargin{1};
%     et = varargin{2} - bt;
% end

for i = 1:nrExt
    if size(dataSets{i}, 1) ~= 0
        if i <= 4
            tscale = 1e-9;
        else
            tscale = 1e-3;
        end
        dataSets{i}(:,1) = dataSets{i}(:,1)*tscale;
        %         ind = (st <= dataSets{i}(:,1)) & (dataSets{i}(:,1) <= et);
        %         dataSets{i} = dataSets{i}(ind,:);
    end
end

baroData   = dataSets{1};
accData    = dataSets{2};
gyroData   = dataSets{3};
magData    = dataSets{4};
gpsData    = dataSets{5};
