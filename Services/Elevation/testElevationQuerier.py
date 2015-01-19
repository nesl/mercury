import ElevationService as ES
from ElevationService import *

querier = ElevationQuerier()

start = (34.076991, -118.453712)
pt2 = (34.073809, -118.449163)
pt3 = (34.073969, -118.445129)
pt4 = (34.076902, -118.444184)
stop = (34.078324, -118.439421)
latLngs = [ start, pt2, pt3, pt4, stop ]

b = querier.query(latLngs)
print(b)
