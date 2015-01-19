import simplejson
import numpy as np
import os


# RECOMMEND to obselete this file


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


