#define & set the working directory
pbs.dir = '/home/uqvdwj/WallaceInitiative/tmp.pbs/'; dir.create(pbs.dir); setwd(pbs.dir); system('rm -rf *')

#define the script to run
script2run = "/home/uqvdwj/SCRIPTS/WallaceInitiative/HPC/021.script2run.R"

#define the model directory
model.dir = '/home/uqvdwj/WallaceInitiative/models/'

#list the taxonomic groups of species
groups = list.files(model.dir)

#defien the names of the files
tnames = c('no.disp.sum.csv.gz','no.disp.loss.csv.gz','real.sum.csv.gz','real.loss.csv.gz','real.gain.csv.gz','opt.sum.csv.gz','opt.loss.csv.gz','opt.gain.csv.gz')

#cycle through each of the groups and sumbit species jobs
for (group in groups) { cat(group,'\n')
	for (tname in tnames) {
		arg.tname=paste('tname="',tname,'" ',sep='')
		arg.group=paste('group="',group,'" ',sep='')
		#create a pbs to submit a job
		zz = file(paste(group,'_',tname,'.pbs',sep=''),'w')
			cat('#!/bin/bash \n',file=zz)
			cat('source /etc/profile \n',file=zz)
			cat('module load R \n',file=zz) #load the necessary module
			cat('cd ',pbs.dir,'\n',sep='',file=zz)
			cat("R CMD BATCH --no-save '--args ",arg.group,arg.tname,"' ",script2run,' ',group,'_',tname,'.Rout\n',sep='',file=zz)
		close(zz)
		#submit the job
		system(paste('qsub -A q1086 -l select=1:ncpus=2:NodeType=medium -l walltime=100:00:00 ',group,'_',tname,'.pbs',sep=''))
	}
}

