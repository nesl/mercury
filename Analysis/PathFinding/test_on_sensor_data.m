clc; clf; clear all;

%sensorfile = '../../Data/rawData/baro_n501_20150108_221546.gps.csv';
sensorfile = '../../Data/rawData/baro_n503_20150110_143636.gps.csv';
sensor_data = SensorData(sensorfile);
sensor_data.setSeaPressure(1020);
sensor_data.setPressureScalar(-8.1);
%sensor_data.setAbsoluteSegment(1418102835, 1418103643);

baro = sensor_data.getBaro();
gpsele = sensor_data.getGps2Ele();
rawBaro = sensor_data.raw_baro;
rawGpsele = sensor_data.raw_gpsele;

%%
minBaroTime = rawBaro(1, 1)
maxBaroTime = rawBaro(end, 1)
minGpsTime = rawGpsele(1, 1)
maxGpsTime = rawGpsele(end, 1)
startTime = sensor_data.segment_start;
stopTime = sensor_data.segment_stop;
sensor_data.motion_offset
sensor_data.gps_offset

baroLength = maxBaroTime - minBaroTime
gpsLength = maxGpsTime - minGpsTime
endBaroGpsDelta = baroLength - gpsLength

%{
clf
hold on
plot(minBaroTime, minBaroTime, 'v');
plot(maxBaroTime, maxBaroTime, '^');
plot(startTime, startTime, 'o');
plot(stopTime, stopTime, 's');
%}
sensor_data.plotElevation()