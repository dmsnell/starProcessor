import alipy

testImages = [
	'./orion-1-0.fits',
	'./orion-2-0.fits',
	'./orion-3-0.fits',
	'./orion-4-0.fits'
]

def main():
	identifications = alipy.ident.run(
		testImages[ 0 ],
		testImages,
		visu=False,
		n=15
	)
	
	image = 0
	for id in identifications:
		image += 1
		if 1 == image:
			continue

		s = [ (p.x, p.y) for p in id.refmatchstars ]
		t = [ (p.x, p.y) for p in id.uknmatchstars ]

		z = zip( s, t )
		for p in z:
			print "c n0 N%d x%.2f y%.2f X%.2f Y%.2f t0" % (
				image - 1,
				p[0][0], 3648 - p[0][1],
				p[1][0], 3648 - p[1][1]
			)

if "__main__" == __name__:
	main()
