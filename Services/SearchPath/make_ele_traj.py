# input: .tfix file
# output: a folder contains the elevation series of each segment of input .tfix file
#
# summary: load each segment in .tfix file and query the elevations
# alone this segment in a dense manner  (I plan to do it roughly less than 1 meter.)

import os
import sys
sys.path.append('../Elevation')
import ElevationCacheService as ECS

def linearSpace(latLngA, latLngB):
    dlat = latLngB[0] - latLngA[0]
    dlng = latLngB[1] - latLngA[1]
    d = (dlat*dlat + dlng*dlng) ** 0.5
    print(dlat, dlng, d)
    hop = int(d / 1e-5) + 1
    ret = []
    for i in range(hop):
        ret += [ (latLngA[0] + dlat * i / hop, latLngA[1] + dlng * i / hop) ]
    return ret



f = open('../../Data/trajectorySetsFix/ucla_west.tfix')   # input part
lines = f.readlines()
f.close()

outDir = '../../Data/eleSegments/ucla_west/'   # output folder
for line in lines:
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

    elevation = ECS.query(latLngs)
    print(elevation)
    f = open(outDir + ida + '_' + idb, 'w')
    for x in elevation:
        f.write(str(x) + '\n')
    f.close()


