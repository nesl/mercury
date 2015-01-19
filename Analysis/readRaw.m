function [baroData, accData, gyroData, magData, gpsData, gpsEleData] = readRaw(fileID)

% fileID refer to middle parts of file
% e.g. baro_n501_20141127_174324.mag.csv
%           ^^^^^^^^^^^^^^^^^^^^
%
% read() accept either 1 or 3 arguments. The last two specify begining and
% edding points of time interested, unit in second.

rootDir = '../Data/forMat/';
ext = {'baro', 'acc', 'gyro', 'mag', 'gps', 'gpsele'};
nrExt = size(ext, 2);
dataSets = cell(1, nrExt);
for i = 1:nrExt
    filename = [ rootDir 'baro_' fileID '.' ext{i} '.csv' ]
    if exist(filename, 'file')
        dataSets{i} = csvread(filename);
    else
        dataSets{i} = [];
    end
end

baroData   = dataSets{1};
accData    = dataSets{2};
gyroData   = dataSets{3};
magData    = dataSets{4};
gpsData    = dataSets{5};
gpsEleData = dataSets{6};
