
#define the necessary info
pbs.dir = '/data/jc165798/WallaceInitiative/tmp.pbs3/'; dir.create(pbs.dir); setwd(pbs.dir); system('rm -rf *')
script2run = '/home1/31/jc165798/SCRIPTS/WallaceInitiative/HPC/040.script2run.R'

model.dir = '/data/jc165798/WallaceInitiative/models/'
groups = list.files(model.dir); groups = groups[c(3,1,4,2)] #start with mammals ***** fix for plants

#cycle through each of the species groups
for (group in groups){ 
	#create an sh file for the group
	zz = file(paste(group,'.sh',sep=''),'w')
		cat('##################################\n',file=zz)
		cat('#!/bin/sh\n',file=zz)
		cat('cd $PBS_O_WORKDIR\n',file=zz)
		cat("R CMD BATCH '--args group=",'"',group,'"',"' ",script2run,' ',pbs.dir,group,'.Rout --no-save \n',sep='',file=zz)
		cat('##################################\n',file=zz)		
	close(zz)
	system(paste('qsub -l nodes=1:ppn=8 ',group,'.sh',sep=''))
}
