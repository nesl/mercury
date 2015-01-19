import math
import os
import ElevationService as ES
import sys
import traceback

# WARNING: This file should be obseleted and shouldn't be used anymore

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
    qret = []
    errorFlag = False
    try:
        for a in ask:
            #print(a, latLng, a[:-6])
            latLng = tuple(map(float, a[:-6].split('_')))
            for i in range(11):
                for j in range(11):
                    qp += [ (latLng[0] + 1e-5 * i, latLng[1] + 1e-5 * j) ]
                    if len(qp) == ES.REQUEST_BLOCKSIZE:
                        #print(qp, len(qp))
                        print('query %d-%d of %d' % (len(qret), len(qret)+len(qp), len(ask)*121))
                        qret += ES.requestElevationBlock(qp)
                        qp = []
        if len(qp) > 0:
            print('query %d-%d of %d' % (len(qret), len(qret)+len(qp), len(ask)*121))
            qret += ES.requestElevationBlock(qp)
    except:
        exc_type, exc_value, exc_traceback = sys.exc_info()
        errorFlag = True
        traceback.print_exception(exc_type, exc_value, exc_traceback)

    print(qret, len(qret))
    for i in range( (len(qret) + 1) // 121 ):
        print(i, ask[i])
        f = open(ROOT_TILE_FOLDER + ask[i], 'w')
        for j in range(11):
            s = i * 121 + j * 11
            line = ",".join( list( map(str, qret[s:(s+11)]) ) ) + '\n'
            f.write(line)
        f.close()
    if errorFlag:
        traceback.print_exception(exc_type, exc_value, exc_traceback)
        raise EnvironmentError('Get error from ElevationService')

    # to query
    ret = []
    tiles = {}
    for latLng in latLngSeries:
        fn = _belongTileName(latLng)
        fLatLng = tuple(map(float, fn[:-6].split('_')))
        if fn not in tiles:
            f = open(ROOT_TILE_FOLDER + fn)
            content = [ list(map(float, x.strip().split(','))) for x in f.readlines()[:11] ]
            tiles[fn] = content
        dlat = latLng[0] - fLatLng[0]
        dlng = latLng[1] - fLatLng[1]
        dlati = int(dlat * 1e5)
        dlngi = int(dlng * 1e5)
        print(fn, fLatLng, latLng, dlati, dlngi)
        #lat1 = fLatLng[0] + (dlati    ) * 1e-5
        #lat2 = fLatLng[0] + (dlati + 1) * 1e-5
        #lnga = fLatLng[1] + (dlngi    ) * 1e-5
        #lngb = fLatLng[1] + (dlngi + 1) * 1e-5
        ret += [ _bilinearInterpolation(0, 1e-5, 0, 1e-5,
                    tiles[fn][dlati  ][dlngi  ],
                    tiles[fn][dlati  ][dlngi+1],
                    tiles[fn][dlati+1][dlngi  ],
                    tiles[fn][dlati+1][dlngi+1],
                    dlat - dlati * 1e-5, dlng - dlngi * 1e-5) ]
    return ret

def _belongTileName(latLng):
    return "%.4lf_%.4lf.etile" % ( _nearestNumber(latLng[0])[0], _nearestNumber(latLng[1])[0] )

def _nearestNumber(n):
    t = math.floor( n * 1e4 ) / 1e4
    return (t, t+1e-4)

def _bilinearInterpolation(lat1, lat2, lnga, lngb, e1a, e1b, e2a, e2b, latq, lngq):
    print(lat1, lat2, lnga, lngb, e1a, e1b, e2a, e2b, latq, lngq)
    e1c = _interpolation(e1a, e1b, lnga, lngb, lngq)
    e2c = _interpolation(e2a, e2b, lnga, lngb, lngq)
    return _interpolation(e1c, e2c, lat1, lat2, latq)

def _interpolation(va, vb, xa, xb, x):
    return (va * (xb - x) + vb * (x - xa)) / (xb - xa)
