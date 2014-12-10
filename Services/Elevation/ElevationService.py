
# --- IMPORTS ---
import simplejson
import numpy as np
import os

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
MAX_REQUEST_POINTS = 50000
REQUEST_BLOCKSIZE = 75

# --- HTTP API URLs ---
ELEVATION_BASE_URL = 'https://maps.googleapis.com/maps/api/elevation/json'
CHART_BASE_URL = 'http://chart.apis.google.com/chart'

# --- HELPER SUBROUTINES ---
def isValidLattitude(test):
  if test >= -90 and test <= 90:
    return True
  return False

def isValidLongitude(test):
  if test >= -180 and test <= 180:
    return True
  return False

def isValidLatlng(latlng):
  if isValidLattitude(latlng[0]) and isValidLongitude(latlng[1]):
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

class ElevationGridRequester:

  def __init__(self, latlng_start, latlng_stop, resolution):

    self.res_latlng = resolution
    self.elevationGrid = []

    # check for valid inputs
    if not isValidLatlng(latlng_start) or not isValidLatlng(latlng_stop):
      raise ValueError('Improper (lat,long) pair provided')
    if resolution < 0:
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

    latgrid_range = drange(latlng_NW[0], latlng_SE[0], -self.res_latlng)
    self.latgrid = [x for x in latgrid_range]
    self.len_lat = len(self.latgrid)

    lnggrid_range = drange(latlng_NW[1], latlng_SE[1], self.res_latlng)
    self.lnggrid = [x for x in lnggrid_range]
    self.len_lng = len(self.lnggrid)

    self.num_points = self.len_lng*self.len_lat

    if self.num_points > MAX_REQUEST_POINTS:
      raise ValueError('The specified resolution produces %d points (max %d)' %\
        (self.num_points, MAX_REQUEST_POINTS))

  def downloadElevations(self):
    for lat in self.latgrid:
      block_pts = []
      for lng in self.lnggrid:
        block_pts.append((lat,lng))
      elevations = requestElevations(block_pts)
      self.elevationGrid.append(elevations)

  def getElevationGrid(self):
    return self.elevationGrid

  def saveAsFolder(self, path):
    # if the folder doesn't exist, create it
    if not os.path.exists(path):
      os.makedirs(path)

    # create metadata file
    fid = open(path + '/meta.txt', 'w')
    fid.write('resolution '+str(self.res_latlng)+'\n')
    fid.write('latstart '+str(self.latgrid[0])+'\n')
    fid.write('latstop '+str(self.latgrid[-1])+'\n')
    fid.write('lngstart '+str(self.lnggrid[0])+'\n')
    fid.write('latstop '+str(self.lnggrid[-1])+'\n')
    fid.write('numpts '+str(self.num_points)+'\n')
    fid.write('lenlat '+str(self.len_lat)+'\n')
    fid.write('lenlng '+str(self.len_lng)+'\n')
    fid.close()

    # create matrix file
    fid = open(path + '/data.csv', 'w')
    for line in self.elevationGrid:
      for point in line:
        fid.write('%f,' % point)
      fid.write('\n')
    fid.close()


def requestElevations(pts):
  # truncate tailing digits
  pts = [ (round(x[0],6), round(x[1],6)) for x in pts ]
  if len(pts) == 0:
    return

  # how many request blocks do we need?
  num_blocks = int( len(pts)/REQUEST_BLOCKSIZE) + 1
  
  # request elevations in blocks
  block_pts = []
  current_block_size = 0
  current_block = 1
  elevations = []

  for p in pts:
    # if this block is big enough, send it out and keep going
    if current_block_size >= REQUEST_BLOCKSIZE:
      #print(" requesting block " + str(current_block) + " of " + str(num_blocks))
      elevation_block = requestElevationBlock(block_pts)
      elevations.extend(elevation_block)
      current_block_size = 0
      current_block += 1
      block_pts = []

    current_block_size += 1
    block_pts.append( (p[0],p[1]) )

  # if there are pending points still
  if current_block_size > 0:
    elevation_block = requestElevationBlock(block_pts)
    elevations.extend(elevation_block)

  return elevations

  #self.fid.close()

def requestElevationBlock(block_pts):
  # make sure the request is short enough
  if len(block_pts) > REQUEST_BLOCKSIZE:
    raise ValueError('requested block is too large')

  # convert positions to string
  pts_str = ''
  for p in block_pts:
    pts_str += str(p[0]) + "," + str(p[1])
    pts_str += "|"
  # remove final "|"
  pts_str = pts_str[0:-1]

  # request elevations
  elvtn_args = {
    'locations': pts_str,
  }
  url = ELEVATION_BASE_URL + '?' + urllibParse.urlencode(elvtn_args)
  response = simplejson.load(urllibRequest.urlopen(url))

  # parse elevations
  elevations = []
  for resultset in response['results']:
    elevations.append(resultset['elevation'])

  if len(elevations) != len(block_pts):
    raise EnvironmentError('Response from Google Elevation API is underfull')

  return elevations



if __name__ == '__main__':
    # testing...
    print('testing basic elevation requesting...')
    res = requestElevations([(36.578581,-118.291994), (36.23998,-116.83171)])
    print(res)
    print('testing grid requests...')
    NW = (34.073263, -118.444527)
    SE = (34.070979, -118.440804)
    req = ElevationGridRequester(NW, SE, 1e-4)
    req.downloadElevations()
    req.saveAsFolder('storage/test')

