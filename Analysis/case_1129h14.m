%% read files
[baroRaw, accRaw, gyroRaw, magRaw, gpsRaw, gpsEle] = read('n501_20141129_140457');
baroRaw = baroRaw(3:end, :);
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
%subRaw = gpsRaw;
subRaw = gpsRaw( 85900 < gpsRaw(:,1) & gpsRaw(:,1) < 86500, : );

gpsGps = subRaw( subRaw(:,7) == 0 , : );
gpsNet = subRaw( subRaw(:,7) == 1 , : );
clf
hold on
plot(gpsGps(:,3), gpsGps(:,2), 'r-o');
plot(gpsNet(:,3), gpsNet(:,2), 'b-*');
text(gpsGps(1,3), gpsGps(1,2), 'Start')
text(gpsGps(end,3), gpsGps(end,2), 'End')
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
%axis euqal

%% plot gps-ele
clf
plot(gpsEle(:,1), gpsEle(:,4))

%% plot baro (all)
clf
plot(baroRaw(:,1), baroRaw(:,2))

%% pile baro to gps-ele
clf
hold on

seaPre = 1013.494; % part 1
sca = -8.2836;
%seaPre = 1016.694; % part 2
%sca = -8.2836;
%seaPre = 1016.394; % part 3
%sca = -8.2836;
plot(baroRaw(:,1), (baroRaw(:,2) - seaPre) * sca, 'r');
plot(gpsEle(:,1), gpsEle(:,4), 'b.-');
legend({'baro', 'gps-ele'});
xlabel('convert barometer to height and match gps elevation')

%% plot baro (segments)
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

%% compare height baro
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


