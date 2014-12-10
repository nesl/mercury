# imports
from ElevationService import ElevationRequester

filename = 'baro_n501_20141208_211251'    # sample: baro_n501_20141208_211251, without TWO levels of extension plz...

rootDir = '../../Data/forMat/'

src = rootDir + filename + '.gps.csv'
dst = rootDir + filename + '.gpsele.csv'

# create elevation requester
rq = ElevationRequester()
rq.setSaveName('ttmp')

f = open(src)
lines = [ x.strip().split(',') for x in f.readlines() ]
f.close()

lines = [ x for x in lines if x[-1] == '0' ]
queryList = [ ( float(x[1]), float(x[2]) ) for x in lines ]

rq.setPositions(queryList)
rq.requestElevations()

f = open('storage/ttmp.csv')
res = f.readlines()
f.close()

assert len(lines) == len(res)

f = open(dst, 'w')
for (q, r) in zip(lines, res):
	f.write( ",".join( tuple( q[0:3] + [ r.strip().split(',')[-1] ] ) ) + '\n')
f.close()
