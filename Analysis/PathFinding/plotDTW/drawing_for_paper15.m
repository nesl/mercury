addpath('../utils');
addpath('../classes');

rootDir = '~/Dropbox/MercuryWriting/figures/';


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

%%

clf


cfigure(14,8);
hold on
%a=axes('units','normalized','position',[.1 .25 .8 .7],'xlim',[0 144],'xtick',0:12:144)
%xlabel(a,'Inches')
plot((1:length(mapElev)) * 8 / 1000, mapElev - mapElev(1), 'b--','LineWidth',2);
plot(sensorElev(1,1), sensorElev(1,2), 'r', 'LineWidth', 2);
ylim([-70 20]);
xlabel('Traveling distance (Km, bottom) and time (Sec, top)', 'FontSize', 12);
ylabel('Shifted elevation (meter)', 'FontSize', 12);
h_legend = legend({'Map', 'Barometer'});
set(h_legend, 'FontSize', 12);
grid on;

ax1 = gca; % current axes
ax1_pos = get(ax1,'Position'); % position of first axes

ax2 = axes('Position',ax1_pos,...
    'XAxisLocation','top',...
    'YAxisLocation','right',...
    'Color','none');

%b=axes('units','normalized','position',[.1 .1 .8 0.000001],'xlim',[0 12],'color','none')
%xlabel(b,'Feet')
line(sensorElev(:,1), sensorElev(:,2) - mapElev(1), 'Color', 'r', 'Parent', ax2, 'LineWidth',2)

ylim([-70 20]);
set(gca, 'YTickLabel', {})
%xlabel('Traveling time (Sec)', 'FontSize', 12);

%plot((1:length(mapElev)) * 8, mapElev - mapElev(1), 'r');
saveplot([rootDir 'elev_dtw_1']);

return
pflag = 1;
dtw(sensorElev(:,2),mapElev,pflag,[1 0 0]);
