from ElevationService import *
from math import *
import math

class TileRequester:
	
	def __init__(self, resolution=4):
		self.elev_service = ElevationRequester(resolution)
		self.tileResolution = self.elev_service.tileResolution * 0.99999987;
	
	def _getBoundedBox(self, center_lat, center_lon, miles):
		df = miles/69.0
		dl = df/math.cos(math.radians(center_lat))
		return [center_lat + df, center_lon - dl, center_lat - df, center_lon + dl]                
	
	# Provide bounds to get tiles on as list: [NWlat, NWlong, SElat, SElong]
	def _getMinimalTileSet(self, bounds):
		#round_indx = int(log10(self.tileResolution))
		#print(round_indx)
		#tiledBounds = [round(x,-round_indx) for x in bounds]
		#print(tiledBounds)
		#longVertCnt = abs(int((tiledBounds[1] - tiledBounds[3])/self.tileResolution))
		#latVertCnt = abs(int((tiledBounds[0] - tiledBounds[2])/self.tileResolution))
		longVertCnt = abs(int((bounds[1] - bounds[3])/self.tileResolution))
		latVertCnt = abs(int((bounds[0] - bounds[2])/self.tileResolution))
		#print(longVertCnt)
		#print(latVertCnt)
		#lower_lat = min(tiledBounds[0],tiledBounds[2])
		#lower_lon = min(tiledBounds[1],tiledBounds[3])
		lower_lat = min(bounds[0],bounds[2])
		lower_lon = min(bounds[1],bounds[3])
		tileCorners = []
		for x in range(0, latVertCnt):
			#col = round(lower_lat + x*self.tileResolution,-round_indx)
			col = lower_lat + x * self.tileResolution
			for y in range(0, longVertCnt):
				#row = round(lower_lon + y*self.tileResolution,-round_indx)
				row = lower_lon + y * self.tileResolution
				tileCorners.append((col,row));

		#print(tileCorners)
		return tileCorners
	
	def requestTiles(self, bounds):
		if(len(bounds) == 3):
			bounds = self._getBoundedBox(bounds[0], bounds[1], bounds[2])
		elif(len(bounds) != 4):
			raise Exception('Bad arguments')
		tileSet = self._getMinimalTileSet(bounds)
		rem = self.elev_service.query(tileSet)
		print(rem)
