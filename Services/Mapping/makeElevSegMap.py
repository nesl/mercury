# input: .tfix file
# output: a folder contains the elevation series of each segment of input .tfix file
#
# summary: load each segment in .tfix file and query the elevations
# 
# the experiment told us there's no big improvement if you generate very
# fine-grained elevation segments, so let's set resolution as >= 1e-4
# (should be roughly 5m)

# Issues: the position of this script cannot be changed. Since it uses Elevation
#         library by appending the path, and ElevationService has it's own path
#         to store data (elevation tiles), move this script into other folder,
#         or even executing this script from different working directory will
#         raise folder/file not found error.

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


# historical options
inputTfixName = 'ucla_5x5.tfix'
#inputTfixName = 'ucla_4x4.tfix'
#inputTfixName = 'ucla_3x3.tfix'
#inputTfixName = 'ucla_sample.tfix'  # sample: 'ucla_small.tfix'
#inputTfixName = 'ucla_west'


#if len(sys.argv) >= 2:
#    inputTfixName = sys.argv[1]

inRootDir = '../../Data/trajectorySets/'
outRootDir = '../../Data/EleSegmentSets/'

tfixFilePath = inRootDir + inputTfixName
outDir = outRootDir + inputTfixName[:-5] + '/'

cmd = 'mkdir -p ' + outDir
os.system(cmd)

f = open(tfixFilePath)   # input part
lines = f.readlines()
f.close()

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


