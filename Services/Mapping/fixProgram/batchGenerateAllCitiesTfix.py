import os
import sys

filenames = [
'Albuquerque_6x6.osm',
'Atlanta_6x6.osm',
'Austin_6x6.osm',
'Baltimore_6x6.osm',
'Boston_6x6.osm',
'Charlotte_6x6.osm',
'Chicago_6x6.osm',
'Cleveland_6x6.osm',
'Columbus_6x6.osm',
'Dallas_6x6.osm',
'Denver_6x6.osm',
'Detroit_6x6.osm',
'El_Paso_6x6.osm',
'Fort_Worth_6x6.osm',
'Fresno_6x6.osm',
'Houston_6x6.osm',
'Indianapolis_6x6.osm',
'Jacksonville_6x6.osm',
'Kansas_City_2_6x6.osm',
'Kansas_City_6x6.osm',
'Las_Vegas_6x6.osm',
'Long_Beach_6x6.osm',
'Los_Angeles_6x6.osm',
'Memphis_6x6.osm',
'Mesa_6x6.osm',
'Milwaukee_6x6.osm',
'Nashville_6x6.osm',
'New_Orleans_6x6.osm',
'New_York_6x6.osm',
'Oklahoma_City_6x6.osm',
'Omaha_6x6.osm',
'Philadelphia_6x6.osm',
'Phoneix_6x6.osm',
'Portland_6x6.osm',
'Sacramento_6x6.osm',
'San_Antonio_6x6.osm',
'San_Diego_6x6.osm',
'San_Francisco_6x6.osm',
'San_Jose_6x6.osm',
'San_Juan_6x6.osm',
'Seattle_6x6.osm',
'Tucson_6x6.osm',
'Virginia_Beach_6x6.osm',
'Washington_6x6.osm',
#'ucla_3x3.osm',
#'ucla_4x4.osm',
#'ucla_5x5.osm',
#'ucla_small.osm',
]

acceptedIdxs = range(len(filenames))
if len(sys.argv) > 1:
	acceptedIdx = [ int(x) for x in sys.argv[1:] ]

for idx, filename in list(enumerate(filenames)):
    if idx in acceptedIdxs:
        print('idx=' + str(idx))
        cmd = 'python3 tmp_script.py ' + x
        print(cmd)
        os.system(cmd)
