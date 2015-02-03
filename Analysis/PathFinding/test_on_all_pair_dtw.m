A = rand(1, 5);
B = rand(1, 10);

reA = zeros(10) * NaN;
for i = 1:10
    for j = i:10
        [~, ~, D] = dtw_baro(A, B(i:j));
        reA(i, j) = D(end, end);
    end
end

reB = all_pair_dtw_baro(A, B);

reA
reB

% test reuslt: match

%% real test
dataq = csvread('../../Data/eleSegments/test_case/case1_baro_gnd.csv'); % query
datae = csvread('../../Data/eleSegments/test_case/case1_ac.csv');
datae = datae(1:100);

WINDOW = 0.5; % sec
nrB = floor((dataq(end,1) - dataq(1,1)) / WINDOW);
baros = zeros(nrB, 1);
baroc = zeros(nrB, 1);
for i = 1:size(dataq,1)
    ind = floor((dataq(i,1) - dataq(1,1)) / WINDOW) + 1;
    if 1 <= ind && ind <= nrB
        baros(ind) = baros(ind) + dataq(i,2);
        baroc(ind) = baroc(ind) + 1;
    end
end
baros = baros ./ baroc;
baros = baros(setdiff(1:nrB, find(isnan(baros))));

seaPre = 1018;
sca = -8.30;
height = (baros - seaPre) * sca;
ta = tic;
R = all_pair_dtw_baro(datae', height');
tb = tic;

tb - ta
size(datae)
size(height)

% test result:
%   size -> datae:50, baros:1099  ==> 49sec
%   size -> datae:100, baros:1099  ==> 101sec