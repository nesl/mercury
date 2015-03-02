import sys
import csv
import math
import os

def getBoundedBox(center_lat, center_lon, miles):
    df = miles/69.0
    dl = df/math.cos(math.radians(center_lat))
    return [center_lat + df, center_lon - dl, center_lat - df, center_lon + dl]

# Location of city centers:
citylocs = 'city_centers.csv'

# Acquire city name
filename = sys.argv[1]
cityfile = filename[0:filename.index('_6x6')]
cityname = cityfile.split('/')[-1].replace('_',' ')
#cityname = ''.join(c for c in cityname if not c.isdigit())
cityname = ''.join(c for c in cityname)

scale = int(sys.argv[2])
if scale >= 6 or scale < 1:
    print "Scaling parameter must be less than 6, and positive."
    sys.exit(1)

bounds = []

#print cityname
fd = open(citylocs, 'r')
data = csv.reader(fd)
for row in data:
    #if row[0][0:6] == 'Kansas':
    #    print row, cityname
    if(row[0] == cityname):
        bounds = getBoundedBox(float(row[1]),float(row[2]),float(scale) / 2.0)
        break

if len(bounds) == 0:
    print "Unable to find city center, exiting."
    sys.exit(1)

nd = open('/tmp/rescale.xml', 'w')
nd.write('<result>\n')


pd = open(filename, 'r')
tfixdata = csv.reader(pd)
nrow = list()

for row in tfixdata:
    nrow = []
    elems = len(row)
    if elems % 3 == 0:
        nodes = elems/3
        outFlag = False  # drops the whole segment if one node falls outside
        for i in range(0,nodes):
            lat = float(row[i*3 + 1])
            lon = float(row[i*3 + 2])
            if not (lat < bounds[0] and lat > bounds[2] and lon > bounds[1] and lon < bounds[3]):
                outFlag = True
        if not outFlag:
            nd.write('  <way id="1">\n')
            for i in range(0,nodes):
                nd.write('    <nd id="' + row[i*3+0] + '" lat="' + row[i*3+1] + '" lon="' + row[i*3+2] + '"/>\n')
            nd.write('  </way>\n')
    else:
        print "Node count not divisible by 3, poor formatting?"
        sys.exit(2)

fd.close()

nd.write('</result>\n')
nd.close()

cityfile += '_{0}x{0}.tfix'.format(str(scale))
cmd = 'python ../fixProgram/fix.py < /tmp/rescale.xml > ' + cityfile
print(cmd)
os.system(cmd)
