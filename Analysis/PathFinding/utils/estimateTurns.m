function [turns] = estimateTurns(accRaw, gyroRaw)
% [turn_angles] = estimateTurns(accRaw, gyroRaw)

%% Get Sampling Rates
SR_acc = mean(1./diff(accRaw(:,1)));
SR_gyro = mean(1./diff(gyroRaw(:,1)));

%% Detect the gravity vector using accelerometer
% first filter accel a lot
acc_fc = (1/5); % Hz
[b,a] = butter(2, acc_fc/(SR_acc/2));
accFilt = [accRaw(:,1) filtfilt(b,a,accRaw(:,2:4))];
norms = sqrt(sum(abs(accFilt(:,2:4)).^2,2));
grav_vec = [accFilt(:,1)...
    accFilt(:,2:4)./repmat(norms,1,3)];


%% Extract Rotations about the Normal Vector
% remove sharp spikes w/ median filter
gyro_medfilt = [gyroRaw(:,1) medfilt1(gyroRaw(:,2:4), 20)];
% filter the gyro a little bit with a LPF
gyro_fc = (1/2); % Hz
[b,a] = butter(1, gyro_fc/(SR_gyro/2));
gyroFilt = [gyro_medfilt(:,1) filtfilt(b,a,gyro_medfilt(:,2:4))];
% extract only rotations about normal axis
%     (positive is CCW, negative is CW)
grav_vec_resize = imresize(grav_vec, size(gyroFilt));
normalRotations = [gyroFilt(:,1) sum(gyroFilt(:,2:4).*grav_vec_resize(:,2:4), 2)];

%% Turn Detection
% windowed, bounded integration
TURN_THRESH = 10; % degrees
turns = [normalRotations(:,1) zeros(size(normalRotations,1),1)];
win_size = 50*5; % 5 sec (integral window time)
backoff = 50*4; % 4 sec (temporal backoff)
turn_events = [];

last_time = turns(1,1);

% windowed integration (summation)
for i=1:size(gyroRaw,1) %time
    w_idx = i-win_size; % previous history (now - window)
    if w_idx <= 0
        w_idx = 1;
    end
    % integrate
    turns(i,2) = sum(gyroFilt(w_idx:i,2));
end

SCALE = 100;
turns(:,2) = turns(:,2)*SCALE;

end

