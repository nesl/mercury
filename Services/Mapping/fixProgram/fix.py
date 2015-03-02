import os
import sys
import re
from collections import deque

flagAllowCycle = False
for op in sys.argv:
    if op == '-a':
        flagAllowCycle = True

lines = sys.stdin.readlines()

nodes = {}
edges = []

lastNode = None
for i in range(1, len(lines)):
    match = re.match(r'  <way id="(\d+)">', lines[i])
    if match:
        lastNode = None
        continue

    match = re.match(r'    <nd id="(\d+)" lat="([0-9\.\-]+)" lon="([0-9\.\-]+)"\/>', lines[i])
    if match:
        nodes[ match.group(1) ] = (match.group(2),  match.group(3))
        if lastNode != None:
            edges += [ (lastNode, match.group(1)) ]
        lastNode = match.group(1)
        continue

nextNodes = {}   # node-> list of neighbor nodex
for e in edges:
    (na, nb) = e
    if na == nb:  # i don't know why this can happen in osm
        continue

    if na not in nextNodes:
        nextNodes[na] = []
    if nb not in nextNodes[na]:  # it's strange neighbor nodes can appear several times
        nextNodes[na] += [nb]

    if nb not in nextNodes:
        nextNodes[nb] = []
    if na not in nextNodes[nb]:  # it's strange neighbor nodes can appear several times
        nextNodes[nb] += [na]

sys.stderr.write('Total # of nodes: ' + str(len(nodes)) + '\n')
sys.stderr.write('Total # of edges: ' + str(len(edges)) + '\n')
#asking = ['122905200', '1903812544', '1903812541', '1903812539', '1903812527', '1903812524', '122905197']
#for ask in asking:
#    print ask, nextNodes[ask]
#exit()

trajCnt = 0

tracedNodes = set()
tracedEdges = set()
for n in nextNodes:
    if n not in tracedNodes:
        connectedNodes = set()
        queue = deque([n])
        while len(queue) > 0:
            nn = queue.popleft()
            connectedNodes.add(nn)
            for nnn in nextNodes[nn]:
                if nnn not in connectedNodes and nnn not in queue:
                    queue += [nnn]
        tracedNodes |= connectedNodes

        criticalNodes = [ x for x in connectedNodes if len(nextNodes[x]) != 2 ]
        jointNodes = [ x for x in connectedNodes if len(nextNodes[x]) > 2 ]
        if len(criticalNodes) == 0 and flagAllowCycle:
            criticalNodes = connectedNodes[0]

        if len(jointNodes) < 100:
            continue
        sys.stderr.write('find component with size ' + str(len(criticalNodes)) + '\n')

        idx = 0
        for nn in criticalNodes:
            idx += 1
            #sys.stderr.write(str(idx) + '\n')
            for tn in nextNodes[nn]:
                if (nn, tn) not in tracedEdges:
                    seg = [nn, tn]
                    #sys.stderr.write(str(nn) + ' ->' + str(tn))
                    tracedEdges.add( (nn, tn) )
                    tracedEdges.add( (tn, nn) )
                    while seg[-1] not in criticalNodes:
                        nnn = seg[-1]
                        find = 0
                        #sys.stderr.write(' ')
                        for tnn in nextNodes[nnn]:
                            if (nnn, tnn) not in tracedEdges:
                                tracedEdges.add( (nnn, tnn) )
                                tracedEdges.add( (tnn, nnn) )
                                seg += [tnn]
                                #sys.stderr.write('->' + str(tnn))
                                find += 1
                        if find != 1:
                            sys.stderr.write('error\n')
                            print >>sys.stderr, nnn
                            print >>sys.stderr, nextNodes[nnn]
                            print >>sys.stderr, (nnn in criticalNodes)
                            quit()
                    segCoor = [ x + ',' + nodes[x][0] + ',' + nodes[x][1] for x in seg ]
                    #sys.stderr.write('\n')
                    print ",".join( tuple(segCoor) )

