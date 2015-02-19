function [ rootMeanSquare ] = timeGpsSeriesCompare( seriesGnd, seriesEstimation )

% This function compare two <time, lat, lng> series and evaluate the
% difference with square-error metric.
%
% Parameter explanation:
%   - seriesGnd: a three column table, with <time, lat, lng>. This suppose
%                to be the gps data from the mobile phone.
%   - seriesEstimation: a three column table, with <time, lat, lng>. This
%                       should be the estimated result from our searching algorithm.
%
% Algorithm:
%   For each record in seriesEstimation, based on the timestamp, extract
%   the expected location from the seriesGnd via interpolation. Calculate
%   the square error then do summation.

gndLat = interp1(seriesGnd(:,1), seriesGnd(:,2), seriesEstimation(:,1), 'linear', 'extrap');
gndLng = interp1(seriesGnd(:,1), seriesGnd(:,3), seriesEstimation(:,1), 'linear', 'extrap');
gndLatLng = [gndLat gndLng];
distance = zeros(size(gndLatLng), 1);
for i = 1:size(gndLatLng, 1)
    distance(i) = latlng2m(gndLatLng(i,:), seriesEstimation(i,2:3));
end
rootMeanSquare = rms(distance);

end