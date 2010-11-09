#!/bin/bash
source /etc/profile.d/modules.sh
module load ImageMagick

#define the base directory & if this is a richness dataset from commandline args
BASEDIR=$1
cd $BASEDIR
IS_RICHNESS_DATASET=$2;           #Affects colour output - 0 value for green, 1 value for rainbow

COREDIR=/data/jc165798/WallaceSummaries/summaries/maps

for tfile in `find $BASEDIR -name '*asc.gz'`
do
	echo $tfile
	#define, make and move to the output directory
	OUTDIR=${tfile//\.asc\.gz/}
	OUTDIR=${OUTDIR//GIS/maps}
	OUTDIR=${OUTDIR//${COREDIR}/'/ctbccr/datasets'}
	mkdir -p $OUTDIR
	chmod 775 $OUTDIR
	cd $OUTDIR
	
	#copy over the datafile & extract the file
	cp -af $tfile $OUTDIR
	gzip --d $(basename $tfile)
	
	#run David's script
	#These details should be changed per dataset, if necessary.
	TARGET_DIRECTORY=$OUTDIR;      #Controls where tiles are outputted
	DATASET_FILE=$(basename $tfile); DATASET_FILE=${DATASET_FILE//\.gz/} #Actual dataset location to be processed
	NODATA_VALUE="-9999";            #Set the nodata value for alpha channel production
	
	#setup the maximum
	if [ $IS_RICHNESS_DATASET -eq 1 ]; then
		R CMD BATCH --no-save /home1/31/jc165798/SCRIPTS/WallaceInitiative/HPC/025a.get.max.R
		max=$(sed -n 1p max.dat)
		rm -f 025a.get.max.Rout
	else
		max=1
	fi

	#Set range of values present in dataset for scaling to colours.
	SCALE_HIGHEST_VALUE=$max
	SCALE_LOWEST_VALUE=0.0
	
	#What zoom levels of tiles we are rendering for our map. These typically won't need changing
	ZOOM_LEVEL_LOWER=2
	ZOOM_LEVEL_UPPER=4

	#Run the tiling process.
	gdalwarp -srcnodata "$NODATA_VALUE" -dstalpha $DATASET_FILE gdal_alphafile.tif
	gdal_translate -ot Byte -of GTiff -co "TILED=YES" -b 1 -b 1 -b 1 -b 2 -scale $SCALE_LOWEST_VALUE $SCALE_HIGHEST_VALUE 0 255 gdal_alphafile.tif gdal_alphabytefile.tif
	gdalwarp -t_srs EPSG:4326 gdal_alphabytefile.tif gdal_alphabyteprojectedfile.tif
	gdal2tiles.py --webviewer=none --zoom=$ZOOM_LEVEL_LOWER-$ZOOM_LEVEL_UPPER gdal_alphabyteprojectedfile.tif $TARGET_DIRECTORY/
	rm gdal_alphafile.tif gdal_alphabytefile.tif gdal_alphabyteprojectedfile.tif

	###
	#recompress the asc file
	gzip *.asc
	#change file permissions
	chmod -R 775 .
done

