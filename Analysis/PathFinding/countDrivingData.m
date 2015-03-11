clc; close all; clear all;
fdir = '../../Data/rawData/';
addpath('utils');

all_files = dir(fdir);

dist = 0;
time = 0;

for fidx=1:length(all_files)
    fpath = [fdir all_files(fidx).name];
    if ~isempty( regexp(fpath, 'gps.csv', 'match') )
        
        % files to ignore
        if ~isempty( regexp(fpath, '140457') )
            fprintf('skipping: %s\n', fpath);
            continue;
        end
        
        disp(fpath);
        data = csvread(fpath);
        t = data(end,1) - data(1,1);
        t = t/1e3;
        d = 0;
        for i=2:size(data,1)
            dm = latlng2m(data(i,2:3), data(i-1,2:3));
            dist = dist + dm;
        end
        
    end
    
end