function [ elevMatrix ] = TileGridLoader( input, varargin )

% TileGridLoader return the elevation grid based on the input. It reads the
% file in the EleTile folder. The input can be one of the three formats:
%
%     is a string -> this string represents a file name, and inside the file
%                    it records all the (corner of) the tiles.
%     is a n-by-2 array -> each row of the array stores all the (corner of) the tiles. 
%     is a 4-element row vector -> to specify the bounding box. In this
%                                  case, the order is [NW_LAT, NW_LONG, SE_LAT, SE_LONG]
%
% The second parameter is the resolution. The default is 4.
%
% The return value elevMatrix shows the final result of the tiles combine
% together. The bounding box is decided by max/min lat/lng. The missing
% tiles simply represent as NaN.



% prepareness: Resolution Parameters (Corrected for first lat top-right/bottom-left).
edgelength = [0 10 10 20 10] + 1;
reallength = 10.^-[0 1 2 3 4];


% parse the input part1: decide resolution
res = 4;
if numel(varargin) > 0
    res = varargin{1};
end

% initialize parameters based on resolution
edgeres = edgelength(res);
realres = reallength(res);
dir = sprintf('%s/%d/', '../../Data/EleTile', res);

% parse the input part2: decide tiles
if ischar(input)  % specify by file name
    fid = fopen('westwood.txt');
    tiles = roundn(cell2mat(textscan(fid,'%f %f')),-6);
else
    [r, c] = size(input);
    if r > 0 && c == 2  % specify by a list of tiles
        tiles = input;
    elseif r == 1 && c == 4  % specify by bounding box, with the order [NW_LAT, NW_LONG, SE_LAT, SE_LONG]
        lat_set = input(3):realres:input(1);
        long_set = input(2):realres:input(4);
        nlong = length(long_set); nlat = length(lat_set);

        lat_set = repmat(lat_set, nlong, 1); lat_set = lat_set(:);
        long_set = repmat(long_set, 1, nlat); long_set = long_set(:);
        tiles = [lat_set long_set]; 
    else
        error('Invalid input type (please see TileGridLoader.m for accepted input format');
    end
end



%% Create Map
max_lat = max(tiles(:,1));
min_lat = min(tiles(:,1));
min_lon = min(tiles(:,2));
max_lon = max(tiles(:,2));

tileIndx = zeros(size(tiles));

tileIndx(:,1) = tiles(:,1) - min_lat;
tileIndx(:,2) = tiles(:,2) - min_lon;
tileIndx = int32(abs(tileIndx)./realres) + 1;

tileRowCt = numel(unique(tiles(:,1)));
tileColCt = numel(unique(tiles(:,2)));

tile_map = cell(tileRowCt, tileColCt);

for i=1:length(tiles)
   latitude = tiles(i,1);
   longitude = tiles(i,2);
   filename = sprintf('%s%.6f_%.6f.etile', dir, latitude, longitude);
   if exist(filename, 'file') == 2
       tile_matrix = csvread(filename);
       %fprintf('o find %s\n', filename);
   else
       tile_matrix = NaN(edgeres);
       %fprintf('x find %s\n', filename);
   end
   tile_map{tileIndx(i,1),tileIndx(i,2)} = tile_matrix;
end

elevMatrix = cell2mat(tile_map);

end

