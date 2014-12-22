%baro_n501_20141129_034845.*.csv
% this file only contains less than 5 minutes of data, and it records
% trajectory from Clark's home (Vateran 069) to Bo's home

%% read files
[baroRaw, accRaw, gyroRaw, magRaw, gpsRaw] = read('n501_20141129_034845');
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

%% plot gps 2D
%subRaw = gpsRaw( gpsRaw(

gpsGps = gpsRaw( gpsRaw(:,7) == 0 , : );
gpsNet = gpsRaw( gpsRaw(:,7) == 1 , : );
clf
hold on
plot(gpsGps(:,3), gpsGps(:,2), 'r-o');
plot(gpsNet(:,3), gpsNet(:,2), 'b-*');
legend('GPS', 'network');
axis equal 

%% plot gps 2D (rescale)
%subRaw = gpsRaw( gpsRaw(
ratio = 1.37;

gpsGps = gpsRaw( gpsRaw(:,7) == 0 , : );
gpsNet = gpsRaw( gpsRaw(:,7) == 1 , : );
clf
hold on
plot(gpsGps(:,3) / ratio, gpsGps(:,2), 'r-o');
plot(gpsNet(:,3) / ratio, gpsNet(:,2), 'b-*');
legend('GPS', 'network');
axis equal 

%% plot gps 3D
subRaw = gpsRaw( gpsRaw(:,1) < 3600 , : );
gpsGps = gpsRaw( subRaw(:,7) == 0 , : );
gpsNet = gpsRaw( subRaw(:,7) == 1 , : );
clf
hold on
plot3(gpsGps(:,3), gpsGps(:,2), gpsGps(:,4), 'rv');
plot3(gpsNet(:,3), gpsNet(:,2), gpsNet(:,4), 'b*');
legend('GPS', 'network');
grid on
%axis euqal

%% plot baro (all)
clf
plot(baroRaw(:,1), baroRaw(:,2))

%% plot baro (segments)
%{
% borrow from case_1128h12.m, haven't changed
clf
subplot(3, 1, 1)
ind = 600 < baroRaw(:,1) & baroRaw(:,1) < 1600;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/28 12pm, bos home to NESL')

subplot(3, 1, 2)
ind = 3600 < baroRaw(:,1) & baroRaw(:,1) < 18000;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/28 1pm to 5pm, at NESL on my desk')

subplot(3, 1, 3)
ind = 26800 < baroRaw(:,1) & baroRaw(:,1) < 27900;
plot(baroRaw(ind, 1), baroRaw(ind, 2))
xlabel('2014/11/28 7:30pm, walk with Takamasa from bos home to NESL')
%}
%% compare height baro
%{
% borrow from case_1128h12.m, haven't changed
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
