dataDir = '../../Data/eleSegments/test_case/';

dataq = csvread([dataDir 'case1_baro_gnd.csv']); % query
datae = csvread([dataDir 'case1_ac.csv']); % elevation trajectory candidate

clf
hold on
plot(dataq(:,2), 'r')
plot(datae, 'b')
return;

%% segment barometer trajectory into window
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

clf
hold on
plot(baros, 'r')
plot(datae, 'b')

%% baros to height
seaPre = 1020.394;
sca = -7.9736;
height = (baros - seaPre) * sca;

clf
hold on
plot(height, 'r')
plot(datae, 'b')

%% dynamic time warping

answer = [];

for seaPre = 1018:0.5:1022
    for sca = -8.08:0.02:-7.88
        height = (baros - seaPre) * sca;
        
        [p, q, W] = dtw_baro(datae', height');
        x = [1 seaPre sca W(end, end)]
        answer = [answer; x];
        [p, q, W] = dtw_baro(flipud(datae)', height');
        x = [2 seaPre sca W(end, end)]
        answer = [answer; x];
    end
end

res = sortrows(answer, 4)


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