import math
import os
import ElevationService as ES
import sys
import traceback

ROOT_TILE_FOLDER = '../../Data/EleTile/'

def query(latLngSeries):
    # also support signle point query

    if isinstance(latLngSeries, list) == False:
       latLngSeries = [ latLngSeries ]

    ask = []
    for latLng in latLngSeries:
        fn = _belongTileName(latLng)
        if os.path.isfile(ROOT_TILE_FOLDER + fn) == False and fn not in ask:
            ask += [fn]
    
    qp = []
    ret = []
    errorFlag = False
    try:
        for a in ask:
            #print(a, latLng, a[:-6])
            latLng = tuple(map(float, a[:-6].split('_')))
            for i in range(10):
                for j in range(10):
                    qp += [ (latLng[0] + 1e-5 * i, latLng[1] + 1e-5 * j) ]
                    if len(qp) == ES.REQUEST_BLOCKSIZE:
                        #print(qp, len(qp))
                        print('query %d-%d of %d' % (len(ret), len(ret)+len(qp), len(ask)*100))
                        ret += ES.requestElevationBlock(qp)
                        qp = []
        if len(qp) > 0:
            print('query %d-%d of %d' % (len(ret), len(ret)+len(qp), len(ask)*100))
            ret += ES.requestElevationBlock(qp)
    except:
        exc_type, exc_value, exc_traceback = sys.exc_info()
        errorFlag = True
        traceback.print_exception(exc_type, exc_value, exc_traceback)

    print(ret, len(ret))
    for i in range( (len(ret) + 1) // 100 ):
        print(i, ask[i])
        f = open(ROOT_TILE_FOLDER + ask[i], 'w')
        for j in range(10):
            s = i * 100 + j * 10
            line = ",".join( list( map(str, ret[s:(s+10)]) ) ) + '\n'
            f.write(line)
        f.close()
    if errorFlag:
        traceback.print_exception(exc_type, exc_value, exc_traceback)
        raise EnvironmentError('Get error from ElevationService')

    # to query


def _belongTileName(latLng):
    return "%.4lf_%.4lf.etile" % ( _nearestNumber(latLng[0])[0], _nearestNumber(latLng[1])[0] )

def _nearestNumber(n):
    t = math.floor( n * 1e4 ) / 1e4
    return (t, t+1e-4)

# DON'T touch the following ----------------------------
cind = 0
ii = 0
jj = 0
curTile = [ [range(10)] for x in range(10) ]
qp = []
