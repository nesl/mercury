# imports
import ElevationService

filename = 'baro_n501_20141128_120042'    # sample: baro_n501_20141208_211251, without TWO levels of extension plz...

rootDir = '../../Data/forMat/'

src = rootDir + filename + '.gps.csv'
dst = rootDir + filename + '.gpsele.csv'

# create elevation requester

f = open(src)
lines = [ x.strip().split(',') for x in f.readlines() ]
f.close()

lines = [ x for x in lines if x[-1] == '0' ]
queryList = [ ( float(x[1]), float(x[2]) ) for x in lines ]
res = ElevationService.requestElevations(queryList)

assert len(lines) == len(res)

f = open(dst, 'w')
for (q, r) in zip(lines, res):
	f.write( ",".join( tuple( q[0:3] + [ str(r) ] ) ) + '\n')
f.close()
