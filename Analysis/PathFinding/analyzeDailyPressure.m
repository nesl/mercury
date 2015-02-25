%% Housekeeping
clc; close all; clear all;

%% Load barometer data
data = csvread('../../Data/rawData/baro_n501_20150220_092148.baro.csv');

%% Plot
dT = mean( diff(data(:,1))*1e-9 );
downsample = 40000;

samples = data(1:downsample:end, 2);
samples = samples - samples(1);

times = ( dT*downsample )*( 0:( length(samples) - 1) );
times = times./3600; % hours

cfigure(14,8);
plot(times, samples, 'b-o','MarkerSize',5);
xlabel('Time (hours)', 'FontSize',14);
ylabel('Change in Pressure (hPa)', 'FontSize', 14);
grid on;

%% how much change per hour?
hourly = zeros(size(samples));
idx_hour = round( 3600/dT/downsample );
for i=1:length(samples)
    idx = max( i - idx_hour, 1 );
    hourly(i) = samples(i) - samples(idx);
end

hold on;
plot(times, hourly, '--^r','MarkerSize',5);
legend('Pressure Change since t=0', 'Hourly Pressure Change','Location','SW');
saveplot('figs/dailypressure');