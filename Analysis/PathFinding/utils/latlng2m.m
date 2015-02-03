function [ dist ] = latlng2m( latlng1, latlng2 )
%[ dist ] = latlng2m( latlng1, latlng2 )
% converts latlng difference to distance in meters

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

end

