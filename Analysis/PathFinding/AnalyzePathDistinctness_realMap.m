%% Bo solver, dp5L
clear all; clc; close all;
add_paths

caseNames = {
%'[Sample]_WeyburnWalking'
'[Bo-Driving]_1-1_size4'
'[Bo-Driving]_1-2_size4'
'[Bo-Driving]_1-3_size4'
'[Bo-Driving]_1-4_size4'
'[Bo-Driving]_1-5_size4'
'[Bo-Driving]_1-6_size4'
'[Bo-Driving]_2-1_size4'
'[Bo-Driving]_2-2_size4'
'[Bo-Driving]_3-1_size4'
'[Bo-Driving]_3-2_size4'
'[Bo-Driving]_3-3_size4'
'[Bo-Driving]_3-4_size4'
'[Bo-Driving]_3-5_size4'
'[Bo-Driving]_3-6_size4'
'[Bo-Driving]_3-7_size4'
'[Bo-Driving]_3-8_size4'
'[Bo-Driving]_5-1_size4'
'[Bo-Driving]_5-2_size4'
'[Bo-Driving]_5-3_size4'
'[Bo-Driving]_6-1_size4'
'[Bo-Driving]_6-2_size4'
'[Bo-Driving]_7-1_size4'
'[Bo-Driving]_7-2_size4'
'[Bo-Driving]_7-3_size4'
'[Bo-Driving]_7-4_size4'
'[Bo-Driving]_7-5_size4'
'[Bo-Driving]_7-6_size4'
'[Bo-Driving]_7-7_size4'
'[Bo-Driving]_7-8_size4'
};
%%

elev_from_baro = cell(size(caseNames, 1), 1);
elev_from_seg = cell(size(caseNames, 1), 1);

numCases = size(caseNames, 1);

for i = 1:numCases
%for i = 1:2
    %fprintf('====== case %d: %s ======\n', i, caseNames{i});
    testCase = TestCase(caseNames{i});
    sensor_data = SensorData(testCase.sensorFilePath);
    sensor_data.setAbsoluteSegment(testCase.startAbsTime, testCase.stopAbsTime);
    %sensor_data.setWindowSize(testCase.sensorWindowSize);
    sensor_data.setWindowSize(0.5);
    
    map_data = MapData(testCase.mapFilePath, testCase.mapDataDownSampling);
    gps = sensor_data.getGps();
    tmp = map_data.rawGpsAlignment( gps(:,2:3) );
    elev_from_seg{i} = tmp(:,3);
    %tmp = sensor_data.getGps2Ele();
    %elev_from_seg{i} = tmp(:,4);
    
    tmp = sensor_data.getElevationTimeWindow();
    elev_from_baro{i} = -tmp(:,2);
end



%%
numCorrect = 0;

for i = 1:numCases
%for i = 2:2
    scores = inf(numCases, 1);
    %for j = 1:2
    for j = 1:numCases
        offset = elev_from_baro{j}(1) - elev_from_seg{i}(1);
        minScore = inf;
        for elevShift = -3:3
            [s, ~, ~] = dtw_basic(elev_from_seg{i}, elev_from_baro{j} - offset + elevShift, @(x) (x.^2), @(x) inf);
            minScore = min(minScore, s(end));
        end
        scores(j) = minScore;
        fprintf('progress %d-%d\n', i, j);
    end
    [~, order] = sort(scores);
    
    if order(1) == i
        numCorrect = numCorrect + 1;
    end
    
    scores
    fprintf('Num correct=%d/%d (ratio=%f)\n', numCorrect, i, numCorrect / i);
end


