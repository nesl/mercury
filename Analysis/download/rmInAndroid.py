#!/usr/bin/python

import os
import sys
import fileFilter

names = fileFilter.do()
for name in names:
	print '<adb> rm storage/sdcard0/' + name
print "\nWARNING: are you sure to remove all the LeLogger data? [begin with y]"

line = sys.stdin.readline()
if (line[0].lower() != 'y'):
	print 'abort...'
	exit()

for name in names:
	cmd = 'adb shell rm storage/sdcard0/' + name
	os.system(cmd)


