import simplejson

try:
  import urllib.parse as urllibParse
except ImportError:
  import urllib as urllibParse

try:
  import urllib.request as urllibRequest
except ImportError:
  import urllib as urllibRequest

ELEVATION_BASE_URL = 'https://maps.googleapis.com/maps/api/elevation/json'
CHART_BASE_URL = 'http://chart.apis.google.com/chart'

def roundTo6thDigit(n):
  return round(n, 6)

class ElevationRequester:
  BLOCKSIZE = 75

  def __init__(self):
    self.cachename = 'default'
    self.data = {}
    self.positions = []

  def setName(self, name):
    self.cachename = name

  def setPositions(self, positions):
    self.positions = positions

  def addPosition(self, xy):
    self.positions.append(xy)

  def requestElevations(self):
    # since google elevation api doesn't allow us to access very fine-grained
    # (my test is up to 6th digit after floating point, which is cm level),
    # the following line is just truncate the tailing digits
    self.positions = [ map(roundTo6thDigit, x) for x in self.positions ]

    self.fid = open('cache/'+str(self.cachename)+".csv", 'w')

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
    rq = ElevationRequester()
    rq.setName('test')
    rq.addPosition( (36.578581,-118.291994) )
    rq.addPosition( (36.23998,-116.83171) )
    rq.requestElevations()
