function [ dist ] = latlng2m( latlngv, latlngh )
%[ dist ] = latlng2m( latlng1, latlng2 )
% converts latlng difference to distance in meters

% return dist(i, j) = distance between latlngv(i) and latlngh(j)
% assume latlngv and latlngh are both Nx2 matrix
numRow = size(latlngv, 1);
numCol = size(latlngh, 1);

R = 6378.137; % Radius of earth in KM

latlngh = latlngh';

latv = repmat(latlngv(:,1), 1, numCol);
lngv = repmat(latlngv(:,2), 1, numCol);
lath = repmat(latlngh(1,:), numRow, 1);
lngh = repmat(latlngh(2,:), numRow, 1);
dLat = (lath - latv) * pi / 180;
dLng = (lngh - lngv) * pi / 180;

a = sin(dLat/2) .* sin(dLat/2) + cos(latv*pi/180) .* cos(lath*pi/180) .* sin(dLng/2) .* sin(dLng/2);
c = 2*atan2(sqrt(a), sqrt(1-a));
d = R*c;
dist =  d*1000; % meters



%{
% single pair version
lat1 = latlng1(1);
lng1 = latlng1(2);
lat2 = latlng2(1);
lng2 = latlng2(2);

R = 6378.137; % Radius of earth in KM
dLat = (lat2 - lat1) * pi / 180;
dLng = (lng2 - lng1) * pi / 180;
a = sin(dLat/2)*sin(dLat/2) + cos(lat1*pi/180)*cos(lat2*pi/180)*...
    sin(dLng/2)*sin(dLng/2);
c = 2*atan2(sqrt(a), sqrt(1-a));
d = R*c;
dist =  d*1000; % meters
%}


end

