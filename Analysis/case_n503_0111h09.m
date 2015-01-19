%% read files
[baroRaw, accRaw, gyroRaw, magRaw, gpsRaw, gpsEle] = readRaw('n503_20150111_091333');
baroRaw(1,:)
baroRaw(end,:)
accRaw(1,:)
accRaw(end,:)
gyroRaw(1,:)
gyroRaw(end,:)
magRaw(1,:)
magRaw(end,:)
gpsRaw(1,:)
gpsRaw(end,:)
return;

%% test timestamp for all sensors
baroRaw(end, 1) - baroRaw(1, 1)
gpsRaw(end, 1) - gpsRaw(1, 1)
baroRaw(1, 1)
gpsRaw(1, 1)

% conclusion: motion sensor and gps data span the same time interval but
% with different start timestamps.

% from the webplot, it shows:
%    - gps time 1421002543000 to 1421002693000 on Sunset
%    - gps time 1421002693000 to 1421002988000 on Hilgard

% case 2:
stoff = (1421002543000 - gpsRaw(1,1)) / 1e3; % start time offset in second
tint = (1421002988000 - 1421002543000) / 1e3;  % time interval in second
baroSt = baroRaw(1,1) + stoff * 1e9; % desired barometer start timestamp
baroEt = baroRaw(1,1) + (stoff + tint) * 1e9; % desired barometer end timestamp
ind = (baroSt <= baroRaw(:,1) & baroRaw(:,1) <= baroEt);
dataOut = baroRaw(ind,:);
dataOut(:,1) = (dataOut(:,1) - dataOut(1,1)) / 1e9;
dlmwrite('../Data/eleSegments/test_case/case3_baro_query.csv', dataOut, 'delimiter', ',', 'precision', 9);

%% plot gps-ele
clf
plot(gpsEle(:,1), gpsEle(:,4))

%% plot baro (all)
clf
plot(baroRaw(:,2))

%% pile baro to gps-ele
clf
hold on
seaPre = 1019.394;
sca = -7.9736;
%plot(baroRaw(:,1), baroRaw(:,2) * sca + off, 'r');
plot((baroRaw(:,1) - baroRaw(1,1)) / 1e9, (baroRaw(:,2) - seaPre) * sca, 'r-v');
plot((gpsEle(:,1) - gpsEle(1,1)) / 1e3, gpsEle(:,4), 'b.-');
legend({'baro', 'gps-ele'});
xlabel('convert barometer to height and match gps elevation')

%% plot baro (segments)
%{
clf
subplot(3, 3, 1)
ind = 0 < baroRaw(:,1) & baroRaw(:,1) < 900;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/29 2pm, bos home to NESL')

subplot(3, 3, 2)
ind = 2000 < baroRaw(:,1) & baroRaw(:,1) < 20000;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/29 2:40pm to 7:40pm, at NESL on my desk')

subplot(3, 3, 3)
ind = 21500 < baroRaw(:,1) & baroRaw(:,1) < 22800;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/29 8pm, NESL to bos home')

subplot(3, 3, 4)
ind = 24200 < baroRaw(:,1) & baroRaw(:,1) < 24800;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/29 8:52 to 8:57pm, bos to clarks to bos home')

subplot(3, 3, 5)
ind = 78200 < baroRaw(:,1) & baroRaw(:,1) < 78600;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/30 11:49pm, bos home to Indian oven by driving')

subplot(3, 3, 6)
ind = 80000 < baroRaw(:,1) & baroRaw(:,1) < 85000;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/30 12pm, sitting (possibly walking) at Indian oven')

subplot(3, 3, 7)
ind = 80000 < baroRaw(:,1) & baroRaw(:,1) < 85000;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/30 12pm, sitting (possibly walking) at Indian oven')

subplot(3, 3, 8)
ind = 85900 < baroRaw(:,1) & baroRaw(:,1) < 86500;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/30 2pm, Indian oven -> lab by driving')
%}

%% compare height baro
%{
tl = 600;
tu = 1600;

baroa = 999;
barob = 1003;
gpsa = 70;
gpsb = 150;

clf
hold on
ind = 600 < baroRaw(:,1) & baroRaw(:,1) < 1600;
plot(baroRaw(ind, 1), (baroRaw(ind, 2) - baroa) / (barob - baroa) * (gpsb - gpsa) + gpsa, 'ro')
ind = 600 < gpsRaw(:,1) & gpsRaw(:,1) < 1600;
plot(gpsRaw(ind, 1), gpsRaw(ind, 4), 'bx')
legend('baro (remapping)', 'gps altitude');
xlabel('2014/11/28 12pm, bos home to NESL')
%}
