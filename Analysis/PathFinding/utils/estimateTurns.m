function [turn_angles, turns] = estimateTurns(accRaw, gyroRaw)  % TODO: check the correctness of this file
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
TURN_THRESH = 35; % degrees
turns = [normalRotations(:,1) zeros(size(normalRotations,1),1)];
win_size = round( SR_acc*3 ); % 3 sec (integral window time)
backoff = round( SR_gyro*5 ); % 5 sec (temporal backoff)
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

% -------- turn detection ----------
i = 1;
while i < size(turns,1)
    % skip over everything under the threshold
    while abs(turns(i,2)) < TURN_THRESH && i < size(turns,1)
        if i >= size(turns,1)
            break;
        end
        i = i+1;
    end
    
    % once the threshold is passed, find the next peak
    while abs(turns(i,2)) > abs(turns(i-1,2)) && i < size(turns,1)
        if i >= size(turns,1)
            break;
        end
        i = i+1;
    end
    
    % we found a peak! calculate time since last event
    dT = turns(i,1)-last_time;
    % recycle last_time variable for the next event
    last_time = turns(i,1);
    
    
    % append to event array
    turn_events = [turn_events;
        turns(i,1) turns(i,2)
        ];
    
    % backoff
    for j=1:backoff
        if i >= size(turns,1)
            break;
        end
        i = i+1;
    end
    
    % and ride it back down
    while abs(turns(i,2)) < abs(turns(i-1,2)) && i < size(turns,1)
        if i >= size(turns,1)
            break;
        end
        i = i+1;
    end
end

% predict turn angles
turn_angles = turn_events;
turn_angles(:,2) = turn_angles(:,2)*0.8; % fudge factor to estimate angle

% plot
%{
cfigure(30,12);
stem(turn_angles(:,1)/1e9 - turn_angles(1,1)/1e9, turn_angles(:,2),'or','LineWidth',2);
xlabel('Time (sec)','FontSize',12);
ylabel('Turn angle (degrees)','FontSize',12);
grid on;
hold on;
plot(turns(:,1)/1e9 - turns(1,1)/1e9, turns(:,2),'sb');
%}

end

