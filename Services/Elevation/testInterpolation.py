# imports
from ElevationService import *
import matplotlib.pyplot as plt

# get UCLA GPS coords
fname = 'storage/Ucla'
q = ElevationGridQuerier(fname);
start = (34.072194, -118.444863)
stop = (34.072216, -118.440968)
elev_points = q.getElevationLine(start, stop, 100)
plt.plot(elev_points)
plt.show()

