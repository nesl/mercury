dataDir = '../../Data/eleSegments/test_case/';

testFiles = {'case1_ac.csv', 'case1_aw1.csv', 'case1_aw2.csv', 'case1_aw3.csv', 'case1_aw4.csv'};

dataq = csvread([dataDir 'case1_baro_gnd.csv']); % query
return

%% process
% segment barometer trajectory into window
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



% dynamic time warping
for i = 1:5
    datae = csvread([dataDir testFiles{i}]); % query
    for seaPre = 1018:0.5:1022
        for sca = -8.30:0.05:-7.90
            height = (baros - seaPre) * sca;
            [p, q, W] = dtw_baro(datae', height');
            x = [i seaPre sca W(end, end)]
            answer = [answer; x];
        end
    end
end

res = sortrows(answer, 4);
res(1:20, :)


% lesson learned here:
%    if the offset (seaPre) is correct, the scale coefficient (sca)
%    doesn't matter that much

%% parse res
f = res(res(:,1) == 2,:);
f(:,4) = log10(f(:,4));
m = zeros(9, 11);
for i = 1:size(f,1)
    a = round((f(i,2) - 1018) / 0.5) + 1;
    b = round((f(i,3) + 8.08) / 0.02) + 1;
    m(a, b) = f(i,4);
end
clf
imagesc(m)
xlabel('scale coefficients')
ylabel('sea level pressure (hPa)')
set(gca, 'XTickLabel', strread(num2str(-8.08:0.02:-7.88), '%s') )
set(gca, 'YTickLabel', strread(num2str(1018:0.5:1022), '%s') )

colorbar


%% examine
seaPre = 1020.394;
sca = -7.9736;
testCaseInd = 1;

datae = csvread([dataDir testFiles{testCaseInd}]); % query

height = (baros - seaPre) * sca;

clf
hold on
plot(height, 'r')
plot(datae, 'b')
