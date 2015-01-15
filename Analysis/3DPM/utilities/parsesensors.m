function [baroData, accData, gyroData, magData, gpsData, gpsSpeed] = parsesensors(fileID, varargin)

% fileID refer to middle parts of file
% e.g. baro_n501_20141127_174324.mag.csv
%           ^^^^^^^^^^^^^^^^^^^^
%
% read() accept either 1 or 3 arguments. The last two specify begining and
% edding points of time interested, unit in second.

rootDir = '../../Data/forMat/';
ext = {'baro', 'acc', 'gyro', 'mag', 'gps'};
nrExt = size(ext, 2);
dataSets = cell(1, nrExt);
for i = 1:nrExt
    filename = [ rootDir 'baro_' fileID '.' ext{i} '.csv' ];
    if exist(filename, 'file')
        dataSets{i} = csvread(filename);
        fprintf('parsing file: %s\n', filename);
    else
        fprintf('cannot find file: %s\n', filename);
        dataSets{i} = [];
    end
end

% st = 0;
% et = inf;
% bt = dataSets{1}(1,1) * 1e-9;
% if numel(varargin) == 2
%     st = varargin{1};
%     et = varargin{2};
%     bt = st;
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

%% Calculate gpsSpeed
gpsSpeed = zeros(size(gpsData,1), 2);
gpsSpeed(:,1) = gpsData(:,1);
for i=1:( size(gpsSpeed,1) - 1 )
    dist = latlng2m(gpsData(i,2:3), gpsData(i+1,2:3));
    dt = gpsData(i+1,1) - gpsData(i,1);
    gpsSpeed(i,2) = dist/dt;
end
% assign last index in speed to duplicate second to last
gpsSpeed(end,2) = gpsSpeed(end-1,2);

