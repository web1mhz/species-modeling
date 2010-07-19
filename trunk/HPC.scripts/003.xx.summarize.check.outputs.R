#define some directories
data.dir = '/data/jc165798/models/'
out.dir = '/homes/31/jc165798/working/Wallace.Initiative/summaries/csv/';
pbs.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs/'; setwd(pbs.dir); system('rm -rf *')
script2run = '/homes/31/jc165798/working/Wallace.Initiative/scripts/HPC.scripts/003.script2run.R'

#get the species groups
spp.groups = list.files(data.dir)

#cycle through each of the species groups
for (spp.group in spp.groups){ cat(spp.group,'\n')
	#create the out.sum.dir
	out.sum.dir = paste(out.dir,spp.group,'/',sep='')
	#cycle through each of the species
	species = gsub('\\.tar.gz','',list.files(paste(data.dir,spp.group,sep='')))
	#check which species have not finished...
	completed = gsub('\\.predictions.binary.csv.gz','',list.files(out.sum.dir,pattern='\\.predictions.binary.csv.gz'))
	#define the species as only those ones not completed
	species = setdiff(species,completed)
	if (length(species)>0) {
		for (spp in species) { cat(spp,'\n')
			#create a sh script to submit the species summary job
			zz = file(paste(spp,'.sh',sep=''),'w')
				cat('##################################\n',file=zz)
				cat('#!/bin/sh\n',file=zz)
				cat('#set the working directory to the local tmp drive\n',file=zz)
				cat('cd /tmp/\n',file=zz)
				cat('#copy the species data over and untar it\n',file=zz)
				cat('cp -af ',data.dir,spp.group,'/',spp,'.tar.gz ',spp,'.tar.gz\n',sep='',file=zz)
				cat('tar -xf ',spp,'.tar.gz\n',sep='',file=zz)			
				cat('#run the R summarizing script\n',file=zz)
				cat('cp -af ',script2run,' ',spp,'.R\n',sep='',file=zz)
				cat("R CMD BATCH '--args spp=",spp," out.dir=",'"',out.sum.dir,'"',"' ",spp,'.R ',pbs.dir,spp,'.Rout --no-save \n',sep='',file=zz)
				cat('#remove the local files\n',file=zz)
				cat('cd /tmp/\n',file=zz)
				cat('rm -rf ',spp,'*\n',sep='',file=zz)
				cat('##################################\n',file=zz)		
			close(zz)
			system(paste('qsub -m n ',spp,'.sh',sep=''))
		}
	}
}

#######################works for plants
#define some directories
data.dir = '/homes/31/jc165798/working/Wallace.Initiative/models/plantae/'
out.dir = '/homes/31/jc165798/working/Wallace.Initiative/summaries/csv/plantae/'
pbs.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs/'; setwd(pbs.dir); system('rm -rf *')
script2run = '/homes/31/jc165798/working/Wallace.Initiative/scripts/HPC.scripts/003.script2run.R'

#get the species groups
spp.groups = list.files(data.dir)

#setup the script for running
qq = file('/homes/31/jc165798/wallace.sh','w')
	cat('##################################\n',file=qq)
	cat('#!/bin/sh\n',file=qq)	
	cat('cd ',pbs.dir,'\n',sep='',file=qq)
	
#cycle through each of the species groups
for (spp.group in spp.groups){ cat(spp.group,'\n')
	#create the out.sum.dir
	out.sum.dir = paste(out.dir,spp.group,'/',sep=''); dir.create(out.sum.dir,recursive=TRUE)
	#get a list of species
	species = gsub('\\.tar.gz','',list.files(paste(data.dir,spp.group,sep='')))
	completed = gsub('\\.predictions.binary.csv.gz','',list.files(out.sum.dir,pattern='\\.predictions.binary.csv.gz'))
	species = setdiff(species,completed)
	if (length(species)>0) {
		#get the data off tape
		if(length(species)<5) {
			for (spp in species) { cat("ssh dmf.jcu.edu.au 'dmget ",data.dir,spp.group,"/",spp,".tar.gz'\n",sep='',file=qq) }
		} else {
			cat("ssh dmf.jcu.edu.au 'dmfind ",data.dir,spp.group," -state OFL | dmget'\n",sep='',file=qq)
		}
		for (spp in species) {
			#create a sh script to submit the species summary job
			zz = file(paste(spp,'.sh',sep=''),'w')
				cat('##################################\n',file=zz)
				cat('#!/bin/sh\n',file=zz)
				cat('#set the working directory to the local tmp drive\n',file=zz)
				cat('cd /tmp/\n',file=zz)
				cat('#copy the species data over and untar it\n',file=zz)
				cat('cp -af ',data.dir,spp.group,'/',spp,'.tar.gz ',spp,'.tar.gz\n',sep='',file=zz)
				cat('tar -xf ',spp,'.tar.gz\n',sep='',file=zz)			
				cat('#run the R summarizing script\n',file=zz)
				cat('cp -af ',script2run,' ',spp,'.R\n',sep='',file=zz)
				cat("R CMD BATCH '--args spp=",spp," out.dir=",'"',out.sum.dir,'"',"' ",spp,'.R ',pbs.dir,spp,'.Rout --no-save \n',sep='',file=zz)
				cat('#remove the local files\n',file=zz)
				cat('cd /tmp/\n',file=zz)
				cat('rm -rf ',spp,'*\n',sep='',file=zz)
				cat("ssh dmf.jcu.edu.au 'dmput -r ",data.dir,spp.group,'/',spp,".tar.gz' \n",sep='',file=zz)
				cat('##################################\n',file=zz)		
			close(zz)
			cat('qsub -m n ',spp,'.sh\n',sep='',file=qq)
		}
	}
}
close(qq)

