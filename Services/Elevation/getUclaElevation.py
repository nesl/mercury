# imports
from ElevationService import *
from ElevationGridRequester import *

# get UCLA GPS coords
'''
latlng_NW = (34.049785, -118.471726)
latlng_SE = (34.088381, -118.419076)
resolution = 1e-4
requester = ElevationGridRequester(latlng_NW,latlng_SE,resolution)
requester.downloadElevations('storage/Ucla_large', False)
'''

latlng_NW = (34.049785, -118.471726)
latlng_SE = (34.054785, -118.473726)
resolution = 1e-4
requester = ElevationGridRequester(latlng_NW,latlng_SE,resolution)
requester.downloadElevations('storage/Ucla_piece', False)
