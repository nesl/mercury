% This script generates test cases for simulation. The test case is stored
% in a variable structure and then stored as a mat file. Because of this,
% the structure must be carefully designed.

%% Housekeeping
clear all; clc; close all;

%% generation

% pseudo code:
% choose a map.
map_manager = MapManager();
map_data = map_manager.getMapDataObject(1, 3, 1);  % see test_on_map_data.m to see examples
% you can use map_data to generate random path, see the function in the
% class. Note the path is truely random walk, you might want to generate
% the paths look more realistic. I can help you on this part.

% then generate speed of time

% based on the path extract turn, and we already have the function from
% MapData

% fill in the the necessary attributes in the TestCase, see the example
% below

% I also provide testingScript_BoDriving.m for testing sample

% I need to end up here as my friend just called me

return;

%% case generated based on real roads

% sample
testCase = TestCase();
testCase.mapFilePath = '../../Data/EleSegmentSets/ucla_west/';
testCase.sensorFilePath = '../../Data/rawData/baro_n501_20141208_211251.baro.csv';
testCase.startAbsTime = 1418102835;
testCase.stopAbsTime = 1418103643;
testCase.useFakeTurnEvent = 0;
testCase.sensorWindowSize = 5;
testCase.mapDataDownSampling = 1;
caseName = '[Sample]_WeyburnWalking';
fprintf('''%s''\n', caseName);
testCase.save(caseName);

% bo-jhang driving
info = { 'baro_n503_20150110_143636',  1420929399,  1420931703,  'ucla_5x5';
         'baro_n503_20150110_155834',  1420931703,  1420935362,  'ucla_5x5';
         'baro_n503_20150110_161641',  1420935404,  1420938234,  'ucla_5x5';
         'baro_n503_20150111_091333',  1420998472,  1420999765,  'Los_Angeles_6x6';
         'baro_n503_20150111_091333',  1421001938,  1421003215,  'ucla_5x5';
};
info(:,1) = strcat('../../Data/rawData/', info(:,1));
info(:,1) = strcat(info(:,1), '.baro.csv');
info(:,4) = strcat('../../Data/EleSegmentSets/', info(:,4));
info(:,4) = strcat(info(:,4), '.map');

for i = 1:size(info, 1)
    st = info{i, 2}; % start time
    cnt = 1;
    while st + 600 < info{i, 3}
        testCase = TestCase();
        testCase.mapFilePath = info{i, 4};
        testCase.sensorFilePath = info{i, 1};
        testCase.startAbsTime = st;
        testCase.stopAbsTime = st + 600;
        testCase.useFakeTurnEvent = 0;
        testCase.sensorWindowSize = 1.0;
        testCase.mapDataDownSampling = 2;
        
        caseName = sprintf('[Bo-Driving]_%d-%d', i, cnt);
        fprintf('''%s''\n', caseName);
        testCase.save(caseName);
        
        st = st + 300;
        cnt = cnt + 1;
    end
end

%% simple explanation how it works: generation
a = TestCase()
a.mapFilePath = 'from/empty/to/something';
a
a.save('33333333333')

%% simple explanation how it works: load
b = TestCase('33333333333')