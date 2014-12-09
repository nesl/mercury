# imports
from ElevationService import ElevationRequester

def interpolation(laloa, lalob, res):
    #laloa and lalob are lat-lng tuples
    dla = lalob[0] - laloa[0]
    dlo = lalob[1] - laloa[1]
    d = (dla * dla + dlo * dlo) ** 0.5
    n = int(d / res) + 1
    re = []
    for i in range(n):
        p = float(i) / n
        re += [ (laloa[0] + dla * p, laloa[1] + dlo * p) ]
    return re


# get strathmore path coords
pathC = [ '34.0685657,-118.4489289',
        '34.0684706,-118.4490809',
        '34.0683569,-118.4491847',
        '34.0672971,-118.4497256',
        '34.0662627,-118.4500183',
        '34.0660021,-118.4501852',
        '34.0658194,-118.4503613',
        '34.0656797,-118.4505131',
        '34.0655404,-118.4506620',
        '34.0654535,-118.4507109',
        '34.0653544,-118.4507333',
        '34.0649488,-118.4507647',
        '34.0645550,-118.4507985',
        '34.0645004,-118.4508279',
        '34.0643667,-118.4509593',
        '34.0642947,-118.4511577',
        '34.0642761,-118.4514100',
        '34.0643092,-118.4518787',
        '34.0642906,-118.4521483',
        '34.0642263,-118.4524317',
        '34.0641333,-118.4527160',
        '34.0640850,-118.4528660',
        '34.0639799,-118.4531040']

resolution = 1e-5

# create elevation requester
rq = ElevationRequester()
rq.setName('strathmore_path_1e-5')
positions_added = 0
pathC = [ map(float, x.split(',')) for x in pathC ]
pathD = []
for i in range(len(pathC) - 1):
#for i in range(2):
    pathD += interpolation( pathC[i], pathC[i+1], resolution )
pathD += [ pathC[-1] ]
rq.setPositions(pathD)

rq.requestElevations()




