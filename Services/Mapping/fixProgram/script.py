#!/usr/bin/python

import os
import sys
import re

# file name unified by the following rule:
# 1. always save the osm under ../osmFiles directory
# 2. the result automatically generate to ../trajectorySets
# 3. change variable "osmName"

#inFile = '../osmFiles/ucla.osm'
#outDir = '../trajectorySets/ucla/'

osmName = 'ucla.osm'   # sample: 'ucla.osm'

inFile = '../osmFiles/' + osmName
if len(osmName.split('.')) == 1:
    osmNameWoExt = osmName
else:
    osmNameWoExt = osmName[:-(1+len(osmName.split('.')[-1]))]
outRootDir = '../../../Data/trajectorySetsFix/'
outFile = outRootDir + osmNameWoExt + '.tfix'


print 'input file = ' + inFile
print 'output file = ' + outFile
print ' '

f = open('/tmp/in', 'w')
f.write('<in>' + inFile + '</in>');
f.close()

cmd = 'basex findWayTrajectory.xq > /tmp/wayDetail.xml'
print 'CMD: ' + cmd
os.system(cmd)

cmd = 'python fix.py < /tmp/wayDetail.xml > ' + outFile 
print 'CMD: ' + cmd
os.system(cmd)


