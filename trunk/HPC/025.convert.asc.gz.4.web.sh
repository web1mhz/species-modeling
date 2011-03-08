#!/bin/bash
source /etc/profile.d/modules.sh

#define the base directory
BASEDIR=/ctbccr/scratch/summaries/GIS

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

################################################################################
#run this from a separate script
################################################################################

#!/bin/bash
source /etc/profile.d/modules.sh

#define the base directory
BASEDIR=/data/jc165798/WallaceSummaries/summaries/GIS

#now do the individual species
SPPDIR=${BASEDIR}/species

#go to the temporary pbs directory and remove the contents
cd /data/jc165798/tmppbs/
if [ $? -eq 0 ] ; then rm -f * ; fi

#cycle through each of the species and put a job in the tmppbs file
for tdir in `find $SPPDIR -type d -maxdepth 3 -mindepth 3`
do
	# echo $tdir
	# define the output dir
	OUTDIR=${tdir//GIS/maps}
	
	#if output dir exists... skip this species
	if [ \! -d $OUTDIR ] ; then
	
		# get the filename
		tfile=`basename $tdir`
		
		# write out the shell script to be run
		echo '#!/bin/bash' > ${tfile}.sh
		echo 'source /etc/profile.d/modules.sh' >> ${tfile}.sh
		echo 'sh /home1/31/jc165798/SCRIPTS/WallaceInitiative/HPC/025.script2run.sh' $tdir 0 >> ${tfile}.sh
		
		# submit the jobs
		numjobs=$(( $(qstat -u jc165798 | wc -l) - 5 )) ; #get the number of current jobs
		while [ $numjobs -gt 149 ] ; do sleep 60 ; numjobs=$(( $(qstat -u jc165798 | wc -l) - 5 )) ; done #pause and wait for available job runs
		qsub -m n ${tfile}.sh
		
	fi
done

for tdir in `find ${SPPDIR}/reptilia -type d -maxdepth 2 -mindepth 2`
do
	# echo $tdir
	# get the filename
	tfile=`basename $tdir`
	
	# write out the shell script to be run
	echo '#!/bin/bash' > ${tfile}.sh
	echo 'source /etc/profile.d/modules.sh' >> ${tfile}.sh
	echo 'sh /home1/31/jc165798/SCRIPTS/WallaceInitiative/HPC/025.script2run.sh' $tdir 0 >> ${tfile}.sh
	
	# submit the jobs
	qsub -m n -l nodes=1:ppn=2:V20Z ${tfile}.sh
	sleep 0.5	
done
