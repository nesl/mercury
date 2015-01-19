# imports
from ElevationService import *
#import matplotlib.pyplot as plt

def linearSpace(latLngA, latLngB):
    dlat = latLngB[0] - latLngA[0]
    dlng = latLngB[1] - latLngA[1]
    d = (dlat*dlat + dlng*dlng) ** 0.5
    print(dlat, dlng, d)
    hop = int(d / 1e-4) + 1
    ret = []
    for i in range(hop):
        ret += [ (latLngA[0] + dlat * i / hop, latLngA[1] + dlng * i / hop) ]
    return ret

# get UCLA GPS coords
fname = 'storage/Ucla'
q = ElevationGridQuerier(fname);
start = (34.076991, -118.453712)
pt2 = (34.073809, -118.449163)
pt3 = (34.073969, -118.445129)
pt4 = (34.076902, -118.444184)
stop = (34.078324, -118.439421)

points1 = q.getElevationLine(start, pt2, 100)
points2 = q.getElevationLine(pt2, pt3, 100)
points3 = q.getElevationLine(pt3, pt4, 100)
points4 = q.getElevationLine(pt4, stop, 100)

gnd = points1 + points2 + points3 + points4
for x in gnd:
    print(x)

print('---------------------------------')

latLngs = []
latLngs += linearSpace(start, pt2)
latLngs += linearSpace(pt2, pt3)
latLngs += linearSpace(pt3, pt4)
latLngs += linearSpace(pt4, stop)
querier = ElevationQuerier(3)
ans = querier.query(latLngs)
for x in ans:
    print(x)

#plt.plot(points1 + points2 + points3 + points4)
#plt.show()

