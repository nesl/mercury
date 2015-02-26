import os

def do():
    accExt = ['acc', 'baro', 'gps', 'gyro', 'mag', 'offset', 'event']  # accepted extension

    cmd = 'adb shell ls storage/sdcard0/ > tmp'
    os.system(cmd)

    f = open('tmp')
    names = [ x.strip() for x in  f.readlines() if x[:5] == 'baro_']
    names = [ x for x in names if len(x.split('.')[0]) == 25 and x.split('.')[-1] in accExt]
    f.close()

    os.system('rm tmp')
    return names
