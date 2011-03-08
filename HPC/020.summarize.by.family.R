#define & set the working directory
pbs.dir = '/home/uqvdwj/WallaceInitiative/tmp.pbs/'; dir.create(pbs.dir); setwd(pbs.dir); system('rm -rf *')

#define the script to run
script2run = "/home/uqvdwj/SCRIPTS/WallaceInitiative/HPC/020.script2run.R"

#define the model directory
model.dir = '/home/uqvdwj/WallaceInitiative/models/'

groups = list.files(model.dir)#list the taxonomic groups of species

#cycle through each of the groups and sumbit species jobs
for (group in groups) { cat(group,'\n')
	families = list.files(paste(model.dir,group,'/',sep='')) #get alist of families
	for (fam in families) {
		arg.group=paste('group="',group,'" ',sep='')
		arg.fam=paste('fam="',fam,'" ',sep='')
		#create a pbs to submit a job
		zz = file(paste(fam,'.pbs',sep=''),'w')
			cat('#!/bin/bash \n',file=zz)
			cat('source /etc/profile \n',file=zz)
			cat('module load R \n',file=zz) #load the necessary module
			cat('cd ',pbs.dir,'\n',sep='',file=zz)
			cat("R CMD BATCH --no-save '--args ",arg.group,arg.fam,"' ",script2run,' ',fam,'.Rout\n',sep='',file=zz)
		close(zz)
		#submit the job
		system(paste('qsub -A q1086 -l select=1:ncpus=4:NodeType=medium -l walltime=1000:00:00 ',fam,'.pbs',sep=''))
		#system('sleep 5')
	}
}
