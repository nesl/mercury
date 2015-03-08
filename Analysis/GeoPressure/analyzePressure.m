%% Housekeeping
clc; close all; clear all;

%% Data file path
fpath = '../../Data/GeoData/weather/raw/';
fname = '201501hourly';
fid = fopen([fpath fname '.txt']);
LOCATION_COL = 1;
DATE_COL = 2;
HOUR_COL = 3;
PRESSURE_COL = 31;

%% Load pressure data into matrix
if exist(['../../Data/GeoData/weather/pressure/' fname '.mat'])
    load(['../../Data/GeoData/weather/pressure/' fname '.mat']);
else
    
    % how many lines do we need to load?
    MAX_LINES = 1924111;
    
    location_ids = [];
    all_data = {};
    num_locations = 0;
    
    % skip first line
    line = fgetl(fid);
    line = fgetl(fid);
    
    line_num = 3;
    
    while line ~= -1
        
        % split up line
        tokens = strsplit(line,',');
        
        % get station ID
        station_id = str2double( tokens(LOCATION_COL) );
        
        % get station date
        datestr = tokens{DATE_COL};
        year  = str2double( datestr(1:4) );
        month = str2double( datestr(5:6) );
        day   = str2double( datestr(7:8) );
        
        % get hour sample was taken
        timestr = tokens{HOUR_COL};
        hour = str2double( timestr(1:2) );
        min = str2double( timestr(3:4) );
        hour = str2double( tokens(HOUR_COL) );
        
        % convert to POSIX time
        date_now = datenum(year, month, day, hour, min, 0);
        posix_time = int32(floor(86400 * (date_now - datenum('01-Jan-1970'))));
        
        % get pressure
        pressure_inhg = str2double( tokens(PRESSURE_COL) );
        % convert to hPa
        pressure_hpa = pressure_inhg*33.86;
        
        % if the pressure is 0, ignore. this is bad data
        if pressure_hpa == 0
            continue;
        end
        
        % add to matrix
        idx = find(location_ids == station_id);
        if isempty(idx)
            % first time we saw this location
            num_locations = num_locations + 1;
            fprintf('Processing Location %d  (%.2f)\n', num_locations, 100*line_num/MAX_LINES);
            location_ids(num_locations) = station_id;
            idx = num_locations;
            all_data{num_locations} = [posix_time pressure_hpa];
            
        else
            % we've seen this location before
            all_data{idx} = [all_data{idx}; [posix_time pressure_hpa]];
        end

        
        % read next line
        line = fgetl(fid);
        line_num = line_num + 1;
    end
    
    % save in cache
    save(['../../Data/GeoData/weather/pressure/' fname '.mat'], 'location_ids', 'all_data');
    
end


%% Analyze Data
SR = (1/3600);
NFFT = 256;
NUM_STATIONS   = size(all_data, 2);
mean_pressures = zeros( NUM_STATIONS, 1);
var_pressures  = zeros( NUM_STATIONS, 1);
fft_pressures  = zeros( NUM_STATIONS, NFFT );

% aaaaand analyze...
changes = [];

for s=1:NUM_STATIONS
    pressure = all_data{s}(:,2);
    mean_pressures(s) = mean( double(pressure) );
    var_pressures(s) = var( double(pressure) );
    fft_pressures(s,:) = abs( fft( double(pressure) - mean(double(pressure)), NFFT )');
   
    % pressure changes in an hour?
    if min(pressure) > 0
        changes = [changes; diff(pressure)];
    end
    
end

%% Plot Distribution
cfigure(14,8);
[centers, prob] = calculatePdf( mean_pressures(mean_pressures > 50), 70 );
plot(centers, prob, 'o-b', 'LineWidth',2);
grid on;
xlabel('Pressure (hPa)', 'FontSize',12);
ylabel('Probability','FontSize',12);
xlim([800 1050]);
saveplot('output/usPressureDistributuion');

%% Plot Spectra
cfigure(14,8);
xvals = (24*3600)*(SR/2)*(1:(NFFT/2))./(NFFT/2); % (1/day)
yvals = fft_pressures(:,1:(NFFT/2));
good_idxs = find(mean(yvals,2) < 200);
yvals = yvals(good_idxs,:);

mean_spectra = mean(yvals);
perc99_spectra = prctile(yvals, 99);
plot(xvals, mean_spectra, 'o-b', 'LineWidth',2);
hold on;
plot(xvals, perc99_spectra, 's-m', 'LineWidth',2);
grid on;
xlabel('Frequency (day^{-1})', 'FontSize',12);
ylabel('Magnitude','FontSize',12);
legend('Mean Pressure Spectra', '99th Percentile Spectra');
xlim([0 3]);
ylim([0 2000]);
saveplot('output/usPressureSpectra');

%% print variance within an hour
mean(changes)
prctile(changes,99)
max(changes)









