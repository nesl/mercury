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
    if na not in nextNodes:
        nextNodes[na] = []
    nextNodes[na] += [nb]
    if nb not in nextNodes:
        nextNodes[nb] = []
    nextNodes[nb] += [na]

print('Total # of nodes: ' + str(len(nodes)))
print('Total # of edges: ' + str(len(edges)))
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
        if len(criticalNodes) == 0 and flagAllowCycle:
            criticalNodes = connectedNodes[0]

        if len(criticalNodes) < 100:
            continue
        print('find component with size ' + str(len(criticalNodes)))

        for nn in criticalNodes:
            for tn in nextNodes[nn]:
                if (nn, tn) not in tracedEdges:
                    seg = [nn, tn]
                    tracedEdges.add( (nn, tn) )
                    tracedEdges.add( (tn, nn) )
                    while seg[-1] not in criticalNodes:
                        nnn = seg[-1]
                        for tnn in nextNodes[nnn]:
                            if (nnn, tnn) not in tracedEdges:
                                tracedEdges += [ (nnn, tnn), (tnn, nnn) ]
                                seg += [tnn]
                    segCoor = [ x + ',' + nodes[x][0] + ',' + nodes[x][1] for x in seg ]
                    print ",".join( tuple(segCoor) )

