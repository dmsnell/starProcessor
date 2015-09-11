import cv2
from PIL import Image, ImageDraw
import math
import re
import sys

class Point:
	def __init__(self, x, y):
		self.x = x
		self.y = y

def distance( p1, p2 ):
	return math.sqrt(pow(p1.x-p2.x,2) + pow(p1.y-p2.y,2));

def drawCirlce( p, r, height, draw ):
	draw.ellipse( ( p.x - r, ( height - p.y ) - r, p.x + r, ( height - p.y ) + r ), outline='yellow' )

def drawLine( p1, p2, height, draw ):
	draw.line( ( p1.x, height - p1.y, p2.x, height - p2.y ), width=2, fill='yellow' )

def main():
	sourceImageName = sys.argv[1]
	sourceCatalog = sys.argv[2]
	targetImage = sys.argv[3]

	sourceImage = cv2.imread( sourceImageName )
	height, width = sourceImage.shape[:2]
	center = Point( width / 2, height / 2 )
	pilImage = Image.new('RGB',(width,height))
	draw = ImageDraw.Draw(pilImage)

	stars = []
	with open( sourceCatalog, 'r' ) as catalog:
		for line in catalog:
			if line.strip()[0] == "#":
				continue
			stars.append( map( lambda x: float(x), re.split( "\s+", line.strip() ) ) )

	# Draw stars
	k = 5
	filteredStars = filter( lambda x: (x[2] < -15.0) and distance( center, Point( x[0], x[1] ) ) < 1600, stars)
	sortedStars = sorted( filteredStars, key=lambda x: x[2] )[0:30]
	for star in sortedStars:
		p = Point( star[0], star[1] )

		filteredNeighbors = filter( lambda x: distance( p, Point( x[0], x[1] ) ) < 300, sortedStars)
		sortedNeighbors = sorted( filteredNeighbors, key=lambda x: distance( p, Point( x[0], x[1] ) ) )[1:k]

		for n in sortedNeighbors:
			drawLine( p, Point( n[0], n[1] ), height, draw )

		for r in range(1,1):
			drawCirlce( p, r, height, draw )

	del draw
	pilImage.save( targetImage, 'PNG' )

if "__main__" == __name__:
	main()