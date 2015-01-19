import simplejson
import numpy as np
import os
from ElevationService import *



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



# for downloading an elevation Grid (rectangle of points)
class ElevationGridRequester:

  def __init__(self, latlng_start, latlng_stop, resolution):

    self.res_latlng = resolution
    self.elevationGrid = []
    self.elevationService = ElevationQuerier()  # with default resolution 5e-5

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

  # TODO: consider to remove truncate flag since it's no longer need to
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
      elevations = self.elevationService.query(block_pts)
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

