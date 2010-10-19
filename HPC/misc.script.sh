#!/bin/bash
source /etc/profile 

cd ~/tmp

# define the model directory
MODELS=/home/uqvdwj/WallaceInitiative/models/
#cycle through each of the taxa
for TAXA in `ls -d ${MODELS}*` ; do
	echo $TAXA
	for SPP in `find $TAXA -type f -name '*\.tar\.gz'` ; do
		# echo $SPP
		TOUT=`basename $SPP`
		tar --strip-components 1 -xf $SPP --wildcards '*/bkgd.csv'
		for DOMAIN in `cut -d ',' -f1 bkgd.csv | sort | uniq` ; do
			TOUT=${TOUT},$DOMAIN
		done
		echo $TOUT >> `basename $TAXA`.dat
	done
done
