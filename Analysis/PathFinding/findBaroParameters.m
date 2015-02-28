clear all; clc; clf;

%% File set to process:

baro_files = {
    %'baro_n501_20141201_230214', 1417573441, NaN;  % fail on butter()
    'baro_n501_20141203_085057', NaN, 1417628515;
    %'baro_n501_20141213_093710', NaN, 1418494703;  % fail on butter()
    %'baro_n501_20141215_212237', 1418717289, NaN;  % fail on butter()
    'baro_n501_20150108_221546', NaN, NaN;
    'baro_n503_20150110_143636', NaN, NaN;
    'baro_n503_20150110_155834', NaN, NaN;
    'baro_n503_20150110_161641', NaN, NaN;
    'baro_n503_20150111_091333', NaN, NaN
};

baro_files(:,1) = strcat('../../Data/rawData/',baro_files(:,1));
baro_files(:,1) = strcat(baro_files(:,1),'.gps.csv');
limits = cell(length(baro_files),2); [limits{:}] = deal(NaN);

%% Function, can't think of a name right now
calWin = 60*10;    % in seconds
for file=1:size(baro_files, 1);
    % Create SensorData for file, parse elevation and barometer
    sensorFile = baro_files{file,1};
    startTime = baro_files{file,2};
    stopTime = baro_files{file,3};
    sData = SensorData(sensorFile);
    sData.setWindowSize(1);
    
    if ~(isnan(startTime) && isnan(stopTime))
       if isnan(startTime)
           startTime = min(sData.raw_gps(:,1));
       end
       if isnan(stopTime)
           stopTime = max(sData.raw_gps(:,1));
       end
       sData.setAbsoluteSegment(startTime, stopTime);
    end
    
    gpsEle = sData.getGps2Ele();
    gpsEle(:,1) = floor(gpsEle(:,1));
    eleWin = sData.getElevationTimeWindow();
    % Filter intervals with no data points
    baroWin = [floor(eleWin(:,1)), eleWin(:,2)/sData.PRESSURE_M2HPA + sData.PRESSURE_SEALEVEL];
    [~,iab] = setdiff(gpsEle(:,1), baroWin(:,1));
    [~,iag] = setdiff(baroWin(:,1), gpsEle(:,1));
    gpsEle = removerows(gpsEle, iab);
    baroWin = removerows(baroWin, iag);
    if isempty(gpsEle) || isempty(eleWin)
        disp('Empty set, ignoring.');
        continue
    end
    % Append extra values to allow reshape
    mBaros = baroWin(:,2);
    oElevs = gpsEle(:,4);
    short = calWin - mod(length(mBaros), calWin);
    if short ~= calWin
        mBaros = [mBaros; nan(short, 1)];
        oElevs = [oElevs; nan(short, 1)];
    end
    winCount = length(mBaros)/calWin;
    mBaros = reshape(mBaros, calWin, winCount)';
    oElevs = reshape(oElevs, calWin, winCount)';
    rmsErrs = zeros(1, winCount);
    params = zeros(winCount, 2);
    elepred = zeros(1, length(baroWin(:,1)));
    for win = 1:winCount
        baroSet = mBaros(win,:)'; elevSet = oElevs(win,:)';
        baroSet(isnan(baroSet)) = []; elevSet(isnan(elevSet)) = [];
        Z = [baroSet ones(length(baroSet),1)];
        R = pinv(Z)*elevSet;
        S = Z*R;
        
        params(win,:) = R;
        lBound = calWin*(win-1)+1;
        elepred(lBound:lBound+length(baroSet)-1) = S;
        
        delta = S - elevSet;
        rmsErrs(win) = sqrt(mean(delta.^2));
    end
    disp(rmsErrs);
    fullPred = [baroWin(:,1) elepred'];
    figure;
    plot(gpsEle(:,1),gpsEle(:,4),fullPred(:,1),fullPred(:,2),'r','LineWidth',0.75);

    % Print or store as necessary here, available variables:
    %   rmsErrs: root-mean-square error for each window in set.
    %   fullPred: predicted height using barometer data.
    %   params: scale+offset parameters that satisfy:
    %        height = params(X, 1)*baro + params(X, 2)
    %        Where X is index of window on which pseudo-inverse was
    %        computed. 'params' contains one set for each window.
    
end
