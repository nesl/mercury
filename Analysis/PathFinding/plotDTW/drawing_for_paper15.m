addpath('../utils');
addpath('../classes');

% sensor case 3
sensorfile = '../../../Data/rawData/baro_n503_20150111_091333.baro.csv';
sensor_data = SensorData(sensorfile);
sensor_data.setSeaPressure(1018.3);  % correct coefficient hand-tuned
sensor_data.setPressureScalar(-8.4);
sensor_data.setAbsoluteSegment(1421002543, 1421002988);
sensor_data.setWindowSize(0.5);  % finer case: 0.5

mapfile = '../../../Data/EleSegmentSets/ucla_small.map';
map_data = MapData(mapfile, 1);  % finer case: 1


estimatedAnswer = [
     1    20
    10    22
    61    26
    75   164
    76   240
   101   253
   104   293
   114   298
   151   301
   156   323
   159   328
   168   332
   188   338
   221   317
   230   315
   231   120
   236   307
   243   303
   255   291
   262   275
   331   219
   347   230
   359   213
   398   204
   443   207
];

sensorElev = sensor_data.getElevationTimeWindow();
mapElev = map_data.getPathElev(estimatedAnswer(:,2));

close all
clf
hold on

plot(1:length(sensorElev), sensorElev(:,2) - mapElev(1), 'b');
plot(1:length(mapElev), mapElev - mapElev(1), 'r');

pflag = 1;
dtw(sensorElev(:,2),mapElev,pflag,[1 0 0]);
