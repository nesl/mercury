import sys

f = open('to_matlab.txt')
lines = f.readlines()
f.close()

for line in lines:
    eles = line.split(' ')
    #print(eles)
    print(line[:-1])
    print(line[77:-1] + '_6x6 -----------------------')
    #print('Map: ' + '-----------------------------------')
    print('           ' + eles[4])
    print(eles[5] + '           ' + eles[9])
    print('           ' + eles[8])
    sys.stdin.readline()
