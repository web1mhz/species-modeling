#define & set the working directory
pbs.dir = '/home/uqvdwj/WallaceInitiative/tmp.pbs2/'; dir.create(pbs.dir); setwd(pbs.dir); system('rm -rf *')

#define the script to run
script2run.name = '010.script2run.R'
script2run = paste("/home/uqvdwj/SCRIPTS/WallaceInitiative/HPC/",script2run.name,sep='')
maxent.file = "/home/uqvdwj/WallaceInitiative/maxent.jar"
mask.pos.file = '/home/uqvdwj/WallaceInitiative/training.data/mask.pos.csv'

#define the basic argument for the single species run
arg.models = 'models=TRUE ' #ensure trailing space
arg.project = 'project=TRUE ' #ensure trailing space
arg.summarize = 'summarize=TRUE ' #ensure trailing space
arg.clip = 'clip=TRUE ' #ensure trailing space
arg.rich = 'rich=TRUE ' #ensure trailing space
arg.clip.dist = 'clip.dist=2000000 ' #ensure trailing space #distance to clip species to

#define some directories
proj.dir.name = 'projecting.data'
proj.tar.file = '/home/uqvdwj/WallaceInitiative/projecting.data.tar'
model.dir = '/home/uqvdwj/WallaceInitiative/models/'

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
		species = list.files(base.dir,pattern='\\.tar.gz'); species = gsub('\\.tar.gz','',species)#list the species for which we have occurrences
		#cycle through the species and prepare job submissions for 8 species to be run at once
		jj=1; subjob.count = 0 #define jj as 1 & identify the subjob count
		while (jj <= length(species)) { cat('.')
			subjob.count = subjob.count + 1 #increment the subjob count
			subjob.species = species[jj:(jj+7)]; subjob.species = na.omit(subjob.species) #define the species for this subjob
			#create a subjob for this set of species
			zz = file(paste(fam,subjob.count,'.sh',sep=''),'w')
				cat('#!/bin/bash \n',file=zz)
				cat('source /etc/profile \n',file=zz)
				cat('module load R \n',file=zz) #load the necessary module				
				cat('mkdir -p /scratch/uqvdwj/\n',file=zz) #make a directory on the scratch drive
				cat('cd /scratch/uqvdwj/\n',file=zz) #move to the temporary
				cat('cp -af ',proj.tar.file,' /scratch/uqvdwj/\n',sep='',file=zz) #copy over the projection tar file
				cat('tar -xf ',proj.dir.name,'.tar \n',sep='',file=zz) #untar the file
				cat('rm -f ',proj.dir.name,'.tar \n',sep='',file=zz) #remove the tar file
				cat('cp -af ',maxent.file,' /scratch/uqvdwj/\n',sep='',file=zz) #copy over the maxent file
				cat('cp -af ',script2run,' /scratch/uqvdwj/\n',sep='',file=zz) #copy over the R script2run file
				cat('cp -af ',mask.pos.file,' /scratch/uqvdwj/\n\n',sep='',file=zz) #copy over the basic positions file
				#define some arguments
				arg.maxent = 'maxent="/scratch/uqvdwj/maxent.jar" '#ensure trailing space
				arg.mask.pos.file = 'mask.pos.file="/scratch/uqvdwj/mask.pos.csv" '#ensure trailing space
				arg.proj.dir = paste('proj.dir="/scratch/uqvdwj/',proj.dir.name,'/" ',sep='') #ensure trailing space #define the projection directory
				#cycle through each of the subjob species
				for (spp in subjob.species) {
					cat('cp -af ',base.dir,spp,'.tar.gz /scratch/uqvdwj/\n',sep='',file=zz) #copy over the species tar file
					cat('tar -xf ',spp,'.tar.gz \n',sep='',file=zz) #untar the file
					cat('rm -f ',spp,'.tar.gz \n',sep='',file=zz) #remove the tar file
					arg.spp = paste('spp=',spp,' ',sep='')
					arg.work.dir = paste('work.dir="/scratch/uqvdwj/',spp,'/" ',sep='')
					cat("R CMD BATCH '--args ",arg.spp,arg.work.dir,arg.maxent,arg.proj.dir,arg.models,arg.project,arg.summarize,arg.clip,arg.rich,
						arg.mask.pos.file,arg.clip.dist,arg.disp.real,arg.disp.opt,"' /scratch/uqvdwj/",script2run.name,' /scratch/uqvdwj/',spp,'/',
						script2run.name,'out & \n\n',sep='',file=zz) #run the R script in the background
				}
				cat('wait \n\n',file=zz) #wait until all background jobs complete
				for (spp in subjob.species) { cat('tar --remove-files -czf ',spp,'.tar.gz ',spp,' \n',sep='',file=zz) } #tar and gzip all model outputs
				cat('\n',file=zz)
				cat('mv -f *tar.gz ',base.dir,' \n\n',sep='',file=zz) #move all files back to /home
				cat('cd /scratch\n',file=zz)#move to the upper level directory
				cat('rm -rf /scratch/uqvdwj\n',file=zz) #clean up the scratch space				
			close(zz)
			jj=jj+8 #increment jj
		}
		#setup job submission
		if (subjob.count==1) {
			#submit the pbs job
			#system(paste('qsub -l select=1:ncpus=8:NodeType=medium -A q1086 ',fam,'1.sh',sep=''))
		} else {
			#write out a job array pbs script to submit the family jobs
			zz = file(paste(fam,'.pbs',sep=''),'w')
				cat('#!/bin/bash \n',file=zz)
				cat('cd ',pbs.dir,'\n',sep='',file=zz)
				cat('(sleep $(( ($PBS_ARRAY_INDEX % 10) * 15 ))) \n',file=zz)
				cat('file=',fam,'$[PBS_ARRAY_INDEX].sh \n',sep='',file=zz)
				cat('sh $file \n',sep='',file=zz)
			close(zz)
			#submit the pbs job array
			#system(paste('qsub -l select=1:ncpus=8:NodeType=medium -A q1086 -J 1-',subjob.count,' ',fam,'.pbs',sep=''))
			#system('sleep 60')
		}
		cat('\n')
		
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
