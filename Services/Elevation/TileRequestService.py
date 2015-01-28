from ElevationService import *
import math

class TileRequester:
	
	def __init__(self, resolution=4):
		self.elev_service = ElevationRequester(resolution)
		self.tileResolution = self.elev_service.tileResolution*self.elev_service.numVertexPerEdge;
	
	def _getBoundedBox(self, center_lat, center_lon, miles):
		df = miles/69.0
		dl = df/math.cos(math.radians(center_lat))
		return [center_lat + df, center_lon - dl, center_lat - df, center_lon + dl]                
	
	# Provide bounds to get tiles on as list: [NWlong, NWlat, SElong, SElat]
	def _getMinimalTileSet(self, bounds):
		tiledBounds = [self.tileResolution*int(x/self.tileResolution) for x in bounds]
		longVertCnt = abs(int((tiledBounds[0] - tiledBounds[2])/self.tileResolution))
		latVertCnt = abs(int((tiledBounds[1] - tiledBounds[3])/self.tileResolution))

		tileCorners = []
		for x in range(0, longVertCnt):
			longCol = tiledBounds[0] + x*self.tileResolution
			for y in range(0, latVertCnt):
				latRow = tiledBounds[1] + y*self.tileResolution
				tileCorners.append((longCol,latRow));

		return tileCorners
	
	def requestTiles(self, bounds):
		if(len(bounds) == 3):
			bounds = self._getBoundedBox(bounds[0], bounds[1], bounds[2])
		elif(len(bounds) != 4):
			raise Exception('Bad arguments')
		tileSet = self._getMinimalTileSet(bounds)
		self.elev_service.query(tileSet)
