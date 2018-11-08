
sample = False

roads = {}
for line in open('../../../Data/osmFiles/Chicago_6x6.osm'):
    if line.startswith('  <way id=\"'):
        sample = True
    elif line.startswith('  </way>'):
        sample = False
    else:
        if sample and line.startswith('    <tag k=\"name\" v='):
            terms = line.split('\"')
            #print(terms[-2])
            roads[terms[-2]] = 1

print(len(roads))
