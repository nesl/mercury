# imports
from ElevationService import *

# get UCLA GPS coords
NW = (22.557869, -160.972767)
SE = (18.900729, -154.534779)
resolution = 5e-2
requester = ElevationGridRequester(NW,SE,resolution)
requester.downloadElevations()
requester.saveAsFolder('storage/Hawaii')


