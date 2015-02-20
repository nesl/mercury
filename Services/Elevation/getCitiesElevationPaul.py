from ElevationService import *
from TileRequestService import *
import csv, math, os.path

def get_box(center_lat, center_lon):
	miles_across = 10.0
	df = miles_across/69.0
	dl = df/math.cos(math.radians(center_lat))
	return [(center_lat + df, center_lon - dl), (center_lat - df, center_lon + dl)]

major_cities = './storage/filter_paul.csv'

e = TileRequester(4)

csvfile = open(major_cities,'r')
city_list = csv.reader(csvfile)

cnt = 1
for city_data in city_list:
	print('Getting data for ' + city_data[0] + ' (idx=' + str(cnt) + ')')
	e.requestTiles((float(city_data[1]),float(city_data[2]),3));
	cnt += 1
