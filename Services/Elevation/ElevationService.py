
# --- IMPORTS ---
import simplejson
import numpy as np

try:
  import urllib.parse as urllibParse
except ImportError:
  import urllib as urllibParse

try:
  import urllib.request as urllibRequest
except ImportError:
  import urllib as urllibRequest

# --- CONSTANTS ---
EARTH_RAD_KM = 6371

# --- HTTP API URLs ---
ELEVATION_BASE_URL = 'https://maps.googleapis.com/maps/api/elevation/json'
CHART_BASE_URL = 'http://chart.apis.google.com/chart'

def roundTo6thDigit(n):
  return round(n, 6)

def latlngToMeters(dist_latlng):
  a = (np.sin(np.deg2rad(dist_latlng)/2))**2
  c = 2*np.arctan2(np.sqrt(a), np.sqrt(1-a))
  d = EARTH_RAD_KM*c
  return d*1000.0

def metersToLatlng(dist_m):
  dist_km = dist_m/1000.0
  degrees = np.rad2deg(dist_km/EARTH_RAD_KM)

def isValidLattitude(test):
  if test >= -90 and test <= 90:
    return True
  return False

def isValidLongitude(test):
  if test >= -180 and test <= 180:
    return True
  return False

def isValidLatlng(latlng):
  if isValidLattitude(latlng[0]) and isValidLongitude(latlng[1])
    return True
  return False

def drange(start, stop, step):
  pol = 1
  if stop < start:
    pol = -1
  r = start
  # make sure polarity and step align
  if pol == 1 and step < 0 or pol == -1 and step > 0:
    return

  while pol*r <= pol*stop:
    yield r
    r += step

class ElevationMatrixRequester:

  def __init__(self, latlng_start, latlng_stop, res_meters=10):

    self.res_latlng = metersToLatlng(res_meters)

    # check for valid inputs
    if not isValidLatlng(latlng_start) or not isValidLatlng(latlng_stop):
      raise ValueError('Improper (lat,long) pair provided')
    if res_meters < 0:
      raise ValueError('Negative resolution provided')

    # find the "North West" and "South East" (lat,lng)
    latlng_NW = (max(latlng_start[0],latlng_stop[0]),min(latlng_start[1],latlng_stop[1]))
    latlng_SE = (min(latlng_start[0],latlng_stop[0]),max(latlng_start[1],latlng_stop[1]))

    # make sure the longitude is the correct polarity
    if latlng_NW[1] - latlng_SE[1] <= -180:
      raise ValueError('Specified Region cannot cross 180 degrees longitude')

    # define the positional grid
    dist_lat = abs( latlng_NW[0] - latlng_SE[0] )
    dist_lng = abs( latlng_NW[1] - latlng_SE[1] )
    if dist_lng >= 180:
      dist_lng = 360 - dist_lng
    latgrid_range = drange(latlng_NW[0], latlng_SE[0], resolution)
    latgrid = ["%f" % round(x,6) for x in latgrid_range]
    if 
    lnggrid_range = drange(latlng_NW[1], latlng_SE[1], resolution)
    lnggrid = ["%f" % round(x,6) for x in lnggrid_range]

    num_points = len(latgrid)*len(lnggrid)
    

class ElevationRequester:
  BLOCKSIZE = 75

  def __init__(self):
    self.savename = 'default'
    self.data = {}
    self.positions = []

  def setSaveName(self, savename):
    self.savename = savename

  def setPositions(self, positions):
    self.positions = positions

  def addPosition(self, xy):
    self.positions.append(xy)

  def requestElevations(self):
    # since google elevation api doesn't allow us to access very fine-grained
    # (my test is up to 6th digit after floating point, which is cm level),
    # the following line is just truncate the tailing digits
    self.positions = [ map(roundTo6thDigit, x) for x in self.positions ]

    self.fid = open('storage/'+str(self.savename)+".csv", 'w')

    if len(self.positions) == 0:
      return
    # how many request blocks do we need?
    num_blocks = int( len(self.positions)/ElevationRequester.BLOCKSIZE) + 1

    # convert block locations to string
    location_str = ''
    location_pts = []
    current_block_size = 0
    current_block = 1

    for l in self.positions:
      # if this block is big enough, send it out and keep going
      if current_block_size >= ElevationRequester.BLOCKSIZE:
        # remove last "|"
        location_str = location_str[0:-1]
        print(" requesting block " + str(current_block) + " of " + str(num_blocks))
        data = self.requestElevationBlock(location_str, location_pts)
        current_block_size = 0
        current_block += 1
        location_str = ''
        location_pts = []

      current_block_size += 1
      location_str += str(l[0]) + "," + str(l[1])
      location_str += "|"
      location_pts.append( (l[0],l[1]) )

    print(" requesting block " + str(current_block) + " of " + str(num_blocks))
    # remove last "|"
    location_str = location_str[0:-1]
    self.requestElevationBlock(location_str, location_pts)

    self.fid.close()

  def requestElevationBlock(self,block_str, block_pts):
    elvtn_args = {
      'locations': block_str,
    }
    url = ELEVATION_BASE_URL + '?' + urllibParse.urlencode(elvtn_args)
    response = simplejson.load(urllibRequest.urlopen(url))
    result_num = 0
    for resultset in response['results']:
      #lat = resultset['location']['lat']
      #lng = resultset['location']['lng']
      lat = block_pts[result_num][0]
      lng = block_pts[result_num][1]
      alt = resultset['elevation']
      self.data[lat,lng] = alt
      self.fid.write(str(lat) + "," + str(lng) + "," + str(alt) + "\n")
      result_num += 1


if __name__ == '__main__':
    # testing...
    rq = ElevationRequester()
    rq.setSaveName('test')
    rq.addPosition( (36.578581,-118.291994) )
    rq.addPosition( (36.23998,-116.83171) )
    print(latlngToMeters(-179.999-(179.999)))
    #rq.requestElevations()
