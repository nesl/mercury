%% Get test cases

testdir = '../../Data/SimTestCases/';
all_files = dir(testdir);
test_files = {};
for i=1:length(all_files)
    fname = all_files(i).name;
    if isempty( regexp(fname, 'SIM') )
        continue;
    end
    test_files = [test_files; fname];
end


%% choose a lucky case as ground truth and compare with all the other ones

numCorrect = 0;

allRanking = size( length(test_files), 1 );

for luckyIdx = 1:length(test_files)

    tfile = test_files{luckyIdx};
    loaded = load([testdir tfile]);
    testcase = loaded.obj;
    % sensor data
    sensor_data = SensorDataSim(testcase.sim_elevations, ...
        testcase.sim_turns, testcase.sim_gps);
    elev_from_baro = sensor_data.getElevationTimeWindow();
    elev_from_baro = elev_from_baro(:,2);

    % 1         x10
    % 1->0.5    x20
    % 0.5->0.7  x30
    % 0.7->0    x5
    % 0         x20
    % 0->0.1    x5
    % 0.1->0.8  x20
    % 0.8->1    x50
    % 1->0.9    x30
    % 0.9->0.95 x20
    % 0.95->0.7 x30
    % 0.7->1    x35

    speed    = [0.9  0.9  0.5  0.7  0   0  0.1  0.3  0.95  0.6  0.95  0.7  0.9];
    interval = [10   20   30   5    20  5  20   50   30    20   30    10   40];

    speedVector = [];
    for i = 1:(length(speed)-1)
        speedVector = [speedVector linspace(speed(i), speed(i+1), interval(i))];
    end
    speedVector = [speedVector repmat( speed(end), 1, interval(end) ) ];

    loc = 1;
    time = 1;
    new_elev_from_baro = [];
    while loc < length(elev_from_baro)
        left = floor(loc);
        ratio = loc - left;
        d = elev_from_baro(left+1) - elev_from_baro(left);
        value = elev_from_baro(left) + d * ratio;
        new_elev_from_baro = [new_elev_from_baro value];
        loc = loc + speedVector(time);
        [time  speedVector(time)];
        time = time + 1;
        if time > length(speedVector)
            time = 1;
        end
    end

    %{
    map_data = MapData(testcase.mapFilePath{1}, testcase.mapDataDownSampling);
    elev_from_seg = map_data.getPathElev( testcase.sim_path );

    figure
    plot(new_elev, 'LineWidth', 2)
    figure
    plot(elev_from_seg, 'r', 'LineWidth', 2)

    return
    %}

    load allSimGndElev.mat

    dtwScore = zeros( length(test_files), 2 );
    for tidx = 1:length(test_files)
    %for tidx = 1:10
        tfile = test_files{tidx};

        % solve this test case w/ greedy solver
        loaded = load([testdir tfile]);
        testcase = loaded.obj;

        % map data
        %map_data = MapData(testcase.mapFilePath{1}, testcase.mapDataDownSampling);
        %elev_from_seg = map_data.getPathElev( testcase.sim_path );

        [scoreSeg, ~, ~] = dtw_basic(elev_from_seg{tidx}, new_elev_from_baro, @(x) (x.^2), @(x) inf);

        dtwScore(tidx, :) = [tidx, scoreSeg(end)];
        %fprintf('%d is done\n', tidx);
    end
    
    [~, order] = sort(dtwScore(:,2));
    if order(1) == luckyIdx
        numCorrect = numCorrect + 1;
    end
    allRanking(luckyIdx) = find(order == luckyIdx);
    
    %tmp = dtwScore(:,2);
    %tmp = 
    
    fprintf('Num correct=%d/%d (ratio=%f)\n', numCorrect, luckyIdx, numCorrect / luckyIdx);
end




return % prevent silly things
save dtwScore

%% post processing

load dtwScore
load allSimGndElev.mat

sortedDtw = sortrows(dtwScore(1:540,:), 2);
idx = ~isinf( sortedDtw(:,2) ) & sortedDtw(:,2) ~= 0;
sortedDtw = sortedDtw(idx, :);

figure
plot(elev_from_baro, 'r', 'LineWidth', 2)

for tidx = sortedDtw(1:5, 1)'
    tfile = test_files{tidx};
    
    % solve this test case w/ greedy solver
    loaded = load([testdir tfile]);
    testcase = loaded.obj;
    
    % map data
    %map_data = MapData(testcase.mapFilePath{1}, testcase.mapDataDownSampling);
    %elev_from_seg = map_data.getPathElev( testcase.sim_path );
    
    fprintf('plot %d done\n', tidx);
    figure
    plot(elev_from_seg{tidx}, 'b', 'LineWidth', 2)
    xlabel(['tidx: ' num2str(tidx) 'score: ' num2str(dtwScore(tidx, 2)) ])
end



%% calculate map scope

mgr = MapManager('../../Data/EleSegmentSets/');
map_size = 6;
map_downsample = 1;
map_ids = mgr.getValidMapIds(map_size);

allLength = zeros(0, 2);

for midx=1:26
%for midx=2
    map_id = map_ids(midx);
    map_data = mgr.getMapDataObject(map_id, map_size, 1);  % so that's why METERS_PER_GPS is 10
    length = map_data.getTotalDistanceOfAllSegments();
    allLength(end+1, 1:2) = [map_id length];
end