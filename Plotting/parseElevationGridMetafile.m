function [ res, latvec, lngvec, npts ] = parseElevationGridMetafile( fpath )


fid = fopen(fpath);
meta = textscan(fid, '%s %f32');
% parse
labels = meta{:,1};
values = meta{:,2};

res = values(find(ismember(labels, 'resolution')));
latstart = values(find(ismember(labels, 'latstart')));
latstop = values(find(ismember(labels, 'latstop')));
lngstart = values(find(ismember(labels, 'lngstart')));
lngstop = values(find(ismember(labels, 'lngstop')));
npts = values(find(ismember(labels, 'numpts')));
lenlat = values(find(ismember(labels, 'lenlat')));
lenlng = values(find(ismember(labels, 'lenlng')));

latvec = linspace(latstart, latstop, lenlat);
lngvec = linspace(lngstart, lngstop, lenlng);

fclose(fid);

end
