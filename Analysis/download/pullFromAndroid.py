#!/usr/bin/python

import fileFilter
import os

names = fileFilter.do()
for name in names:
    src = 'storage/sdcard0/' + name
    tmp = '/tmp/baro'
    dst = '../forMat/' + name + '.csv'
    cmd = 'adb pull ' + src + ' ' + dst;
    print 'CMD=' + cmd
    os.system(cmd)
    #cmd = 'sed \'$d\' ' + tmp + ' > ' + dst
    #print cmd
        


