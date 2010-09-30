#!/bin/bash

source /etc/profile.d/modules.sh

module load ImageMagick

#define the base directory
BASEDIR=/data/jc165798/tmp2/amphibia
cd $BASEDIR

for tfile in `find $BASEDIR -name '*asc.gz'`
do
	echo $tfile
	#define, make and move to the output directory
	OUTDIR=${tfile//\.asc\.gz/}
	OUTDIR=${OUTDIR//tmp2/maps}
	mkdir -p $OUTDIR
	cd $OUTDIR
	
	#copy over the datafile & extract the file
	cp -af $tfile $OUTDIR
	gzip --d $(basename $tfile)
	
	#run David's script
	#These details should be changed per dataset, if necessary.
	TARGET_DIRECTORY=$OUTDIR;      #Controls where tiles are outputted
	DATASET_FILE=$(basename $tfile); DATASET_FILE=${DATASET_FILE//\.gz/} #Actual dataset location to be processed
	IS_RICHNESS_DATASET=1;           #Affects colour output - 0 value for green, 1 value for rainbow
	NODATA_VALUE="-9999";            #Set the nodata value for alpha channel production
	
	#setup the maximum
	if [ $IS_RICHNESS_DATASET -eq 1 ]; then
		R CMD BATCH --no-save /home1/31/jc165798/SCRIPTS/WallaceInitiative/HPC/025a.get.max.R
		max=$(sed -n 1p max.dat)
		rm max.dat
		rm 025a.get.max.Rout	
	else
		max=1
	fi

	#Set range of values present in dataset for scaling to colours.
	SCALE_HIGHEST_VALUE=$max
	SCALE_LOWEST_VALUE=0.0
	#Middle value is calculated for our visual scale
	SCALE_MIDDLE_VALUE=`printf "%1.1f" "\`echo "scale=1;($SCALE_HIGHEST_VALUE-$SCALE_LOWEST_VALUE)/2.0" | bc\`"`

	#Set locations/filenames for our gradients.  Only one will be used per dataset (see above). 
	GRADIENT_SPECTRUM="/data/jc165798/gradient_spectrum.png"
	GRADIENT_GREEN="/data/jc165798/gradient_green.png"

	#What zoom levels of tiles we are rendering for our map. These typically won't need changing
	ZOOM_LEVEL_LOWER=2
	ZOOM_LEVEL_UPPER=4

	#Run the tiling process.
	gdalwarp -srcnodata "$NODATA_VALUE" -dstalpha $DATASET_FILE gdal_alphafile.tif
	gdal_translate -ot Byte -of GTiff -co "TILED=YES" -b 1 -b 1 -b 1 -b 2 -scale $SCALE_LOWEST_VALUE $SCALE_HIGHEST_VALUE 0 255 gdal_alphafile.tif gdal_alphabytefile.tif
	gdalwarp -t_srs EPSG:4326 gdal_alphabytefile.tif gdal_alphabyteprojectedfile.tif
	gdal2tiles.py --webviewer=none --zoom=$ZOOM_LEVEL_LOWER-$ZOOM_LEVEL_UPPER gdal_alphabyteprojectedfile.tif $TARGET_DIRECTORY/
	rm gdal_alphafile.tif gdal_alphabytefile.tif gdal_alphabyteprojectedfile.tif

	#Colourise all png images according to the gradient provided -- green for species, spectrum for richness
	TARGET_GRADIENT=`[ $IS_RICHNESS_DATASET -eq 1 ] && echo "$GRADIENT_SPECTRUM" || echo "$GRADIENT_GREEN"`
	for file in `find $TARGET_DIRECTORY/ -name "*.png" -print`
	do
	 convert "$file" "$TARGET_GRADIENT" -clut "$file"
	 mogrify -channel a -threshold 50% "$file"
	done

	#Create our visual scale for our colourisation.  Rotate, resize and add text to our scale image.
	TOP_TEXT_COLOUR=black; MIDDLE_TEXT_COLOUR=black; BOTTOM_TEXT_COLOUR=white;
	SCALE_WIDTH=40; SCALE_HEIGHT=128; CORNER_RADIUS=12;
	convert $TARGET_GRADIENT -rotate -90 -resize "$SCALE_WIDTH"x"$SCALE_HEIGHT"\! scale_sized.png
	convert scale_sized.png \
	  \( -strokewidth 0.5 -stroke "$TOP_TEXT_COLOUR" -fill "$TOP_TEXT_COLOUR" -pointsize 10 -gravity North -annotate 0 "$SCALE_HIGHEST_VALUE" \) \
	  \( -strokewidth 0.5 -stroke "$MIDDLE_TEXT_COLOUR" -fill "$MIDDLE_TEXT_COLOUR" -pointsize 10 -gravity center -annotate 0 "$SCALE_MIDDLE_VALUE" \) \
	  \( -strokewidth 0.5 -stroke "$BOTTOM_TEXT_COLOUR" -fill "$BOTTOM_TEXT_COLOUR" -pointsize 10 -gravity South -annotate 0 "$SCALE_LOWEST_VALUE" \) scale_text.png
	convert -size "$SCALE_WIDTH"x"$SCALE_HEIGHT" xc:none -draw "roundrectangle 0,0,$(( $SCALE_WIDTH - 1 )),$(( $SCALE_HEIGHT - 1 )),$CORNER_RADIUS,$CORNER_RADIUS" scale_mask.png
	convert scale_text.png -matte scale_mask.png -compose Dstin -composite $TARGET_DIRECTORY/scale.png
	rm scale_sized.png scale_text.png scale_mask.png
	
	###
	#recompress the asc file
	gzip *.asc
	#change file permissions
	chmod -R o-rx .
done

