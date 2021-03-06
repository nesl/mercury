import os
import sys
import ElevationService as ES

RESOLUTION = 8e-4

#lat1 = 34.104632
#lat2 = 34.082597
#lng1 = -118.316801
#lng2 = -118.381681
#lat1 = 33.791
#lng1 = -84.439
#lat2 = 33.706
#lng2 = -84.337
lat1 = 34.092
lat2 = 34.000  #lat2 = 33.828
lng1 = -118.495
lng2 = -118.125

if lat1 > lat2:
	lat2, lat1 = lat1, lat2

if lng1 > lng2:
	lng2, lng1 = lng1, lng2;

dlat = int((lat2 - lat1) / RESOLUTION) + 1
dlng = int((lng2 - lng1) / RESOLUTION) + 1

latlngs = []
for i in range(dlat):
	for j in range(dlng):
		latlngs += [ (lat1 + RESOLUTION * i, lng1 + RESOLUTION * j) ]


requester = ES.ElevationRequester()
elevation = requester.query(latlngs)



