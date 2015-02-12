function [ differenceScore ] = gpsSeriesCompare( seriesGnd, seriesEstimation )

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

ind = (seriesGnd(1,1) <= seriesEstimation(:,1) & seriesEstimation(:,1) <= seriesGnd(end,1));
seriesEstimation = seriesEstimation(ind, :);
gndLat = interp1(seriesGnd(:,1), seriesGnd(:,2), seriesEstimation(:,1), 'linear', 'extrap');
gndLng = interp1(seriesGnd(:,1), seriesGnd(:,3), seriesEstimation(:,1), 'linear', 'extrap');
gndLatLng = [gndLat gndLng];
% differenceScore = summation( dx*dx + dy*dy )
differenceScore = sum(sum(  (gndLatLng - seriesEstimation(:,2:3)) .^ 2  ));

end

