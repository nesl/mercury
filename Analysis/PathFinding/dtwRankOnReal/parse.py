f = open('legacy.txt')
lines = [ x for x in f.readlines() if x[:10] == '          ' ]
f.close()

nums = [ float(x[10:-1]) for x in lines ]
print(nums)

#res = [ [ 0 for x in range(29) ] for x in range(29) ]
fo = open('output.csv', 'w')
for i in range(29):
	arr = nums[ (i*29):((i+1)*29) ]
	arr[0], arr[i] = arr[i], arr[0]
	arr[1:] = sorted(arr[1:])
	print(arr)
	fo.write(  ",".join( tuple(map(str, arr)) ) + '\n' )
fo.close()
