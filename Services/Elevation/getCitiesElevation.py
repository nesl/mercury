from ElevationService import *
from TileRequestService import *
import csv, math, os.path
import sys

def get_box(center_lat, center_lon):
	miles_across = 10.0
	df = miles_across/69.0
	dl = df/math.cos(math.radians(center_lat))
	return [(center_lat + df, center_lon - dl), (center_lat - df, center_lon + dl)]

major_cities = './storage/filter.csv'

e = TileRequester(4)

csvfile = open(major_cities,'r')
city_list = csv.reader(csvfile)

if len(sys.argv) == 1:
	dividor = 1
	remainder = 0
else:
	dividor = int(sys.argv[1])
	remainder = int(sys.argv[2])

city_idx = 0
for city_data in city_list:
	if city_idx % dividor == remainder:
		print('Getting data for ' + city_data[0] + ' (idx=' + str(city_idx) + ')')
		e.requestTiles((float(city_data[1]),float(city_data[2]),3));
	city_idx += 1
