#define & set the working directory
pbs.dir = '/data/jc165798/WallaceInitiative/tmp.pbs2/'; dir.create(pbs.dir); setwd(pbs.dir); system('rm -rf *')


#define the location of maxent.jar & script2run file
script2run = '/home1/31/jc165798/SCRIPTS/WallaceInitiative/HPC/020.script2run.R'

#define the output model directory
model.dir = '/data/jc165798/WallaceInitiative/models/'
groups = list.files(model.dir); groups = groups[c(3,1,4,2)] #start with mammals ***** fix for plants

#define the clipping distance
clip.dist = 2000000

count = 0
#cycle through each of the groups and sumbit species jobs
for (group in groups) {
	group.dir = paste(model.dir,group,'/',sep='')
	#list the species for which we have occurrences
	species = list.files(group.dir)
	if (group=='aves' | group=='mammalia') { disp.real = 1500; disp.opt = 3000 }
	if (group=='amphibia' | group=='reptilia') { disp.real = 100; disp.opt = 500 }
	#cycle through each of the species
	for (spp in species) {
		#create a sh script to submit the species summary job
		zz = file(paste(spp,'.sh',sep=''),'w')
			cat('##################################\n',file=zz)
			cat('#!/bin/sh\n',file=zz)
			cat("R CMD BATCH '--args disp.real=",disp.real," disp.opt=",disp.opt," clip.dist=",clip.dist," spp=",spp," work.dir=",'"',group.dir,spp,'/"',"' ",script2run,' ',pbs.dir,spp,'.Rout --no-save \n',sep='',file=zz)
			cat('##################################\n',file=zz)		
		close(zz)
		system(paste('qsub -m n ',spp,'.sh',sep=''))
		count = count + 1; if (count%%300==0) system('sleep 500')
	}
}


# spp=13749423 
# work.dir="/data/jc165798/WallaceInitiative/models/mammalia/13749423/"
# disp.real = 1500 #m pa ... this is the realistic distance a species will disperse 
# disp.opt = 3000 #m pa ... this is the optimistic distance a species will disperse
# clip.dist = 2000000 #distance to clip species to
