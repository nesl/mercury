%% Global knobs
show3d = 0;

%% Get elevation matrix. Uncomment one at one time.

% use file
%elevMatrix = TileGridLoader('westwood.txt');

% use bounding box
%elevMatrix = TileGridLoader([  34.062 -118.448   34.057 -118.443 ]);  % west wood
%elevMatrix = TileGridLoader([  32.758 -117.207   32.673 -117.106 ]);  % 6x6_San Diego
%elevMatrix = TileGridLoader([  37.817 -122.472   37.733 -122.364 ]);  % 6x6_San Francisco
%elevMatrix = TileGridLoader([  37.382 -121.948   37.297 -121.840 ]);  % 6x6_San Jose
%elevMatrix = TileGridLoader([  34.095 -118.294   34.010 -118.191 ]);  % 6x6_Los Angeles
%elevMatrix = TileGridLoader([  41.892  -87.707   41.808  -87.593 ]);  % 6x6_Chicago
%elevMatrix = TileGridLoader([  40.757  -74.063   40.672  -73.950 ]);  % 6x6_New York
%elevMatrix = TileGridLoader([  33.809 -118.240   33.724 -118.137 ]);  % 6x6_Long Beach
%elevMatrix = TileGridLoader([  42.401  -71.118   42.316  -71.002 ]);  % 6x6_Boston
%elevMatrix = TileGridLoader([  33.465 -111.873   33.380 -111.771 ]);  % 6x6_Mesa
%elevMatrix = TileGridLoader([  33.491 -112.124   33.406 -112.022 ]);  % 6x6_Phoenix
%elevMatrix = TileGridLoader([  32.264 -110.976   32.179 -110.875 ]);  % 6x6_Tucson
%elevMatrix = TileGridLoader([  36.790 -119.825   36.705 -119.718 ]);  % 6x6_Fresno
%elevMatrix = TileGridLoader([  38.624 -121.548   38.539 -121.439 ]);  % 6x6_Sacramento
%elevMatrix = TileGridLoader([  39.782 -105.040   39.697 -104.929 ]);  % 6x6_Denver
%elevMatrix = TileGridLoader([  38.937  -77.092   38.853  -76.982 ]);  % 6x6_Washington
%elevMatrix = TileGridLoader([  30.374  -81.705   30.289  -81.606 ]);  % 6x6_Jacksonville
%elevMatrix = TileGridLoader([  33.791  -84.439   33.706  -84.337 ]);  % 6x6_Atlanta
%elevMatrix = TileGridLoader([  39.811  -86.214   39.726  -86.102 ]);  % 6x6_Indianapolis
%elevMatrix = TileGridLoader([  39.157  -94.682   39.072  -94.572 ]);  % 6x6_Kansas City
%elevMatrix = TileGridLoader([  29.997  -90.124   29.912  -90.026 ]);  % 6x6_New Orleans
%elevMatrix = TileGridLoader([  39.333  -76.668   39.248  -76.557 ]);  % 6x6_Baltimore
%elevMatrix = TileGridLoader([  42.374  -83.104   42.289  -82.988 ]);  % 6x6_Detroit
%elevMatrix = TileGridLoader([  39.142  -94.633   39.057  -94.523 ]);  % 6x6_Kansas City
%elevMatrix = TileGridLoader([  41.301  -95.994   41.216  -95.881 ]);  % 6x6_Omaha
%elevMatrix = TileGridLoader([  36.217 -115.189   36.133 -115.084 ]);  % 6x6_Las Vegas
%elevMatrix = TileGridLoader([  35.127 -106.703   35.042 -106.598 ]);  % 6x6_Albuquerque
%elevMatrix = TileGridLoader([  35.269  -80.896   35.184  -80.791 ]);  % 6x6_Charlotte
%elevMatrix = TileGridLoader([  41.542  -81.753   41.457  -81.639 ]);  % 6x6_Cleveland
%elevMatrix = TileGridLoader([  40.004  -83.055   39.919  -82.943 ]);  % 6x6_Columbus
%elevMatrix = TileGridLoader([  35.510  -97.568   35.425  -97.464 ]);  % 6x6_Oklahoma City
elevMatrix = TileGridLoader([  45.566 -122.736   45.481 -122.614 ]);  % 6x6_Portland
%elevMatrix = TileGridLoader([  39.995  -75.220   39.910  -75.108 ]);  % 6x6_Philadelphia
%elevMatrix = TileGridLoader([  18.511  -66.151   18.426  -66.061 ]);  % 6x6_San Juan
%elevMatrix = TileGridLoader([  35.192  -90.101   35.107  -89.997 ]);  % 6x6_Memphis
%elevMatrix = TileGridLoader([  36.208  -86.837   36.123  -86.732 ]);  % 6x6_Nashville
%elevMatrix = TileGridLoader([  30.309  -97.792   30.224  -97.693 ]);  % 6x6_Austin
%elevMatrix = TileGridLoader([  32.826  -96.851   32.741  -96.749 ]);  % 6x6_Dallas
%elevMatrix = TileGridLoader([  31.801 -106.537   31.716 -106.436 ]);  % 6x6_El Paso
%elevMatrix = TileGridLoader([  32.768  -97.371   32.683  -97.270 ]);  % 6x6_Fort Worth
%elevMatrix = TileGridLoader([  29.806  -95.412   29.721  -95.314 ]);  % 6x6_Houston
%elevMatrix = TileGridLoader([  29.466  -98.542   29.381  -98.444 ]);  % 6x6_San Antonio
%elevMatrix = TileGridLoader([  36.895  -76.032   36.810  -75.925 ]);  % 6x6_Virginia Beach
%elevMatrix = TileGridLoader([  47.649 -122.394   47.564 -122.267 ]);  % 6x6_Seattle
%elevMatrix = TileGridLoader([  43.081  -87.965   42.996  -87.848 ]);  % 6x6_Milwaukee




%% visualize
clf
if show3d
    h = surf(elevMatrix);
    set(h,'LineStyle','none');
else
    imagesc(elevMatrix);
end

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
