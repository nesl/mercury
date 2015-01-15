% %% Housekeeping
% clc; close all; clear all;
% addpaths;
% 
% %% Load Candidate Sensory Data
% [baroRaw, accRaw, gyroRaw, magRaw, gpsRaw, gpsSpeed] = ...
%     parsesensors('n501_20150108_221546');


%% Get Sampling Rates
SR_acc = mean(1./diff(accRaw(:,1)));
SR_gyro = mean(1./diff(gyroRaw(:,1)));
SR_baro = mean(1./diff(baroRaw(:,1)));


%% Detect the gravity vector using accelerometer
% first filter accel a lot
acc_fc = (1/5); % Hz
[b,a] = butter(2, acc_fc/(SR_acc/2));
accFilt = [accRaw(:,1) filtfilt(b,a,accRaw(:,2:4))];
norms = sqrt(sum(abs(accFilt(:,2:4)).^2,2));
grav_vec = [accFilt(:,1)...
    accFilt(:,2:4)./repmat(norms,1,3)];

%% Calculate windowed accelerometer variance
% start with empty variance array
variance = [];
% window (seconds * number of 50 Hz samples)
win = 5*50; % 3 second window, 50 samp/sec

for i=1:win:(min([size(accRaw,1) size(gyroRaw,1)]) -win)
    % calculate windowed variance of accel on x,y,z axes
    var_all = [var(sum(accRaw(i:i+win,2))) var((accRaw(i:i+win,3))) var((accRaw(i:i+win,4)))];
    % project to just the vertical axis (normal axis)
    var_normal = grav_vec(i,2:4)*var_all';
    % append to variance matrix;
    variance = [variance;
        accRaw(i,1) var_normal
        ];
end

% ensure minimum variance value is around 0
variance(:,2) = variance(:,2) - min(medfilt1(variance(:,2),100));

% low pass filter on variance (zero phase butterworth)
fc = 0.1;
SR = win/50; % window size / 50 Hz
fNorm =  fc / (SR / 2);
[b,a] = butter(2, fNorm, 'low');
variance_filt = [variance(:,1) filtfilt(b,a,variance(:,2))];

%% Resize Acc. Variance Size to Match GPS Estimate
variance_filt_resize = [gpsSpeed(:,1) ...
    imresize(variance_filt(:,2), [size(gpsSpeed,1) 1])];

%% Max speed and accel.
max_speed = 28; % mps (62 mph)
max_accel = 0;

%% Estimate speed
speed_est = min(max_speed, 10*variance_filt_resize(:,2));

%% Compare GPS Speed to Accelerometer Variance
plot(gpsSpeed(:,2));
hold on;
plot(speed_est, 'm', 'LineWidth',2);
grid on;
legend('GPS Speed','Variance');













