# load the fix file 'ucla.tfix' and try to pick segments of interests.
# the definition of segment here is segment bound by two cross points with
# no cross point in the middle.
# a cross points simply means an intersection or any point on the map
# with degrees not equal to 2.

fp = open('t1')
points = [ x.strip() for x in fp.readlines() ]
fp.close()

f = open('../../../Data/trajectorySetsFix/ucla.tfix')
lines = f.readlines()
f.close()

fo = open('../../../Data/trajectorySetsFix/ucla_west.tfix', 'w')
for line in lines:
    ele = line.strip().split(',')
    if ele[0] in points and ele[-3] in points:
        fo.write(line)
fo.close()
