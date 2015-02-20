%% Inputs:
mapfile =    '../../Data/EleSegmentSets/ucla_3x3/';
%sensorfile = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';

disp 'Getting map data. . .'
%% Create MapData object
map_data = MapData(mapfile);

%% Random Walk Parameters
path_length = 1000; % fixed length of walk (# of segments traversed)
window_size = 160; % compute variance over 'window_size' points
window_step = 10;
flag_only_loops = 1; % if 'only_loops', you can only return to a node by an intermediary.

num_nodes = map_data.getNumNodes();
cur_node = round(1 + (num_nodes - 1)*rand(1));
path = [];

disp 'Performing random walk. . .'
for step=1:path_length
    next_nodes = map_data.getNeighbors(cur_node);
    rand_steps = randperm(numel(next_nodes));
    if flag_only_loops
        while (next_nodes(rand_steps(1)) == cur_node)
            rand_steps = rand_steps(2:end);
        end
    end
    prev_node = cur_node;
    cur_node = next_nodes(rand_steps(1));
    path = [path; map_data.getSegElev([prev_node cur_node])];
end

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