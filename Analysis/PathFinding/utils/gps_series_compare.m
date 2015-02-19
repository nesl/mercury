function [ rootMeanSquare ] = gps_series_compare( seriesGnd, seriesEstimation )

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
%   For every point in seriesEstimation, find the closest points in
%   seriesGnd. Return the root mean square of these closest distances.

numElementGnd = size(seriesGnd, 1);
numElementEstimation = size(seriesEstimation, 1);
distances = zeros(numElementGnd, numElementEstimation);
for i = 1:numElementGnd
    for j = 1:numElementEstimation
        distances(i, j) = latlng2m(seriesGnd(i,2:3), seriesEstimation(j,2:3));
    end
end

rootMeanSquare = rms(min(distances));

end

% about distances:
%
%       =========>  2nd-dim, seriesEstimation
%        x x x x        
%        x x x x        |
%        x x x x        |
% min([  x x x x  ])    |
%        x x x x        |
%        x x x x        |
%        x x x x        |
%                       v
%    = [ R R R R ]      1st-dim, seriesGnd
