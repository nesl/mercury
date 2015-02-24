%% Inputs:
mapfile =    '../../Data/EleSegmentSets/ucla_3x3/';
%sensorfile = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';

add_paths

disp 'Getting map data. . .'
%% Create MapData object
map_data = MapData(mapfile);

%% Random Walk Parameters
path_length = 10000; % fixed length of walk (# of elevation points)
window_size = 160; % compute variance over 'window_size' points
window_step = 10;
flag_allow_go_back = 0; % if 'allow_go_back', you can return to a node by an intermediary.

path = map_data.getRandomWalk(-1, path_length, flag_allow_go_back);
path = map_data.getPathElev(path);

windows = 1:window_step:(numel(path) - window_size);
varvec = zeros(1,numel(windows));
index = 1;
for pane=windows
    varvec(index) = var(path(pane:pane+window_size));
    index = index + 1;
end

figure;
subplot(1,2,1);
plot(varvec,'r');
subplot(1,2,2);
cdfplot(varvec);