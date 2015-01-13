%% read files
st = 1418102795;
et = 1418103617;

[baroRaw, accRaw, gyroRaw, magRaw, gpsRaw, gpsEle] = read('n501_20141208_211251', st, et);
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

figure
plot(baroRaw(:,2))

%csvwrite('../Data/eleSegments/case1.csv', baroRaw)
dlmwrite('../Data/eleSegments/test_case/case1_baro_gnd.csv', baroRaw, 'delimiter', ',', 'precision', 9);