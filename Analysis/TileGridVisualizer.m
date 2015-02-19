%% Resolution Parameters (Corrected for first lat top-right/bottom-left).
res = 5;
edgelength = [0 10 10 20 10] + 1;
reallength = 10.^-[0 1 2 3 4];
edgeres = edgelength(res);
realres = reallength(res);

dir = sprintf('%s/%d/','../Data/EleTile',res);

%% Bounded box visualization [NW_LAT, NW_LONG, SE_LAT, SE_LONG]
westwood = [34.062, -118.448, 34.057, -118.443];
data_box = westwood;

lat_set = data_box(3):realres:data_box(1);
long_set = data_box(2):realres:data_box(4);
nlong = length(long_set); nlat = length(lat_set);

lat_set = repmat(lat_set, nlong, 1); lat_set = lat_set(:);
long_set = repmat(long_set, 1, nlat); long_set = long_set(:);
box_tileset = [lat_set long_set]; 

%% Get desired points from file (Later make this a function that accepts a box)
fid = fopen('westwood.txt');
file_tileset = roundn(cell2mat(textscan(fid,'%f %f')),-6);

%% Create Map
tiles = box_tileset;
max_lat = max(tiles(:,1));
min_lon = min(tiles(:,2));
min_lat = min(tiles(:,1)); max_lon = max(tiles(:,2));
tileIndx = zeros(size(tiles));

tileIndx(:,1) = tiles(:,1) - min_lat;
tileIndx(:,2) = tiles(:,2) - min_lon;
tileIndx = int32(abs(tileIndx)./realres) + 1;

tileRowCt = numel(unique(tiles(:,1)));
tileColCt = numel(unique(tiles(:,2)));

tile_map = cell(tileRowCt, tileColCt);
tile_matrix = NaN(edgeres);

for i=1:length(tiles)
   latitude = tiles(i,1);
   longitude = tiles(i,2);
   filename = sprintf('%s%.6f_%.6f.etile',dir,latitude,longitude);
   if exist(filename, 'file') == 2
       tile_matrix = csvread(filename);
   else
       tile_matrix = NaN(edgeres);
   end
   tile_map{tileIndx(i,1),tileIndx(i,2)} = tile_matrix;
end
tile_map = cell2mat(tile_map);
%tile_map = tile_map(:,any(~isnan(tile_map)));
%tile_map = tile_map(any(~isnan(tile_map),2),:);
h = surf(tile_map);
set(h,'LineStyle','none');

% fid = fopen('latiles.txt');
% tiles = cell2mat(textscan(fid,'%f %f'));
% 
% res = 4; edges = [0 10 10 20 10] + 1;
% edgelen = edges(res);
% 
% dir = sprintf('%s/%d/','../Data/EleTile',res);
% 
% ulat = unique(tiles(:,1));
% ulon = unique(tiles(:,2));
% dlat = roundn(abs(ulat(1) - ulat(2)),-6);
% dlon = roundn(abs(ulon(1) - ulon(2)),-6);
% 
% mp = cell(length(ulat),length(ulon));
% q = zeros(size(tiles));
% for i=1:length(tiles)
%     lat = tiles(i,1);
%     lon = tiles(i,2);
%     filename = sprintf('%s%.6f_%.6f.etile',dir,lat,lon);
%     if exist(filename,'file') == 2
%         m = csvread(filename);
%     else
%         m = zeros(edgelen);
%     end
%     %r = int8(roundn(abs(lat - max(ulat)),-6)/dlat + 1);
%     %c = int8(roundn(abs(lon - min(ulon)),-6)/dlon + 1);
%     %q(i,1) = r; q(i,2) = c;
%     mp{r,c} = m;
% end
% rp = cell2mat(mp);
% rp(rp == 0) = NaN;
% h = surf(rp);
% set(h,'LineStyle','none')
% % bottom left to top right.
