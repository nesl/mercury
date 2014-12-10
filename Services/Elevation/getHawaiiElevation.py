# imports
from ElevationService import ElevationRequester

def drange(start, stop, step):
  r = start
  while r < stop:
    yield r
    r += step

# get UCLA GPS coords
latlng_start = (22.557869, -160.972767)
latlng_stop = (18.900729, -154.534779)
resolution = 5e-2
dist_lat = abs( latlng_start[0] - latlng_stop[0] )
dist_lng = abs( latlng_start[1] - latlng_stop[1] )
latgrid_range = drange(latlng_stop[0], latlng_start[0], resolution)
latgrid = ["%f" % x for x in latgrid_range]
lnggrid_range = drange(latlng_start[1], latlng_stop[1], resolution)
lnggrid = ["%f" % x for x in lnggrid_range]
num_points = len(latgrid)*len(lnggrid)

# create elevation requester
rq = ElevationRequester()
rq.setName('Hawaii_res_5e-2')
positions_added = 0
for lat in latgrid:
  for lng in lnggrid:
    rq.addPosition( (lat, lng) )
    positions_added += 1
    print(' adding position ' + str(positions_added) + " of " + \
    	str(num_points) + " (" + str(100*positions_added/num_points) + "%)" )

rq.requestElevations()




