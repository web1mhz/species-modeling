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

################################################################################
# extract all the maxent results files
#
################################################################################
#!/bin/bash
source /etc/profile 

cd ~/tmp.pbs

# define the model directory
MODELS=/home/uqvdwj/WallaceInitiative/models/
#cycle through each of the taxa
for TAXA in `find $MODELS -type d -maxdepth 1 -mindepth 1` ; do
	echo $TAXA
	for FAM in `find $TAXA -type d -maxdepth 1 -mindepth 1` ; do
		echo $FAM
		TPBS=`basename $FAM`.sh
		echo '#!/bin/bash' > $TPBS
		echo 'source /etc/profile' >> $TPBS
		echo 'cd '$FAM >> $TPBS
		for SPP in `find $FAM -type f -name '*\.tar\.gz'` ; do
			TOUT=`basename $SPP`
			echo "tar --strip-components 2 -xf "${TOUT}" --wildcards '*/maxentResults.csv'" >> $TPBS
			echo 'mv maxentResults.csv '${TOUT//\.tar\.gz/}'.maxentResults.csv' >> $TPBS
			echo 'rm -f '$TOUT >> $TPBS
		done
	done
done

for TPBS in `find . -type f -name '*\.sh'`; do
qsub -A q1086 -l select=1:ncpus=1:NodeType=medium -l walltime=100:00:00 `basename ${TPBS}`
done



