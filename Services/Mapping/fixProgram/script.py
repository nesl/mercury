#!/usr/bin/python

import os
import sys
import re

# file name unified by the following rule:
# 1. always save the osm under ../osmFiles directory
# 2. the result automatically generate to ../trajectorySets
# 3. change variable "osmName"

# also, please scroll down the very bottom to see what's the next step

osmName = 'ucla_5x5.osm'   # sample: 'ucla.osm'
optionAllowLoop = False   # most of the cases are building bounding boxes



# support system parameters
if len(sys.argv) >= 2:
	osmName = sys.argv[1]
if len(sys.argv) >= 3:
	optionAllowLoop = (sys.argv[2] == '1')

inFile = '../../../Data/osmFiles/' + osmName
if len(osmName.split('.')) == 1:
    osmNameWoExt = osmName
else:
    osmNameWoExt = osmName[:-(1+len(osmName.split('.')[-1]))]
outRootDir = '../../../Data/trajectorySets/'
outFile = outRootDir + osmNameWoExt + '.tfix'


print('input file = ' + inFile)
print('output file = ' + outFile)
print('')

f = open('/tmp/in', 'w')
f.write('<in>' + inFile + '</in>');
f.close()

# the following command can be slow. a 3x3 mile^2 area takes 53 seconds to generate the result.
xmlWayDetail = outRootDir + 'originOfLife/' + osmNameWoExt + '.xml'
cmd = 'basex findWayTrajectory.xq > ' + xmlWayDetail
print('CMD: ' + cmd)
os.system(cmd)

cmd = 'python fix.py ' + ('-a' if optionAllowLoop else '') + ' < ' + xmlWayDetail + ' > ' + outFile 
print('CMD: ' + cmd)
os.system(cmd)

# the next step should be executing the python3 ../makeElevSegMap.py with the input
# parameter outFile, but because of the relative folder path issue, integrating
# makeElevSegMap.py into this code needs to make big changes. So at this stage,
# we still stay on manually executing this script.
