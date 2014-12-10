# imports
from ElevationService import *

# get UCLA GPS coords
latlng_NW = (22.557869, -160.972767)
latlng_SE = (18.900729, -154.534779)
resolution = 5e-2
requester = ElevationGridRequester(latlng_NW,latlng_SE,resolution)
requester.downloadElevations()
requester.saveAsFolder('storage/Hawaii')


