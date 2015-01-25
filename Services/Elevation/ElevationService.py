
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

# The correctionness of this file has been examined in the following ways and
# thus the output of the query() should be correct:
#   - compared the created tiles with previous downloaded tiles (with previous
#     program) and the differences of all the vertice are within 1e-9
#   - have been tested in testSunsetInterpolationES.py. inside this test script,
#     it both query from ElevationGridQuerier and this file and plot on the
#     matlab and has similar elevation trend (the trajectory includes 2 hills)
#   - also be called from ElevationGridRequester and successfully output the
#     result (but didn't check the result correctness)
#   - also tested all the possible resolutions


# --- CONSTANTS ---
EARTH_RAD_KM = 6371
#MAX_REQUEST_POINTS = 600000
REQUEST_BLOCKSIZE = 75
REQUEST_MAXATTEMPTS = 20

RESOLUTION_MIN = 3
RESOLUTION_MAX = 5

# --- HTTP API URLs ---
ELEVATION_BASE_URL = 'https://maps.googleapis.com/maps/api/elevation/json'
CHART_BASE_URL = 'http://chart.apis.google.com/chart'



class ElevationRequester:

  def __init__(self, resolution=4):
    # Check resolution sanity
    if isinstance(resolution, int) == False or resolution < RESOLUTION_MIN or resolution > RESOLUTION_MAX:
      raise ValueError('expected variable type of resolution to be int with range 3-5')
    # Root folder for tile storage
    self.tileRootFolderPath = '../../Data/EleTile/';
    # tile meta information
    self.tileResolution = {3:1e-2, 4:1e-3, 5:1e-4}[resolution]
    self.numVertexPerEdge = {3:10, 4:20, 5:10}[resolution] + 1  # including end points
    self.numVertexInTile = self.numVertexPerEdge**2
    self.vertexInterval = self.tileResolution / (self.numVertexPerEdge - 1)
    # cache subpath
    self.tileSetPath = self.tileRootFolderPath + str(resolution) + '/'
    # by default, we'll be verbose
    self.verbose = True
    self.tiles = {}

  def query(self, latLngSeries):
    # also support signle point query
    # (force input to be list)
    if isinstance(latLngSeries, list) == False:
      latLngSeries = [ latLngSeries ]

    # index corresponding to latLngSeries, store info related to tiles
    metaSeries = [] 
    # What tiles should be queried from Google service
    tilesToRequest = []

    # retrieve appropriate tile data
    for latLng in latLngSeries:
      tileinfo = self._getTileInfo(latLng)
      #print(latLng, tinfo)
      metaSeries += [tileinfo]
      # if we don't have this tile downloaded, we need to ask Google for it
      #    (tileinfo[0] is tile file name)
      if os.path.isfile(self.tileSetPath + tileinfo[0]) == False and tileinfo[0] not in tilesToRequest:
        tilesToRequest += [ tileinfo[0] ]
    
    # -- REQUEST ALL TILES --
    blockPoints = []
    eleReturn = []
    errorFlag = False
    try:
      for tile in tilesToRequest:
        # gather points to request for this tile
        #print(a, latLng, a[:-6])
        latLng = tuple(map(float, tile[:-6].split('_')))  # split into lat and lng from tile name
        for i in range(self.numVertexPerEdge):
          for j in range(self.numVertexPerEdge):
            blockPoints += [ (latLng[0] + self.vertexInterval * i, latLng[1] + self.vertexInterval * j) ]
            # if we've gathered enough points, request this block
            if len(blockPoints) == REQUEST_BLOCKSIZE:
                #print(qp, len(qp))
                if self.verbose:
                  print('query %d-%d of %d' % (len(eleReturn), len(eleReturn)+len(blockPoints), len(tilesToRequest)*self.numVertexInTile))
                eleReturn += self._requestElevationBlock(blockPoints)
                blockPoints = []

      # get the left over (underfull) block after all tiles have been run through
      if len(blockPoints) > 0:
        if self.verbose:
          print('query %d-%d of %d' % (len(eleReturn), len(eleReturn)+len(blockPoints), len(tilesToRequest)*self.numVertexInTile))
        eleReturn += self._requestElevationBlock(blockPoints)
    except:
      # remember that we got the exception. don't raise right now since we need to save files
      exc_type, exc_value, exc_traceback = sys.exc_info()
      errorFlag = True
      traceback.print_exception(exc_type, exc_value, exc_traceback)
  
    # store succesfully requested tiles into files
    #print(eleReturn, len(eleReturn))
    for i in range( (len(eleReturn) + 1) // self.numVertexInTile ):  # number of complete tiles downloaded
      #print(i, tilesToRequest[i])
      f = open(self.tileSetPath + tilesToRequest[i], 'w')
      for j in range(self.numVertexPerEdge):
        s = i * self.numVertexInTile + j * self.numVertexPerEdge  # start index
        line = ",".join( list( map(str, eleReturn[s:(s+self.numVertexPerEdge)]) ) ) + '\n'
        f.write(line)
      f.close()

    # raise the exception if the whole downloaded process is incomplete
    if errorFlag:
      traceback.print_exception(exc_type, exc_value, exc_traceback)
      raise EnvironmentError('got exception from requestElevationBlock(), query aborted (and saved)')

    # to query
    ret = []  # final result to return
    for i in range(len(latLngSeries)):
      latLng = latLngSeries[i]
      meta = metaSeries[i]
      fn = meta[0]  # tile file name
      if fn not in self.tiles:
        f = open(self.tileSetPath + fn)
        content = [ list(map(float, x.strip().split(','))) for x in f.readlines()[:self.numVertexPerEdge] ]
        self.tiles[fn] = content
      dlati, dlngi, latfrac, lngfrac = meta[1], meta[2], meta[3], meta[4] # vertex index and fractions
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

  def _getTileInfo(self, latLng):
    # return (filename,
    #         ind of point to immediate south lat line in this tile,
    #         ind of point to immediate west lng line in this tile,
    #         fraction of <point to first vertex to the south> / <vertice interval>,
    #         fraction of <point to first vertex to the west> / <vertice interval>)

    # assume tileResolution=1e-3 and vertexInterval=1e-4
    # => lat/lng = -118.325479 = -118.326 + 0.0001 * 5   + 0.000021
    #                          = tileLng  + deltaTileLng
    #                          =    "     + vertexLng    + deltaVertexLng    
    deltaTileLat = latLng[0] % self.tileResolution  
    deltaTileLng = latLng[1] % self.tileResolution
    tileLat = latLng[0] - deltaTileLat
    tileLng = latLng[1] - deltaTileLng
    vertexLatInd = int(deltaTileLat // self.vertexInterval)
    vertexLngInd = int(deltaTileLng // self.vertexInterval)
    deltaVertexLat = deltaTileLat % self.vertexInterval
    deltaVertexLng = deltaTileLng % self.vertexInterval
    fracDeltaVertexLat = deltaVertexLat / self.vertexInterval
    fracDeltaVertexLng = deltaVertexLng / self.vertexInterval
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

