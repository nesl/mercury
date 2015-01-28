# input: .tfix file
# output: a folder contains the elevation series of each segment of input .tfix file
#
# summary: load each segment in .tfix file and query the elevations
# 
# the experiment told us there's no big improvement if you generate very
# fine-grained elevation segments, so let's set resolution as >= 1e-4
# (should be roughly 5m)

import os
import sys
sys.path.append('../Elevation')
import ElevationService as ES

RESOLUTION = 1e-4

def linearSpace(latLngA, latLngB):
    dlat = latLngB[0] - latLngA[0]
    dlng = latLngB[1] - latLngA[1]
    d = (dlat*dlat + dlng*dlng) ** 0.5
    print(dlat, dlng, d)
    hop = int(d / RESOLUTION) + 1
    ret = []
    for i in range(hop):
        ret += [ (latLngA[0] + dlat * i / hop, latLngA[1] + dlng * i / hop) ]
    return ret



f = open('../../Data/trajectorySetsFix/ucla_small.tfix')   # input part
lines = f.readlines()
f.close()

outDir = '../../Data/EleSegmentSets/ucla_small/'   # output folder
cnt = 0
for line in lines:
    cnt += 1
    print(cnt, len(lines))
    eles = line.strip().split(',')
    ida = eles[0]
    idb = eles[-3]
    nr = len(eles)
    latLngs = []
    for i in range(nr // 3 - 1):
        latLngs += linearSpace(
                (float(eles[i*3+1]), float(eles[i*3+2])),
                (float(eles[i*3+4]), float(eles[i*3+5])) )
    latLngs += [ (float(eles[-2]), float(eles[-1])) ]

    if ida > idb:
        ida, idb = idb, ida
        latLngs.reverse()

    requester = ES.ElevationRequester()
    elevation = requester.query(latLngs)

    #print(elevation)
    eleLatLng = list(zip(elevation, latLngs))
    f = open(outDir + ida + '_' + idb, 'w')
    for x in eleLatLng:
        f.write(",".join( map(str, [ x[0], x[1][0], x[1][1] ] ) ) + '\n')
    f.close()


