function [baroData, accData, gyroData, magData, gpsData] = read(fileID, varargin)

% fileID refer to middle parts of file
% e.g. baro_n501_20141127_174324.mag.csv
%           ^^^^^^^^^^^^^^^^^^^^
%
% read() accept either 1 or 3 arguments. The last two specify begining and
% edding points of time interested, unit in second.

rootDir = 'forMat/';
ext = {'baro', 'acc', 'gyro', 'mag', 'gps'};
dataSets = cell(1, 5);
for i = 1:5
    filename = [ rootDir 'baro_' fileID '.' ext{i} '.csv' ]
    dataSets{i} = csvread(filename);
end

st = 0;
et = inf;
bt = dataSets{1}(1,1) * 1e-9;
if numel(varargin) == 2
    st = varargin{1};
    et = varargin{2};
    bt = st;
end

for i = 1:5
    if i <= 4
        w = 1e-9;
    else
        w = 1e-3;
    end
    dataSets{i}(:,1) = dataSets{i}(:,1) * w - bt;
    ind = (st <= dataSets{i}(:,1)) & (dataSets{i}(:,1) <= et);
    dataSets{i} = dataSets{i}(ind,:);
end

baroData = dataSets{1};
accData  = dataSets{2};
gyroData = dataSets{3};
magData  = dataSets{4};
gpsData  = dataSets{5};

