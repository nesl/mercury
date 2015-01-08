# imports
from ElevationService import *

# get UCLA GPS coords
latlng_NW = (34.078567, -118.460890)
latlng_SE = (34.059868, -118.432823)
resolution = 1e-5
requester = ElevationGridRequester(latlng_NW,latlng_SE,resolution)
requester.downloadElevations()
requester.saveAsFolder('storage/Ucla_1em5')


