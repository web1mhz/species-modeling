#define the working directory
pbs.dir = '/home/uqvdwj/WallaceInitiative/tmp.pbs.check/'; setwd(pbs.dir); system('rm -rf *')

data.dir = '/home/uqvdwj/WallaceInitiative/models/' #define where the models are
taxas = list.files(data.dir) #list the taxas
for (taxa in taxas) { #cycle through each of the taxa
	cat(taxa,'\n')
	fams = list.files(paste(data.dir,taxa,sep='')) #list the families
	for (fam in fams) { #cycle through the fams
		cat('   ',fam,'\n')
		#create a pbs to submit an job array
		zz = file(paste(fam,'.pbs',sep=''),'w')
			cat('#!/bin/bash \n',file=zz)
			cat('cd ',data.dir,taxa,'/',fam,'/ \n',sep='',file=zz)
			cat('mkdir -p /scratch/uqvdwj/\n',file=zz) #make a directory on the scratch drive
			cat('for tfile in ./* \n',sep='',file=zz)
			cat('do \n',sep='',file=zz)
			cat('tar -tf $tfile > /scratch/uqvdwj/',fam,'.txt \n',sep='',file=zz)
			cat('if [[ ! $? -eq 0 ]] ; then rm -f $tfile ; echo $tfile >> ',pbs.dir,fam,'.deleted.txt ; fi \n',sep='',file=zz)
			cat('done \n',sep='',file=zz)
			cat('rm -f /scratch/uqvdwj/',fam,'.txt \n',sep='',file=zz)
		close(zz)
		#submit the pbs job array
		system(paste('qsub -A q1086 ',fam,'.pbs',sep=''))
	}
	system('sleep 60')
}


################################################################################
#define the working directory
pbs.dir = '/home/uqvdwj/WallaceInitiative/tmp.pbs/'; dir.create(pbs.dir); setwd(pbs.dir); system('rm -rf *')

out.dir = '/home/uqvdwj/WallaceInitiative/models/' #define where the models are
in.dir = '/home/uqvdwj/WallaceInitiative/CHECK/' #define where the models are

out.files = list.files(out.dir,pattern='tar.gz',recursive=TRUE) #list the files that are done
in.files = list.files(in.dir,pattern='tar.gz',recursive=TRUE) #list the complete set that should have been done

diff.in.files = setdiff(in.files,out.files) #find the files that are missing
diff.out.files = setdiff(out.files,in.files) #find the files copied into the wrong place

#remove the files in the wrong place
for (tfile in diff.out.files) { cat(tfile,'\n'); unlink(paste(out.dir,tfile,sep='')) }

#recheck the data
out.files = list.files(out.dir,pattern='tar.gz',recursive=TRUE) #list the files that are done
in.files = list.files(in.dir,pattern='tar.gz',recursive=TRUE) #list the complete set that should have been done

diff.in.files = setdiff(in.files,out.files) #find the files that are missing
diff.out.files = setdiff(out.files,in.files) #find the files copied into the wrong place

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



#break diff.in.files into groups, families, species data.frame
diff.data = data.frame(groups=rep(NA,length(diff.in.files)),families=NA,species=NA)
for (ii in 1:length(diff.in.files)) { tt = strsplit(diff.in.files[ii],'/')[[1]]; diff.data[ii,] = tt }

