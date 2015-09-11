#!/bin/bash

ALIGN="align_image_stack"
EXTRACT="sex"
DOT="python ./makeStarDots.py"
COPY_EXIF="exiftool -TagsFromFile"

DENOISER="median"
ERROR_LOG="error.log"
OUTFILE="starry-utah-sky.tif"
PREFIX="stars-"
SRC_DIR="./src_tif"
SUFFIX=".tif"

if [[ "clean" == $1 ]]; then
	rm darkframe.tif
	rm -rf catalogs
	rm -rf nodf
	rm -rf dots
	rm -rf fits
	rm -rf pto
	rm -rf rotated
	rm bigsum.tif
	echo "Clean!"
	exit 0
fi

if [ ! -d catalogs ]; then
	mkdir catalogs
fi

if [ ! -d nodf ]; then
	mkdir nodf
fi

if [ ! -d dots ]; then
	mkdir dots
fi

if [ ! -d fits ]; then
	mkdir fits
fi

if [ ! -d pto ]; then
	mkdir pto
fi

if [ ! -d rotated ]; then
	mkdir rotated
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
if [ ! -e "dots/${PREFIX}${ANCHOR}${SUFFIX}" ]; then
	if [ ! -e "catalogs/${PREFIX}${ANCHOR}.cat" ]; then
			if [ ! -e "fits/${PREFIX}${ANCHOR}.fits" ]; then
				convert "${SRC_DIR}/${PREFIX}${ANCHOR}${SUFFIX}" -colorspace gray "fits/${PREFIX}${ANCHOR}.fits" 2>&1>/dev/null
			fi

			$EXTRACT "fits/${PREFIX}${ANCHOR}.fits" -CATALOG_NAME "catalogs/${PREFIX}${ANCHOR}.cat" 2>&1>/dev/null
		fi

		$DOT "${SRC_DIR}/${PREFIX}${ANCHOR}${SUFFIX}" "catalogs/${PREFIX}${ANCHOR}.cat" "dots/${PREFIX}${ANCHOR}${SUFFIX}.png"
		convert "dots/${PREFIX}${ANCHOR}${SUFFIX}.png" -colorspace rgb -type truecolor "dots/${PREFIX}${ANCHOR}${SUFFIX}" 2>&1>/dev/null
		rm "dots/${PREFIX}${ANCHOR}${SUFFIX}.png"
		$COPY_EXIF "${SRC_DIR}/${PREFIX}${ANCHOR}${SUFFIX}" "dots/${PREFIX}${ANCHOR}${SUFFIX}"
		rm "dots/${PREFIX}${ANCHOR}${SUFFIX}_original"
fi

for i in $(seq 1 $COUNT); do
	FILE="$PREFIX$i"
	echo "   Working on file $i of $COUNT - $FILE"

	# Remove dark frame
	if [ ! -e nodf/${FILE}${SUFFIX} ]; then
		convert darkframe.tif "${SRC_DIR}/${FILE}${SUFFIX}" -evaluate-sequence subtract "nodf/${FILE}${SUFFIX}" 2>&1>$ERROR_LOG
	fi

	# Create dim frame for alignment (to mitigate noise interfering with the alignment)
	#if [ ! -e dim/${FILE}${SUFFIX} ]; then
	#	convert "nodf/${FILE}${SUFFIX}" -threshold 70% "dim/${FILE}${SUFFIX}"
	#fi

	# Create dots from the brightest stars in the middle of the images
	if [ ! -e "dots/${FILE}${SUFFIX}" ]; then
		if [ ! -e "catalogs/${FILE}.cat" ]; then
			if [ ! -e "fits/${FILE}.fits" ]; then
				convert "${SRC_DIR}/${FILE}${SUFFIX}" -colorspace gray "fits/${FILE}.fits" 2>&1>/dev/null
			fi

			$EXTRACT "fits/${FILE}.fits" -CATALOG_NAME "catalogs/${FILE}.cat" 2>&1>/dev/null
		fi

		$DOT "${SRC_DIR}/${FILE}${SUFFIX}" "catalogs/${FILE}.cat" "dots/${FILE}${SUFFIX}.png"
		convert "dots/${FILE}${SUFFIX}.png" -colorspace rgb -type truecolor "dots/${FILE}${SUFFIX}"
		rm "dots/${FILE}${SUFFIX}.png"
		$COPY_EXIF "${SRC_DIR}/${FILE}${SUFFIX}" "dots/${FILE}${SUFFIX}"
		rm "dots/${FILE}${SUFFIX}_original"
	fi
	
	# Find transformation parameters with dot images and rewrite pto for originals
	if [ ! -e pto/${FILE}.pto ]; then
		$ALIGN -a aligned_ -p pto/${FILE}.pto "dots/${PREFIX}${ANCHOR}${SUFFIX}" "dots/${FILE}${SUFFIX}" 2>&1>$ERROR_LOG
		rm aligned_0000.tif
		rm aligned_0001.tif
		#sed -i.bak 's/dots\//..\/nodf\//g' pto/${FILE}.pto
		sed -i.bak 's/dots\//..\/nodf\//g' pto/${FILE}.pto
		#rm pto/${FILE}.pto.bak
	fi

	if [ ! -e rotated/$FILE.tif ]; then
		nona -m TIFF_m -o aligned_ pto/${FILE}.pto
		rm aligned_0000.tif
		mv aligned_0001.tif "rotated/${FILE}.tif"
	fi

	exit 1

	# 32-bit processing means no more need for a group file
	if [ ! -e bigsum.tif ]; then
		convert -size 5472x3648 xc:black -depth 32 bigsum.tif
	fi
	convert bigsum.tif "rotated/${FILE}.tif" -evaluate-sequence add -depth 32 bigsum.tif 2>&1>$ERROR_LOG

	# Add to the group
	#if [ ! -e "math/${FILE}" ]; then
	#	GROUP=$((i % NUM_GROUPS))
	#	GROUP_FILE="math/group-${GROUP}.tif"
	#	if [ ! -e $GROUP_FILE ]; then
	#		cp darkframe.tif $GROUP_FILE
	#	fi
	#	convert $GROUP_FILE "rotated/${FILE}.tif" -evaluate-sequence add $GROUP_FILE 2>&1>$ERROR_LOG
	#	touch "math/${FILE}"
	#fi
done

# Build the final composite
#echo "Building final composite"
#convert math/* -evaluate-sequence $DENOISER $OUTFILE 2>&1>$ERROR_LOG
