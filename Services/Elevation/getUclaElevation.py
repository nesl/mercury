# imports
from ElevationService import *

# get UCLA GPS coords
latlng_NW = (34.064255, -118.449709)
latlng_SE = (34.062873, -118.435355)
resolution = 1e-5
requester = ElevationGridRequester(latlng_NW,latlng_SE,resolution)
requester.downloadElevations('storage/Ucla_large', False)
#requester.saveAsFolder('storage/Ucla_large')


