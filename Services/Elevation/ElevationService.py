
# --- IMPORTS ---
import simplejson
import numpy as np
import os
import sys
import traceback

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
MAX_REQUEST_POINTS = 600000
REQUEST_BLOCKSIZE = 75
REQUEST_MAXATTEMPTS = 20

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



# for querying points on a pre-downloaded grid
class ElevationGridQuerier:


  def __init__(self, fpath):
    self.fpath = fpath
    # make sure directory exists
    if not os.path.exists(fpath):
      raise IOError('specified folder does not exist')
    # read meta file
    fmeta = open(fpath + '/meta.txt')
    line = fmeta.readline()
    while line:
      # split line up
      tokens = line.split()
      # parse
      if tokens[0] == 'resolution':
        self.resolution = float(tokens[1])
      elif tokens[0] == 'latstart':
        self.latstart = float(tokens[1])
      elif tokens[0] == 'latstop':
        self.latstop = float(tokens[1])
      elif tokens[0] == 'lngstart':
        self.lngstart = float(tokens[1])
      elif tokens[0] == 'lngstop':
        self.lngstop = float(tokens[1])
      elif tokens[0] == 'numpts':
        self.numpts = int(tokens[1])
      elif tokens[0] == 'lenlat':
        self.lenlat = int(tokens[1])
      elif tokens[0] == 'lenlng':
        self.lenlng = int(tokens[1])

      line = fmeta.readline()

    # read data file
    fdata = open(fpath + '/data.csv')
    self.data = np.loadtxt(fdata,delimiter=",")

    # create index vectors for lattitude and longitude
    self.latvec = [self.latstart - self.resolution*x for x in range(self.lenlat)]
    self.lngvec = [self.lngstart + self.resolution*x for x in range(self.lenlng)]

  def getLatBoundIndx(self, lat):
    for i in range(len(self.latvec)):
      if self.latvec[i] < lat:
        # return top, bot
        return (i-1,i)
    raise ValueError('Requested lattitude out of range')

  def getLngBoundIndx(self, lng):
    for i in range(len(self.lngvec)):
      if self.lngvec[i] > lng:
        # return left, right
        return (i-1,i)
    raise ValueError('Requested longitude out of range')

  def bilinear_interpolation(self, x, y, points):
    '''Interpolate (x,y) from values associated with four points.

    The four points are a list of four triplets:  (x, y, value).
    The four points can be in any order.  They should form a rectangle.

        >>> bilinear_interpolation(12, 5.5,
        ...                        [(10, 4, 100),
        ...                         (20, 4, 200),
        ...                         (10, 6, 150),
        ...                         (20, 6, 300)])
        165.0

    '''
    # See formula at:  http://en.wikipedia.org/wiki/Bilinear_interpolation

    points = sorted(points)               # order points by x, then by y
    (x1, y1, q11), (_x1, y2, q12), (x2, _y1, q21), (_x2, _y2, q22) = points

    if x1 != _x1 or x2 != _x2 or y1 != _y1 or y2 != _y2:
        raise ValueError('points do not form a rectangle')
    if not x1 <= x <= x2 or not y1 <= y <= y2:
        raise ValueError('(x, y) not within the rectangle')

    return (q11 * (x2 - x) * (y2 - y) +
            q21 * (x - x1) * (y2 - y) +
            q12 * (x2 - x) * (y - y1) +
            q22 * (x - x1) * (y - y1)
           ) / ((x2 - x1) * (y2 - y1) + 0.0)

  def getInterpolatedElevation(self, latlng):
    # ^ lat
    # |
    #
    # NW     NE
    #  * --- *
    #  |     |
    #  * --- *
    # SW     SE --> lng

    lat = latlng[0]
    lng = latlng[1]

    # check for out of bounds
    if lat > self.latstart or lat < self.latstop:
      raise ValueError('One or more specified lattitude points exceeds grid dimensions')
    if lng < self.lngstart or lng > self.lngstop:
      raise ValueError('One or more specified longitude points exceeds grid dimensions')

    # get surrounding, bounding lat/lng indices
    latb = self.getLatBoundIndx(lat)
    lngb = self.getLngBoundIndx(lng)

    # get surrounding elevation value tuples (x/lng, y/lat, value/elev)
    elev_NW = (self.lngvec[lngb[0]], self.latvec[latb[0]], self.data[latb[0], lngb[0]])
    elev_NE = (self.lngvec[lngb[1]], self.latvec[latb[0]], self.data[latb[0], lngb[1]])
    elev_SW = (self.lngvec[lngb[0]], self.latvec[latb[1]], self.data[latb[1], lngb[0]])
    elev_SE = (self.lngvec[lngb[1]], self.latvec[latb[1]], self.data[latb[1], lngb[1]])

    bounding_points = [elev_NW, elev_NE, elev_SW, elev_SE]
    print('-------------- PT = ' + str(latlng) + ' -----------------')
    print('NW = ' + str(elev_NW) + ' NE = ' + str(elev_NE) + ' SW = ' + str(elev_SW) + ' SE = ' + str(elev_SE))

    # interpolate
    elev_inter = self.bilinear_interpolation(lng, lat, bounding_points)
    return elev_inter

  def getElevationPoints(self, points):
    elev_points = []
    for p in points:
      elev_points.append( self.getInterpolatedElevation(p) )

    return elev_points

  def getElevationLine(self, start, stop, N):
    elev_points = []

    latstep = (stop[0] - start[0])/N
    lngstep = (stop[1] - start[1])/N
    points = [(round(start[0] + x*latstep, 6), round(start[1] + x*lngstep, 6)) for x in range(N)]

    return self.getElevationPoints( points )




