#!/bin/bash
source /etc/profile.d/modules.sh

#define the base directory
BASEDIR=/data/jc165798/WallaceSummaries/summaries/GIS

# first setup the species richness
TMPDIR=${BASEDIR}/family
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
