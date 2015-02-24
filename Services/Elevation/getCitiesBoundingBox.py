from ElevationService import *
from TileRequestService import *
import csv, math, os.path

miles_across = 3.0;

def get_box(center_lat, center_lon, _miles_across):
	df = _miles_across/69.0
	dl = df/math.cos(math.radians(center_lat))
	# according to Prashanth's script [NW_LAT, NW_LONG, SE_LAT, SE_LONG] oh he already handle it!
	return [(center_lat + df - 0.001, center_lon - dl + 0.001), (center_lat - df + 0.001, center_lon + dl - 0.001)]

major_cities = './storage/filter_bo.csv'

csvfile = open(major_cities,'r')
city_list = csv.reader(csvfile)

f = open('./storage/to_matlab.txt', 'w')


for city_data in city_list:
	print('Getting data for ' + city_data[0])
	box = get_box(float(city_data[1]), float(city_data[2]), miles_across)
	#f.write(('data_box = [%8.3lf %8.3lf %8.3lf %8.3lf]; % ' + city_data + '_' +  str(miles_across*2) + 'x' + str(miles_across*2) + '\n'));
	print(box);
	print('%.3lf %.3lf %%' % (2.7, box[0][0]), city_data)
	#print(('data_box = [%8.3lf %8.3lf %8.3lf %8.3lf ]; %% %.0lfx%.0lf_%s\n') % (box[0][0], box[0][1], box[1][0], box[1][1], miles_across*2, miles_across*2, city_data[0]))
	f.write(('%%elevMatrix = TileGridLoader([%8.3lf %8.3lf %8.3lf %8.3lf ]);  %% %.0lfx%.0lf_%s\n') % (box[0][0], box[0][1], box[1][0], box[1][1], miles_across*2, miles_across*2, city_data[0]))

f.close()