#now cycle through and setup the jobs arrays
groups = unique(diff.data$groups)
for (group in groups) { cat(group,'\n')
	families = unique(diff.data$families[which(diff.data$groups==group)]) #get alist of families
	#setup more of th arguments
	if (group=='aves' | group=='mammalia') { arg.disp.real = 'disp.real=1500 '; arg.disp.opt = 'disp.opt=3000 ' } #ensure trailing space
	if (group=='amphibia' | group=='reptilia' | group=='plantae') { arg.disp.real = 'disp.real=100 '; arg.disp.opt = 'disp.opt=500 ' } #ensure trailing space		
	#cycle through the families
	for (fam in families) { cat('    ',fam)
		species = unique(diff.data$species[which(diff.data$groups==group & diff.data$families==fam)]); species = gsub('\\.tar.gz','',species)#list the species for which we have occurrences
		dir.create(fam)#create the pbs directory
		#cycle through the species
		for (ii in 1:length(species)) { cat('.')
			spp = species[ii] #define the species of interest
			#create a subjob for this set of species
			zz = file(paste(fam,'/',ii,'.sh',sep=''),'w')
				cat('#!/bin/bash \n',file=zz)
				cat('source /etc/profile \n',file=zz)
				cat('module load R \n',file=zz) #load the necessary module				
				cat('mkdir -p /scratch/uqvdwj/\n',file=zz) #make a directory on the scratch drive
				cat('cd /scratch/uqvdwj/\n',file=zz) #move to the temporary
				cat('if [ ! -e /scratch/uqvdwj/',proj.dir.name,'.tar ]; then cp -af ',proj.tar.file,' /scratch/uqvdwj/; tar -xf ',proj.dir.name,'.tar ; fi \n',sep='',file=zz) #copy over the projection tar file if it is not already there
				cat('if [ ! -e /scratch/uqvdwj/maxent.jar ]; then cp -af ',maxent.file,' /scratch/uqvdwj/; fi \n',sep='',file=zz) #copy over the maxent file
				cat('if [ ! -e /scratch/uqvdwj/',script2run.name,' ]; then cp -af ',script2run,' /scratch/uqvdwj/; fi \n',sep='',file=zz) #copy over the R script2run file
				cat('if [ ! -e /scratch/uqvdwj/mask.pos.csv ]; then cp -af ',mask.pos.file,' /scratch/uqvdwj/; fi \n\n',sep='',file=zz) #copy over the basic positions file
				#define some arguments
				arg.maxent = 'maxent="/scratch/uqvdwj/maxent.jar" '#ensure trailing space
				arg.mask.pos.file = 'mask.pos.file="/scratch/uqvdwj/mask.pos.csv" '#ensure trailing space
				arg.proj.dir = paste('proj.dir="/scratch/uqvdwj/',proj.dir.name,'/" ',sep='') #ensure trailing space #define the projection directory
				cat('cp -af ',in.dir,group,'/',fam,'/',spp,'.tar.gz /scratch/uqvdwj/\n',sep='',file=zz) #copy over the species tar file
				cat('tar -xf ',spp,'.tar.gz \n',sep='',file=zz) #untar the file
				cat('rm -f ',spp,'.tar.gz \n',sep='',file=zz) #remove the tar file
				arg.spp = paste('spp=',spp,' ',sep='')
				arg.work.dir = paste('work.dir="/scratch/uqvdwj/',spp,'/" ',sep='')
				cat("R CMD BATCH '--args ",arg.spp,arg.work.dir,arg.maxent,arg.proj.dir,arg.models,arg.project,arg.summarize,arg.clip,arg.rich,
					arg.mask.pos.file,arg.clip.dist,arg.disp.real,arg.disp.opt,"' /scratch/uqvdwj/",script2run.name,' /scratch/uqvdwj/',spp,'/',
					script2run.name,'out \n\n',sep='',file=zz) #run the R script in the background
				
				cat('tar --remove-files -czf ',spp,'.tar.gz ',spp,' \n',sep='',file=zz) #tar and gzip all model outputs
				cat('mv -f ',spp,'.tar.gz ',out.dir,group,'/',fam,'/ \n\n',sep='',file=zz) #move all files back to /home
			close(zz)
		}
		#setup job submission
		zz = file(paste(fam,'/000.pbs',sep=''),'w')
			cat('#!/bin/bash \n',file=zz)
			cat('#PBS -N ',substr(fam,1,13),'\n',sep='',file=zz)
			if (length(species)==1) {
				cat('file=1.sh \n',file=zz)
			} else {
				cat('#PBS -J 1-',length(species),' \n',sep='',file=zz)
				cat('(sleep $(( ($PBS_ARRAY_INDEX % 10) * 15 ))) \n',file=zz)
				cat('file=$[PBS_ARRAY_INDEX].sh \n',file=zz)
			}
			cat('cd ',pbs.dir,fam,'\n',sep='',file=zz)
			cat('sh $file \n',sep='',file=zz)
		close(zz)		
		cat('\n')
	}
}

#find the pbs jobs and submit them
pbs.files = list.files(pbs.dir,pattern='000.pbs',recursive=TRUE,full.names=TRUE); pbs.files=gsub('//','/',pbs.files); pbs.files=gsub('000.pbs','',pbs.files) #get a list of the pbs files
for (pbs in pbs.files) { setwd(pbs); system('qsub -A q1086 -l NodeType=medium 000.pbs'); system('sleep 15') } #submit the jobs

