#define & set the working directory
pbs.dir = '/data/jc165798/WallaceInitiative/tmp.pbs/'; setwd(pbs.dir); system('rm -rf *')

#define the projection directory
proj.dir = '/data/jc165798/WallaceInitiative/projecting.data/'

#define the location of maxent.jar & script2run file
maxent = '/data/jc165798/WallaceInitiative/maxent.jar'
script2run = '/homes/31/jc165798/working/Wallace.Initiative/scripts/HPC/010.script2run.R'

#define the output model directory
model.dir = '/data/jc165798/WallaceInitiative/models/'
groups = list.files(model.dir); groups = groups[c(3,1,4,2)] #start with mammals ***** fix for plants

#cycle through each of the groups and sumbit species jobs
for (group in groups) {
	group.dir = paste(model.dir,group,'/',sep='')
	#list the species for which we have occurrences
	species = list.files(group.dir)
	#cycle through each of the species
	for (spp in species) {
		out.dir = paste(group.dir,spp,'/output/',sep=''); dir.create(out.dir)
		#create a sh script to submit the species summary job
		zz = file(paste(spp,'.sh',sep=''),'w')
			cat('##################################\n',file=zz)
			cat('#!/bin/sh\n',file=zz)
			cat("R CMD BATCH '--args spp=",spp," work.dir=",'"',group.dir,spp,'/" maxent="',maxent,'" proj.dir="',proj.dir,'"',"' ",script2run,' ',pbs.dir,spp,'.Rout --no-save \n',sep='',file=zz)
			cat('##################################\n',file=zz)		
		close(zz)
		system(paste('qsub -m n ',spp,'.sh',sep=''))
	}
}

