function [ rawBaro, rawGps ] = readTestCase(caseID)

% The caseID can be 1. the full name of the folder
%                   2. the first word (until the first underscope)


testCaseDir = '../../Data/BaroTrajTestCases/';

if exist([testCaseDir caseID], 'dir')
    fullPath = [testCaseDir caseID '/'];
else
    fileProfile = dir(testCaseDir);
    fileProfile = fileProfile(3:end);
    ind = 0;  % index of fileProfile share specified folder prefix
    numMatch = 0;  % number of matched folders
    mw = [caseID '_'];  % matched word
    ml = length(mw);  % matched length
    for i = 1:length(fileProfile)
        if fileProfile(i).isdir && length(fileProfile(i).name) >= ml && strcmp(mw, fileProfile(i).name(1:ml))
            ind = i;
            numMatch = numMatch + 1;
        end
    end
    
    if numMatch == 0
        error('Error: cannot find folder name with matched prefix.')
    end
    if numMatch >= 2
        error('Error: find more than one matches. Please rename the folder share with the same prefix.')
    end
    
    fullPath = [testCaseDir fileProfile(ind).name '/'];
end

rawBaro = csvread([fullPath 'baro.csv']);
rawGps = csvread([fullPath 'gps.csv']);