# for downloading an elevation Grid (rectangle of points)
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

  def downloadElevations(self, path, truncate=False):
    # if truncate is disabled, it is append mode and load the previous result
    # automatically.

    # if the folder doesn't exist, create it
    if not os.path.exists(path):
      os.makedirs(path)

    if truncate == False:
      self.loadData(path)

    for rowCnt in range(len(self.elevationGrid), len(self.latgrid)):
      lat = self.latgrid[rowCnt]
      print('progress: row %d/%d' % (rowCnt+1, len(self.latgrid)))
      block_pts = list(zip([lat] * len(self.lnggrid), self.lnggrid))
      elevations = requestElevations(block_pts)
      self.elevationGrid.append(elevations)
      self.saveData(path)
    self.saveMeta(path)

  def saveMeta(self, path):
    fid = open(path + '/meta.txt', 'w')
    fid.write('resolution '+str(self.res_latlng)+'\n')
    fid.write('latstart '+str(self.latgrid[0])+'\n')
    fid.write('latstop '+str(self.latgrid[-1])+'\n')
    fid.write('lngstart '+str(self.lnggrid[0])+'\n')
    fid.write('lngstop '+str(self.lnggrid[-1])+'\n')
    fid.write('numpts '+str(self.num_points)+'\n')
    fid.write('lenlat '+str(self.len_lat)+'\n')
    fid.write('lenlng '+str(self.len_lng)+'\n')
    fid.close()

  def loadData(self, path):
    if os.path.isfile(path + '/data.csv'):
      fid = open(path + '/data.csv', 'r')
      self.elevationGrid = [ list(map(float, x.strip().split(','))) for x in fid.readlines() ]
      fid.close()

  def saveData(self, path):
    fid = open(path + '/data.csv', 'w')
    for line in self.elevationGrid:
      fid.write( ','.join( list(map(str, line)) ) + '\n' )
    fid.close()
  
  def getElevationGrid(self):
    return self.elevationGrid

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
      elevations.extend(elevation_block)  # you can simply put elevations += elevation block
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


# Before using this class especially in the first time:
#   - Make sure the folder hierarchy is correct, namely under folder <Data>/<EleTile>/
#     we should find the folder named by resolution exponent. Or, should
#     execute activate() method once.
#
# Terminology:
#   +--------+
#   |        |
#   |  v  v  | 
#   |        |
#   |  v  v  | 
#   |        |
#   +--------+ = tile,  v in the tile = vertex
#
# (edge length is equal to specified tile resolution)

# CONSTANTS  ----
RESOLUTION_MIN = 3
RESOLUTION_MAX = 5

