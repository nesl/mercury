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

return;

%% separate analysis
data = csvread('../../Data/rawData/baro_n501_20150220_092148.baro.csv');
%%
data(:,1) = ceil((data(:,1) - data(1,1)) / 1e9 + 1e-6);
numSec = max(data(:,1))
tsum = zeros(1, numSec);
tcnt = zeros(1, numSec);
for i = 1:size(data)
    t = data(i,1);
    tsum(t) = tsum(t) + data(i,2);
    tcnt(t) = tcnt(t) + 1;
end
baroSmooth = tsum ./ tcnt;


baroSmooth = baroSmooth( tcnt >= 15 ); 
baroSmooth = baroSmooth( baroSmooth < inf & baroSmooth > 900);
numSec = numel(baroSmooth);
%{
numMin = floor(numel(baroSmooth) / 60);
baroMin = zeros(1, numMin);
baroMax = zeros(1, numMin);
for i = 1:numMin
    s = i*60 - 59;
    e = i*60;
    tmpSorted = sort(baroSmooth(s:e));
    baroMin(i) = tmpSorted(3);
    baroMax(i) = tmpSorted(58);
end
idx = [2267 find(baroMin < 900)];
baroMin(idx) = baroMin(idx-1);
baroMax(idx) = baroMax(idx-1);
clf
hold on
plot(baroMin);
plot(baroMax, 'r');
%}

%{
clf
hold on
finalRes = [];
for windowSize = 600
    numBin = floor(numSec / windowSize)
    res = zeros(1, numBin);
    for i = 1:numBin
        idx = ((i-1)*windowSize+1):(i*windowSize);
        res(i) = std(baroSmooth(idx));
    end
    sortedRes = sort(res)
    finalRes = [finalRes; [windowSize sortedRes(ceil(numBin * 0.95))]];
end

plot(finalRes(:,1), finalRes(:,2), 'b');
%}

rootDir = '~/Dropbox/MercuryWriting/figures/';


% generate first figure, 72-hour data

%%
% 69->72
numSamples = 998;
idx = floor(linspace(3,numSec-100, numSamples));
y = baroSmooth(idx);
x = linspace(0,69, numSamples)

cfigure(9,7);
plot(x, y, 'b-','MarkerSize',5);
xlabel('Time (hours)', 'FontSize',12);
ylabel('Pressure (hPa)', 'FontSize', 12);
xlim([0, 70])
grid on;
saveplot([rootDir 'pressure_analysis_3days']);

close all

numSamples = 900;
idx = floor(linspace(2,3600, numSamples));
y = baroSmooth(idx);
x = linspace(0,60, numSamples)
cfigure(9,7);
plot(x, y, 'b-','MarkerSize',5);
xlabel('Time (minutes)', 'FontSize', 12);
ylabel('Pressure (hPa)', 'FontSize', 12);
xlim([0, 60])
grid on;
set(gca, 'YTick', [992.6 992.7 992.8 992.9]);
saveplot([rootDir 'pressure_analysis_1hour']);

close all

%%
windowSize = 600; % second
numBin = floor(numSec / windowSize)
res = zeros(1, numBin);
for i = 1:numBin
    idx = ((i-1)*windowSize+1):(i*windowSize);
    res(i) = std(baroSmooth(idx));
end
sortedRes = sort(res);
x = sortedRes(1:end-3);
y = linspace(0, 1, length(x));
plot(x, y);
xlabel('Standard deviration (hPa)', 'FontSize', 12);
ylabel('CDF', 'FontSize', 12);
set(gca, 'XTick', 0:0.02:0.1);
grid on;

saveplot([rootDir 'pressure_analysis_10min_std']);