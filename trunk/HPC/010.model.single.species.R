#define & set the working directory
pbs.dir = '/home/jc165798/working/WallaceInitiative/tmp.pbs/'; dir.create(pbs.dir); setwd(pbs.dir); system('rm -rf *')

#define the script to run
script2run.name = '010.script2run.R'
script2run = paste("/home/jc165798/SCRIPTS/WallaceInitiative/HPC/",script2run.name,sep='')

#define the basic argument for the single species run
arg.models = 'models=TRUE ' #ensure trailing space
arg.project = 'project=TRUE ' #ensure trailing space
arg.summarize = 'summarize=TRUE ' #ensure trailing space
arg.clip = 'clip=TRUE ' #ensure trailing space
arg.rich = 'rich=TRUE ' #ensure trailing space
arg.clip.dist = 'clip.dist=2000000 ' #ensure trailing space #distance to clip species to

arg.mask.pos.file = 'mask.pos.file="/home/jc165798/working/WallaceInitiative/training.data/mask.pos.csv" '#ensure trailing space
arg.maxent = 'maxent="/home/jc165798/working/WallaceInitiative/maxent.jar" '#ensure trailing space
arg.proj.dir = 'proj.dir="/home/jc165798/working/WallaceInitiative/projecting.data/" ' #ensure trailing space #define the projection directory
				
#define some directories
proj.dir.name = 'projecting.data'
####proj.tar.file = '/home/jc165798/working/WallaceInitiative/projecting.data.tar'
model.dir = '/home/jc165798/working/WallaceInitiative/models/'

groups = list.files(model.dir)#list the taxonomic groups of species

#cycle through each of the groups and sumbit species jobs
for (group in groups) { cat(group,'\n')
	families = list.files(paste(model.dir,group,'/',sep='')) #get alist of families
	#setup more of th arguments
	if (group=='aves' | group=='mammalia') { arg.disp.real = 'disp.real=1500 '; arg.disp.opt = 'disp.opt=3000 ' } #ensure trailing space
	if (group=='amphibia' | group=='reptilia' | group=='plantae') { arg.disp.real = 'disp.real=100 '; arg.disp.opt = 'disp.opt=500 ' } #ensure trailing space		
	#cycle through the families
	for (fam in families) { cat('    ',fam)
		base.dir = paste(model.dir,group,'/',fam,'/',sep='') #get the base working directory
		species = list.files(base.dir) #list the species for which we have occurrences
		dir.create(fam)#create the pbs directory
		#cycle through the species
		for (ii in 1:length(species)) { cat('.')
			spp = species[ii] #define the species of interest
			zz = file(paste(fam,'/',spp,'.sh',sep=''),'w')#create a job for this set of species
				cat('#!/bin/bash \n',file=zz)
				cat('source /etc/profile \n',file=zz)
				cat('module load java \n',file=zz) #load the necessary module				
				#define some arguments
				arg.spp = paste('spp=',spp,' ',sep='')
				arg.work.dir = paste('work.dir="/home/jc165798/working/WallaceInitiative/models/',group,'/',fam,'/',spp,'/" ',sep='')
				cat("R CMD BATCH --no-save --no-restore '--args ",arg.spp,arg.work.dir,arg.maxent,arg.proj.dir,arg.models,arg.project,arg.summarize,arg.clip,arg.rich,
					arg.mask.pos.file,arg.clip.dist,arg.disp.real,arg.disp.opt,"' ",script2run,' ',pbs.dir,fam,'/',spp,
					'.Rout \n\n',sep='',file=zz) #run the R script in the background
			close(zz)
		}
		cat('\n')
		# setwd(paste(pbs.dir,fam,sep='')) #move the working directory to the family stuffs
		# tfiles = list.files(,pattern='\\.sh') #get a list of the job files
		# for (tfile in tfiles) { #cycle thorugh each of the job files and submit them
			# system(paste('qsub -m n -l nodes=1:ppn=1 -l pmem=3gb ',gsub('.R','.sh',tfile),sep=''))
		# }
		# setwd(pbs.dir) #return the working directory to the tmp pbs one
		# system('sleep 10') #let the system relax for a couple seconds
	}
}

################################################################################
#copy the following to a sh file to sumbit only 500 jobs at a time...


#!/bin/bash

BASEDIR=/home/jc165798/working/WallaceInitiative/tmp.pbs/
cd $BASEDIR
pwd

for SPP in `find . -type f -name '*.sh'`
do
	echo $SPP
	numjobs=$(( $(qstat -u jc165798 | grep ' Q ' | wc -l) + $(qstat -u jc165798 | grep ' R ' | wc -l) )) 
	while [ $numjobs -gt 499 ] 
	do 
		sleep 60
		numjobs=$(( $(qstat -u jc165798 | grep ' Q ' | wc -l) + $(qstat -u jc165798 | grep ' R ' | wc -l) ))
	done
	qsub -m n -l nodes=1:ppn=1 -l pmem=3gb $SPP 
done
