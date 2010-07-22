#define & set the working directory
pbs.dir = '/data/jc165798/WallaceInitiative/tmp.pbs/'; setwd(pbs.dir); system('rm -rf *')

#define the script to run
script2run = "/home1/31/jc165798/SCRIPTS/WallaceInitiative/HPC/010.script2run.R"

#define the basic argument for the single species run
arg.maxent = 'maxent="/data/jc165798/WallaceInitiative/maxent.jar" '#ensure trailing space
arg.models = 'models=FALSE ' #ensure trailing space
arg.project = 'project=FALSE ' #ensure trailing space
arg.summarize = 'summarize=FALSE ' #ensure trailing space
arg.clip = 'clip=FALSE ' #ensure trailing space
arg.rich = 'rich=TRUE ' #ensure trailing space
arg.clip.dist = 'clip.dist=2000000 ' #ensure trailing space #distance to clip species to
arg.proj.dir = 'proj.dir="/data/jc165798/WallaceInitiative/projecting.data/" ' #ensure trailing space #define the projection directory

#define the output model directory
model.dir = '/data/jc165798/WallaceInitiative/models/'
groups = list.files(model.dir); groups = groups[c(3,1,4,2)] #start with mammals ***** fix for plants

count = 0
#cycle through each of the groups and sumbit species jobs
for (group in groups) {
	group.dir = paste(model.dir,group,'/',sep='')

	#setup more of th arguments
	if (group=='aves' | group=='mammalia') { arg.disp.real = 'disp.real=1500 '; arg.disp.opt = 'disp.opt=3000 ' } #ensure trailing space
	if (group=='amphibia' | group=='reptilia') { arg.disp.real = 'disp.real=100 '; arg.disp.opt = 'disp.opt=500 ' } #ensure trailing space
	
	#list the species for which we have occurrences
	species = list.files(group.dir)
	
	#cycle through each of the species
	for (spp in species) {
		arg.spp = paste('spp=',spp,' ',sep='')
		arg.work.dir = paste('work.dir="',group.dir,spp,'/" ',sep='')
		
		#create a sh script to submit the species summary job
		zz = file(paste(spp,'.sh',sep=''),'w')
			cat('##################################\n',file=zz)
			cat('#!/bin/sh\n',file=zz)
			cat("R CMD BATCH '--args ",arg.spp,arg.work.dir,arg.maxent,arg.proj.dir,arg.models,arg.project,arg.summarize,arg.clip,arg.rich,
				arg.clip.dist,arg.disp.real,arg.disp.opt,"' ",script2run,' ',pbs.dir,spp,'.Rout --no-save \n',sep='',file=zz)
			cat('##################################\n',file=zz)		
		close(zz)
		system(paste('qsub -m n ',spp,'.sh',sep=''))
		#count = count + 1; if (count%%200==0) system('sleep 600')
	}
}



# spp=13749423 
# work.dir="/data/jc165798/WallaceInitiative/models/mammalia/13749423/"
# maxent="/data/jc165798/WallaceInitiative/maxent.jar"
# proj.dir="/data/jc165798/WallaceInitiative/projecting.data/"
# models=TRUE
# project=TRUE
# summarize=TRUE
# clip=TRUE
# rich=TRUE
# disp.real = 1500 #m pa ... this is the realistic distance a species will disperse 
# disp.opt = 3000 #m pa ... this is the optimistic distance a species will disperse
# clip.dist = 2000000 #distance to clip species to
