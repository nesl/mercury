fid = fopen('latiles.txt');
tiles = cell2mat(textscan(fid,'%f %f'));

res = 4; edges = [0 10 10 20 10] + 1;
edgelen = edges(res);
tilepts = edges(res)^2;

dir = sprintf('%s/%d/','../Data/EleTile',res);

mp = cell(10);
ulat = unique(tiles(:,1));
ulon = unique(tiles(:,2));
dlat = roundn(abs(ulat(1) - ulat(2)),-6);
dlon = roundn(abs(ulon(1) - ulon(2)),-6);

for i=1:length(tiles)
    lat = tiles(i,1);
    lon = tiles(i,2);
    filename = sprintf('%s%.6f_%.6f.etile',dir,lat,lon);
    m = csvread(filename);
    r = int8(roundn(abs(lat - max(ulat)),-6)/dlat + 1);
    c = int8(roundn(abs(lon - min(ulon)),-6)/dlon + 1);
    mp{r,c} = m;
end
rp = cell2mat(mp);
surf(rp);
% bottom left to top right.
