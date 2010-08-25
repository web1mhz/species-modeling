#define & set the working directory
pbs.dir = '/home/uqvdwj/WallaceInitiative/tmp.pbs/'; dir.create(tmp.pbs); setwd(pbs.dir); system('rm -rf *')

#define the script to run
script2run = "/home/uqvdwj/SCRIPTS/WallaceInitiative/HPC/010.script2run.R"

#define the basic argument for the single species run
arg.maxent = 'maxent="/home/uqvdwj/WallaceInitiative/maxent.jar" '#ensure trailing space
arg.models = 'models=TRUE ' #ensure trailing space
arg.project = 'project=TRUE ' #ensure trailing space
arg.summarize = 'summarize=TRUE ' #ensure trailing space
arg.clip = 'clip=TRUE ' #ensure trailing space
arg.rich = 'rich=TRUE ' #ensure trailing space
arg.clip.dist = 'clip.dist=2000000 ' #ensure trailing space #distance to clip species to
arg.train.dir = 'train.dir="/home/uqvdwj/WallaceInitiative/training.data/" '

#define some directories
proj.dir = '/home/uqvdwj/WallaceInitiative/projecting.data/'
proj.dir.name = 'projecting.data'
model.dir = '/home/uqvdwj/WallaceInitiative/models/'

groups = list.files(model.dir)#list the taxonomic groups of species

#cycle through each of the groups and sumbit species jobs
for (group in groups) { cat(group,'\n')
	families = list.files(paste(model.dir,group,'/',sep='')) #get alist of families
	#setup more of th arguments
	if (group=='aves' | group=='mammalia') { arg.disp.real = 'disp.real=1500 '; arg.disp.opt = 'disp.opt=3000 ' } #ensure trailing space
	if (group=='amphibia' | group=='reptilia' | group=='plantae') { arg.disp.real = 'disp.real=100 '; arg.disp.opt = 'disp.opt=500 ' } #ensure trailing space		
	#cycle through the families
	for (fam in families) { cat('    ',fam,'\n')
		base.dir = paste(model.dir,group,'/',fam,'/',sep='') #get the base working directory
		species = list.files(base.dir)#list the species for which we have occurrences
		#cycle through each of the species
		for (spp in species) {
			arg.spp = paste('spp=',spp,' ',sep='')
			#create a sh script to submit the species summary job
			zz = file(paste(spp,'.sh',sep=''),'w')
				cat('#!/bin/bash \n',file=zz)
				cat("echo $PBS_NODEFILE \n",file=zz)
				cat('mkdir -p /scratch/uqvdwj/',spp,'\n',sep='',file=zz) #make a directory on the scratch drive
				cat("echo 'direcoty created' \n",file=zz)
				cat('cd /scratch/uqvdwj/',spp,'\n',sep='',file=zz) #move to the temporary
				cat('cp -af ',proj.dir,' /scratch/uqvdwj/',spp,'\n',sep='',file=zz) #copy over the projection files
				cat('cp -af ',base.dir,spp,'/* /scratch/uqvdwj/',spp,'\n',sep='',file=zz) #copy over the occurences & background files
				arg.proj.dir = paste('proj.dir="/scratch/uqvdwj/',spp,'/',proj.dir.name,'/" ',sep='') #ensure trailing space #define the projection directory
				arg.work.dir = paste('work.dir="/scratch/uqvdwj/',spp,'/" ',sep='')
				cat("echo 'data copied' \n",file=zz)
				cat('module load R \n',file=zz) #load the necessary module				
				cat("R CMD BATCH '--args ",arg.spp,arg.work.dir,arg.maxent,arg.proj.dir,arg.models,arg.project,arg.summarize,arg.clip,arg.rich,
					arg.train.dir,arg.clip.dist,arg.disp.real,arg.disp.opt,"' ",script2run,' ',pbs.dir,spp,'.Rout --no-save \n',sep='',file=zz) #run the R script
				cat("echo 'R run & cleaning up' \n",file=zz)
				cat('rm -rf /scratch/uqvdwj/',spp,'/',proj.dir.name,'\n',sep='',file=zz) #remove the projection directory
				cat('cp -af /scratch/uqvdwj/',spp,'/ ',base.dir,'\n',sep='',file=zz) #copy over the outputs to the home drive
				cat('cd /scratch\n',file=zz)#move to the upper level directory
				cat('rm -rf /scratch/uqvdwj/',spp,'\n',sep='',file=zz) #clean up the scratch space
				cat("echo 'DONE' \n",file=zz)
			close(zz)
			system(paste('qsub -A q1086 -k oe ',spp,'.sh',sep=''))
		}
		system('sleep 30')
	}
}



# spp=13749423 
# work.dir="/data/jc165798/WallaceInitiative/models/mammalia/13749423/"
# maxent="/data/jc165798/WallaceInitiative/maxent.jar"
# proj.dir="/data/jc165798/WallaceInitiative/projecting.data/"
# train.dir="/home/uqvdwj/WallaceInitiative/training.data/"
# models=TRUE
# project=TRUE
# summarize=TRUE
# clip=TRUE
# rich=TRUE
# disp.real = 1500 #m pa ... this is the realistic distance a species will disperse 
# disp.opt = 3000 #m pa ... this is the optimistic distance a species will disperse
# clip.dist = 2000000 #distance to clip species to