class ElevationQuerier:

  def __init__(self, resolution=4):
    if isinstance(resolution, int) == False or resolution < RESOLUTION_MIN or resolution > RESOLUTION_MAX:
      raise ValueError('expected variable type of resolution is int with range 3~5')
    self.tileRootFolderPath = '../../Data/EleTile/';
    self.tileResolution = {3:1e-2, 4:1e-3, 5:1e-4}[resolution]
    self.numVerticePerEdge = {3:10, 4:20, 5:10}[resolution] + 1  # including end points
    self.numVerticeInTile = self.numVerticePerEdge * self.numVerticePerEdge
    self.verticeInterval = self.tileResolution / (self.numVerticePerEdge - 1)
    self.tileSetPath = self.tileRootFolderPath + str(resolution) + '/'
    self.verbose = True
    self.tiles = {}

  def query(self, latLngSeries):
    # also support signle point query

    if isinstance(latLngSeries, list) == False:
      latLngSeries = [ latLngSeries ]

    # evaluate what tiles should be queried from Google service
    metaSeries = []  # index corresponding to latLngSeries, store info related to tiles
    tilesToRequest = []
    for latLng in latLngSeries:
      tinfo = self._belongedTileInfo(latLng)
      print(latLng, tinfo)
      metaSeries += [tinfo]  # tinfo[0] is belonged tile file name
      if os.path.isfile(self.tileSetPath + tinfo[0]) == False and tinfo[0] not in tilesToRequest:
        tilesToRequest += [ tinfo[0] ]
    
    blockPoints = []
    eleReturn = []
    errorFlag = False
    try:
      for tile in tilesToRequest:  # tile as tile name
        #print(a, latLng, a[:-6])
        latLng = tuple(map(float, tile[:-6].split('_')))  # split into lat and lng from tile name
        for i in range(self.numVerticePerEdge):
          for j in range(self.numVerticePerEdge):
            blockPoints += [ (latLng[0] + self.verticeInterval * i, latLng[1] + self.verticeInterval * j) ]
            if len(blockPoints) == REQUEST_BLOCKSIZE:
                #print(qp, len(qp))
                if self.verbose:
                  print('query %d-%d of %d' % (len(eleReturn), len(eleReturn)+len(blockPoints), len(tilesToRequest)*self.numVerticeInTile))
                eleReturn += self._requestElevationBlock(blockPoints)
                blockPoints = []
      if len(blockPoints) > 0:
        if self.verbose:
          print('query %d-%d of %d' % (len(eleReturn), len(eleReturn)+len(blockPoints), len(tilesToRequest)*self.numVerticeInTile))
        eleReturn += self._requestElevationBlock(blockPoints)
    except:
      # remember that we got the exception. don't raise right now since we need to save files
      exc_type, exc_value, exc_traceback = sys.exc_info()
      errorFlag = True
      traceback.print_exception(exc_type, exc_value, exc_traceback)
  
    # store succesfully requested tiles into files
    #print(eleReturn, len(eleReturn))
    for i in range( (len(eleReturn) + 1) // self.numVerticeInTile ):  # number of complete tiles downloaded
      #print(i, tilesToRequest[i])
      f = open(self.tileSetPath + tilesToRequest[i], 'w')
      for j in range(self.numVerticePerEdge):
        s = i * self.numVerticeInTile + j * self.numVerticePerEdge  # start index
        line = ",".join( list( map(str, eleReturn[s:(s+self.numVerticePerEdge)]) ) ) + '\n'
        f.write(line)
      f.close()

    # raise the exception if the whole downloaded process is incomplete
    if errorFlag:
      traceback.print_exception(exc_type, exc_value, exc_traceback)
      raise EnvironmentError('get exception from requestElevationBlock(), query abort')

    # to query
    ret = []  # final result to return
    for i in range(len(latLngSeries)):
      latLng = latLngSeries[i]
      meta = metaSeries[i]
      fn = meta[0]  # tile file name
      if fn not in self.tiles:
        f = open(self.tileSetPath + fn)
        content = [ list(map(float, x.strip().split(','))) for x in f.readlines()[:self.numVerticePerEdge] ]
        self.tiles[fn] = content
      dlati, dlngi, latfrac, lngfrac = meta[1], meta[2], meta[3], meta[4] # vertex indice and fractions
      #print(fn, latLng, dlati, dlngi)
      ret += [ self._bilinearInterpolation(latfrac, lngfrac,
          self.tiles[fn][dlati  ][dlngi  ],
          self.tiles[fn][dlati  ][dlngi+1],
          self.tiles[fn][dlati+1][dlngi  ],
          self.tiles[fn][dlati+1][dlngi+1]) ]
    return ret
    
  def setVerbose(self, flag):
    self.verbose = flag

  def currentCacheSize(self):
    return len(self.tiles)

  def activate():
    for resolutionID in range(RESOLUTION_MIN - 1, RESOLUTION_MAX):
      dirName = self.tileRootFolderPath + str(resolutionID)
      if not os.path.exists(dirName):
        os.makedirs(dirName)


  def _requestElevationBlock(self, block_pts):
    # make sure the request is short enough
    if len(block_pts) > REQUEST_BLOCKSIZE:
      raise ValueError('requested block is too large')

    # convert positions to string
    pts_str = ''
    for p in block_pts:
      #pts_str += str(p[0]) + "," + str(p[1])
      pts_str += '%.6f,%.6f' % (p[0], p[1])
      pts_str += "|"
    # remove final "|"
    pts_str = pts_str[0:-1]

    # request elevations
    elvtn_args = {
      'locations': pts_str,
    }

    requestAttempt = 0
    goodResponse = False

    while requestAttempt < REQUEST_MAXATTEMPTS and not goodResponse:
      requestAttempt += 1

      url = ELEVATION_BASE_URL + '?' + urllibParse.urlencode(elvtn_args)
      response = simplejson.load(urllibRequest.urlopen(url))
      # parse elevations
      elevations = []
      for resultset in response['results']:
        elevations.append(resultset['elevation'])

      if len(elevations) == len(block_pts):
        goodResponse = True
        return elevations

    raise EnvironmentError('No response from google after %d attempts' % REQUEST_MAXATTEMPTS)

  def _belongedTileInfo(self, latLng):
    # return (filename,
    #         ind of point to immediate south lat line in this tile,
    #         ind of point to immediate west lng line in this tile,
    #         fraction of <point to first vertex to the south> / <vertice interval>,
    #         fraction of <point to first vertex to the west> / <vertice interval>)

    # assume tileResolution=1e-3 and verticeInterval=1e-4
    # => lat/lng = -118.325479 = -118.326 + 0.0001 * 5   + 0.000021
    #                          = tileLng  + deltaTileLng
    #                          =    "     + vertexLng    + deltaVertexLng    
    deltaTileLat = latLng[0] % self.tileResolution  
    deltaTileLng = latLng[1] % self.tileResolution
    tileLat = latLng[0] - deltaTileLat
    tileLng = latLng[1] - deltaTileLng
    vertexLatInd = int(deltaTileLat // self.verticeInterval)
    vertexLngInd = int(deltaTileLng // self.verticeInterval)
    deltaVertexLat = deltaTileLat % self.verticeInterval
    deltaVertexLng = deltaTileLng % self.verticeInterval
    fracDeltaVertexLat = deltaVertexLat / self.verticeInterval
    fracDeltaVertexLng = deltaVertexLng / self.verticeInterval
    return ("%.6lf_%.6lf.etile" % (tileLat, tileLng), 
        vertexLatInd, vertexLngInd, fracDeltaVertexLat, fracDeltaVertexLng)

  def _bilinearInterpolation(self, latf, lngf, e1a, e1b, e2a, e2b):
    #  <e2a> ------ <e2b>
    #    |            |
    #    |   *        |     * at (latf, lngf) value range within (0,0) to (1,1)
    #    |            |
    #  <e1a> ------ <e1b>
    #print(latf, lngf, e1a, e1b, e2a, e2b)
    e1c = self._interpolation(e1a, e1b, lngf)    # e1a -- e1c ------ e1b
    e2c = self._interpolation(e2a, e2b, lngf)
    return self._interpolation(e1c, e2c, latf)

  def _interpolation(self, va, vb, f):  # value a, value b, fraction (0 = va, 1 = vb)
    return va + (vb - va) * f

if __name__ == '__main__':
    # testing bilinear interpolation
    pass

