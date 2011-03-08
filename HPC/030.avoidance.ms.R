#drafted by Jeremy VanDerWal ( jjvanderwal@gmail.com ... www.jjvanderwal.com )
#GNU General Public License .. feel free to use / distribute ... no warranties

################################################################################
################################################################################
#define the necessary info
pbs.dir = '/home/uqvdwj/WallaceInitiative/tmp.pbs/'; setwd(pbs.dir); system(paste('rm -rf ',pbs.dir,sep=''))
script2run = '/home/uqvdwj/SCRIPTS/WallaceInitiative/HPC/030.script2run.R'

model.dir = '/home/uqvdwj/WallaceInitiative/summaries/area/family/'
groups = list.files(model.dir) #get a list of the groups

#cycle through each of the species groups
for (group in groups){ 
	#create an sh file for the group
	zz = file(paste(group,'.sh',sep=''),'w')
		cat('##################################\n',file=zz)
		cat('#!/bin/sh\n',file=zz)
		cat('source /etc/profile\n',file=zz)
		cat('module load R\n',file=zz)
		cat('cd $PBS_O_WORKDIR\n',file=zz)
		cat("R CMD BATCH '--args group=",'"',group,'"',"' ",script2run,' ',pbs.dir,group,'.Rout\n',sep='',file=zz)
		cat('##################################\n',file=zz)		
	close(zz)
	system(paste('qsub -l select=1:ncpus=4:NodeType=medium -A q1086 -l walltime=100:00:00 ',group,'.sh',sep=''))
}
