import os
import sys

filenames = [
'Albuquerque_6x6.tfix',
'Atlanta_6x6.tfix',
'Austin_6x6.tfix',
'Baltimore_6x6.tfix',
'Boston_6x6.tfix',
'Charlotte_6x6.tfix',
'Chicago_6x6.tfix',
'Cleveland_6x6.tfix',
'Columbus_6x6.tfix',
'Dallas_6x6.tfix',
'Denver_6x6.tfix',
'Detroit_6x6.tfix',
'El_Paso_6x6.tfix',
'Fort_Worth_6x6.tfix',
'Fresno_6x6.tfix',
'Houston_6x6.tfix',
'Indianapolis_6x6.tfix',
'Jacksonville_6x6.tfix',
'Kansas_City_2_6x6.tfix',
'Kansas_City_6x6.tfix',
'Las_Vegas_6x6.tfix',
'Long_Beach_6x6.tfix',
'Los_Angeles_6x6.tfix',
'Memphis_6x6.tfix',
'Mesa_6x6.tfix',
'Milwaukee_6x6.tfix',
'Nashville_6x6.tfix',
'New_Orleans_6x6.tfix',
'New_York_6x6.tfix',
'Oklahoma_City_6x6.tfix',
'Omaha_6x6.tfix',
'Philadelphia_6x6.tfix',
'Phoneix_6x6.tfix',
'Portland_6x6.tfix',
'Sacramento_6x6.tfix',
'San_Antonio_6x6.tfix',
'San_Diego_6x6.tfix',
'San_Francisco_6x6.tfix',
'San_Jose_6x6.tfix',
'San_Juan_6x6.tfix',
'Seattle_6x6.tfix',
'Tucson_6x6.tfix',
#'ucla_3x3.tfix',
#'ucla_4x4.tfix',
#'ucla_5x5.tfix',
#'ucla_small.tfix',
'Virginia_Beach_6x6.tfix',
'Washington_6x6.tfix'
]

startIdx = 0
stopIdx = len(filenames)
if len(sys.argv) >= 2:
    startIdx = int(sys.argv[1])

if len(sys.argv) >= 3:
    stopIdx = int(sys.argv[2])

idx = 0
for x in filenames:
    if startIdx <= idx and idx <= stopIdx:
        print('idx=' + str(idx))
        cmd = 'python3 makeElevSegMap.py ' + x
        print(cmd)
        os.system(cmd)
    idx += 1
