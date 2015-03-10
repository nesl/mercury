%% Housekeeping
clc; close all; clear all;
addpath('../PathFinding/utils');
addpath('../PathFinding/classes');

%% Event Defs
EVT_WINDOWN = 0;
EVT_WINUP = 1;
EVT_ACON = 2;
EVT_ACOFF = 3;
EVT_DOORCLOSE = 4;
EVT_DOOROPEN = 5;

% how long should the window be?
wlen = 100;

baros_dooropen = [];
baros_doorclose = [];
baros_acon = [];
baros_acoff = [];
baros_windown = [];
baros_winup = [];
times = linspace(-wlen/30,wlen/30,2*wlen + 1);

% load door open/close data
fpath = '../../Data/rawData/baro_n501_20150310_021950.baro.csv';
baro = csvread(fpath);
fpath = '../../Data/rawData/baro_n501_20150310_021950.event.csv';
events = csvread(fpath);
for e=1:size(events,1)
    t = events(e,1)/1e3;
    bt = baro(:,1)/1e9;
    bidx = find(bt > t, 1, 'first');
    bseg = baro((bidx-wlen):(bidx+wlen), 2);
    
    if events(e,2) == EVT_DOOROPEN
        baros_dooropen = [baros_dooropen; bseg'];
    end
    
    if events(e,2) == EVT_DOORCLOSE
        baros_doorclose = [baros_doorclose; bseg'];
    end
end

% load ac on/off
fpath = '../../Data/rawData/baro_n501_20150310_022431.baro.csv';
baro = csvread(fpath);
fpath = '../../Data/rawData/baro_n501_20150310_022431.event.csv';
events = csvread(fpath);
for e=1:size(events,1)
    t = events(e,1)/1e3;
    bt = baro(:,1)/1e9;
    bidx = find(bt > t, 1, 'first');
    bseg = baro((bidx-wlen):(bidx+wlen), 2);
    
    if events(e,2) == EVT_ACON
        baros_acon = [baros_acon; bseg'];
    end
    
    if events(e,2) == EVT_ACOFF
        baros_acoff = [baros_acoff; bseg'];
    end
end

% load window open/close
fpath = '../../Data/rawData/baro_n501_20150310_022618.baro.csv';
baro = csvread(fpath);
fpath = '../../Data/rawData/baro_n501_20150310_022618.event.csv';
events = csvread(fpath);
for e=1:size(events,1)
    t = events(e,1)/1e3;
    bt = baro(:,1)/1e9;
    bidx = find(bt > t, 1, 'first');
    bseg = baro((bidx-wlen):(bidx+wlen), 2);
    
    if events(e,2) == EVT_WINUP
        baros_winup = [baros_winup; bseg'];
    end
    
    if events(e,2) == EVT_WINDOWN
        baros_windown = [baros_windown; bseg'];
    end
end

%% Plot
cfigure(14,8);
skip = 5;

tskip = times(1:skip:end);
msize = 6;


% doors
avg = mean(baros_dooropen);
avg = avg(1:skip:end);
plot(tskip, avg - mean(avg(1:(wlen/skip-10))), 'bo-','LineWidth',1,'MarkerSize',msize);
hold on;
avg = mean(baros_doorclose);
avg = avg(1:skip:end);
plot(tskip, avg - mean(avg(1:(wlen/skip-10))), 'bo-','LineWidth',1,'MarkerSize',msize, 'MarkerFaceColor','b');

% ac
avg = mean(baros_acon);
avg = avg(1:skip:end);
plot(tskip, avg - mean(avg(1:(wlen/skip-10))), 'ks-','LineWidth',1,'MarkerSize',msize);
avg = mean(baros_acoff);
avg = avg(1:skip:end);
plot(tskip, avg - mean(avg(1:(wlen/skip-10))), 'ks-','LineWidth',1,'MarkerSize',msize,'MarkerFaceColor','k');

% win
avg = mean(baros_winup);
avg = avg(1:skip:end);
plot(tskip, avg - mean(avg(1:(wlen/skip-10))), 'r^-','LineWidth',1,'MarkerSize',msize);
avg = mean(baros_windown);
avg = avg(1:skip:end);
plot(tskip, avg - mean(avg(1:(wlen/skip-10))), 'r^-','LineWidth',1,'MarkerSize',msize,'MarkerFaceColor','r');

grid on;
legend('Door Open', 'Door Close', 'AC On', 'AC Off', 'Window Up', 'Window Down',...
    'Location', 'SW');

xlabel('Time From Event (sec)','FontSize',12);
ylabel('Pressure Change (hPa)','FontSize',12);

saveplot('figs/pressure_changes');
