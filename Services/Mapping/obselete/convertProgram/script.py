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

osmName = 'ucla.osm'

inFile = '../osmFiles/' + osmName
if len(osmName.split('.')) == 1:
    osmNameWoExt = osmName
else:
    osmNameWoExt = osmName[:-(1+len(osmName.split('.')[-1]))]
outRootDir = '../../../Data/trajectorySets/'
outDir = outRootDir + osmNameWoExt + '/'

#if outDir[-1] != '/':
#    outDir += '/'

print 'input file = ' + inFile
print 'output folder = ' + outDir
print ' '

f = open('/tmp/in', 'w')
f.write('<in>' + inFile + '</in>');
f.close()

cmd = 'basex findWaySummary.xq > /tmp/summary.xml'
print 'CMD: ' + cmd
os.system(cmd)

tfname = outRootDir + osmNameWoExt + '_summary.txt'
print 'ACTION: convert /tmp/summary.xml to ' + tfname
f = open('/tmp/summary.xml', 'r')
lines = f.readlines()
f.close()
f = open(tfname, 'w')
for i in range(1, len(lines) - 1):
    match = re.match(r'  <rec id="(\d+)" name="(.+)"\/>', lines[i])
    if match:
        print >>f, match.group(1)
        print >>f, match.group(2)
f.close()

cmd = 'mkdir -p ' + outDir
print 'CMD: ' + cmd
os.system(cmd)

cmd = 'rm -f ' + outDir + '/*'
print 'CMD: ' + cmd
os.system(cmd)

cmd = 'basex findWayTrajectory.xq > /tmp/wayDetail.xml'
print 'CMD: ' + cmd
os.system(cmd)

print 'ACTION: convert wayDetail into individual files stored under ' + outDir
f = open('/tmp/wayDetail.xml')
lines = f.readlines()
f.close()
for i in range(1, len(lines)):
    match = re.match(r'  <way id="(\d+)">', lines[i])
    if match:
        name = match.group(1)
        f = open('/tmp/t', 'w');
        cnt = 0
        continue
    
    match = re.match(r'    <nd id="(\d+)" lat="([0-9\.\-]+)" lon="([0-9\.\-]+)"\/>', lines[i])
    if match:
        f.write(match.group(2) + ',' + match.group(3) + '\n')
        cnt += 1
        continue

    if re.match(r'  <\/way>', lines[i]):
        f.close()
        if cnt > 0:
            cmd = 'mv /tmp/t ' + outDir + name
            os.system(cmd)




