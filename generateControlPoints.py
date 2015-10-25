import alipy
from glob import glob
from natsort import natsorted

testImages = natsorted( glob( './*-0.fits' ) )
cpFile = open( './controlPoints.txt', 'w' )

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
			cpFile.write( "c n0 N%d x%.2f y%.2f X%.2f Y%.2f t0\n" % (
				image - 1,
				p[0][0], 3648 - p[0][1],
				p[1][0], 3648 - p[1][1]
			) )
			
	cpFile.close()

if "__main__" == __name__:
	main()
