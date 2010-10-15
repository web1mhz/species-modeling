#!/bin/bash
source /etc/profile.d/modules.sh

#define the base directory
BASEDIR=/data/jc165798/WallaceSummaries/summaries/GIS

# first setup the species richness
TMPDIR=${BASEDIR}/family
cd $TMPDIR

for tdir in `find $TMPDIR -type d -maxdepth 2 -mindepth 2`
do
	echo $tdir
	tfile=`basename $tdir`
	cd /data/jc165798/tmppbs/
	echo '#!/bin/bash' > ${tfile}.sh
	echo 'source /etc/profile.d/modules.sh' >> ${tfile}.sh
	echo 'sh /home1/31/jc165798/SCRIPTS/WallaceInitiative/HPC/025.script2run.sh' $tdir 1 >> ${tfile}.sh
	qsub -m n -l nodes=1:ppn=1:V20Z ${tfile}.sh
	sleep 1
done

#now do the individual species
SPPDIR=${BASEDIR}/species

for tdir in `find $SPPDIR -type d -maxdepth 2 -mindepth 2`
do
	echo $tdir
	tfile=`basename $tdir`
	cd /data/jc165798/tmppbs/
	echo '#!/bin/bash' > ${tfile}.sh
	echo 'source /etc/profile.d/modules.sh' >> ${tfile}.sh
	echo 'sh /home1/31/jc165798/SCRIPTS/WallaceInitiative/HPC/025.script2run.sh' $tdir 0 >> ${tfile}.sh
	qsub -l nodes=1:ppn=2 ${tfile}.sh
	sleep 1
done


# setup the taxa richness
TMPDIR=${BASEDIR}/taxa
cd $TMPDIR

for tdir in `ls -d *`
do
	cd /data/jc165798/tmppbs/
	echo $tdir
	echo '#!/bin/bash' > ${tdir}.sh
	echo 'source /etc/profile.d/modules.sh' >> ${tdir}.sh
	echo 'sh /home1/31/jc165798/SCRIPTS/WallaceInitiative/HPC/025.script2run.sh' ${TMPDIR}/$tdir 1 >> ${tdir}.sh
	
	qsub ${tdir}.sh
done
