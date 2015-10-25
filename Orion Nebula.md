Export images from Lightroom

Convert to FITS
```bash
for FILE in orion-*.tif; do convert "$FILE" -separate "${FILE%.tif}.fits"; done
```

Open list of `.tif` files into Hugin and save an empty project `orion.pto`

Run sextractor/AliPy and copy control points into `orion.pto`
Remove `r:CROP` from `n` line of `orion.pto`

Create aligned images
```bash
nona -o aligned_ orion.pto
```

Stack
```bash
convert aligned_* -depth 32 -evaluate-sequence add -depth 32 orion.tif
```

Open in Photoshop and manipulate
