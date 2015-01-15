# imports
from ElevationService import *
import matplotlib.pyplot as plt

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

plt.plot(points1 + points2 + points3 + points4)
plt.show()

