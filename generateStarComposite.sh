#!/opt/local/bin/bash

ALIGN="python astro_align.py"

DENOISER="median"
ERROR_LOG="error.log"
OUTFILE="starry-utah-sky.tif"
PREFIX="stars-"
SRC_DIR="./src_tif"
SUFFIX=".tif"

if [[ "clean" == $1 ]]; then
	rm {red,green,blue}.tif
	rm -rf nodf
	rm -rf fits
	echo "Clean!"
	exit 0
fi

if [[ "cleanall" == $1 ]]; then
	rm darkframe.tif
fi

if [ ! -d nodf ]; then
	mkdir nodf
fi

if [ ! -d fits ]; then
	mkdir fits
fi

COUNT=$(ls -c1 $SRC_DIR | wc -l)
ANCHOR=$((COUNT / 2))
echo "Found $COUNT files, anchoring in the middle on ${PREFIX}${ANCHOR}${SUFFIX}"

# Build darkframe
if [ ! -e darkframe.tif ]; then
	convert $SRC_DIR/* -monitor -limit memory 10GiB -limit area 20GiB -limit map 20GiB -limit thread 4 -evaluate-sequence $DENOISER darkframe.tif 2>&1>$ERROR_LOG
fi

# Generate anchor
if [ ! -e nodf/${PREFIX}${ANCHOR}${SUFFIX} ]; then
	convert darkframe.tif "$SRC_DIR/${PREFIX}${ANCHOR}${SUFFIX}" -evaluate-sequence subtract "nodf/${PREFIX}${ANCHOR}${SUFFIX}" 2>&1>/dev/null 
fi
if [ ! -e "anchor_1.fits" ]; then
	convert "${SRC_DIR}/${PREFIX}${ANCHOR}${SUFFIX}" -channel rgb -separate "anchor_%d.fits" 2>&1>/dev/null
fi

# Create blank channels
for COLOR in {red,green,blue}; do
	convert -size 5472x3648 xc:black -depth 32 "${COLOR}.tif" 2>&1>/dev/null
done

for i in $(seq 1 $COUNT); do
	FILE="$PREFIX$i"
	echo "   Working on file $i of $COUNT - $FILE"

	# Remove dark frame
	#if [ ! -e nodf/${FILE}${SUFFIX} ]; then
	#	convert darkframe.tif "${SRC_DIR}/${FILE}${SUFFIX}" -evaluate-sequence subtract "nodf/${FILE}${SUFFIX}" 2>&1>$ERROR_LOG
	#fi

	# Convert into FITS
	if [ ! -e "fits/${FILE}_1.fits" ]; then
		convert "${SRC_DIR}/${FILE}${SUFFIX}" -channel rgb -separate "fits/${FILE}_%d.fits" 2>&1>/dev/null
	fi

	if [ $((i % 10)) -eq 0 ]; then
		# Rotate
		cp anchor*.fits fits/
		$ALIGN fits/*.fits

		# Add to channels
		for FITS in "alipy_out/${PREFIX}${i}_1.fits"; do
			BASE_FITS=$(basename ${FITS%_1.fits})
			convert red.tif "alipy_out/${BASE_FITS}_0_affineremap.fits" -evaluate-sequence add -depth 32 red.tif 2>&1>/dev/null
			convert green.tif "alipy_out/${BASE_FITS}_1_affineremap.fits" -evaluate-sequence add -depth 32 green.tif 2>&1>/dev/null
			convert blue.tif "alipy_out/${BASE_FITS}_2_affineremap.fits" -evaluate-sequence add -depth 32 blue.tif 2>&1>/dev/null
		done

		rm fits/*
		rm alipy_out/*
	fi
done