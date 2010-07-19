#define some directories
data.dir = '/homes/31/jc165798/working/Wallace.Initiative/summaries/csv/'
pbs.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs2/'; dir.create(pbs.dir); setwd(pbs.dir); system('rm -rf *')
script2run = '/homes/31/jc165798/working/Wallace.Initiative/scripts/HPC.scripts/004.script2run.R'

#get the species groups
spp.groups = list.files(data.dir)

#cycle through each of the species groups
for (spp.group in spp.groups){
	#create the out.sum.dir
	out.dir = paste(data.dir,spp.group,'/',sep='')
	#cycle through each of the species
	species = gsub('\\.predictions.binary.csv.gz','',list.files(paste(data.dir,spp.group,sep=''),pattern='\\.predictions.binary.csv.gz'))
	tcount = 0
	for (spp in species) {
		#create a sh script to submit the species summary job
		zz = file(paste(spp,'.sh',sep=''),'w')
			cat('##################################\n',file=zz)
			cat('#!/bin/sh\n',file=zz)
			cat('cd $PBS_O_WORKDIR\n',file=zz)
			cat('#run the R summarizing script\n',file=zz)
			cat("R CMD BATCH '--args disp.real=100 disp.opt=500 spp=",spp," out.dir=",'"',out.dir,'"',"' ",script2run,' ',pbs.dir,spp,'.Rout --no-save \n',sep='',file=zz)
			cat('##################################\n',file=zz)		
		close(zz)
		system(paste('qsub -m n ',spp,'.sh',sep=''))
		tcount = tcount +1
		if (tcount%%30==0) system('sleep 200')
	}
}


disp.real = 1500 #m pa ... this is the realistic distance a species will disperse 
disp.opt = 3000 #m pa ... this is the optimistic distance a species will disperse

pbs.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs2/'; setwd(pbs.dir);
sh.files = list.files(,pattern='\\.sh'); sh.files=sh.files[-grep('\\.sh.',sh.files)]; sh.files=gsub('\\.sh','',sh.files)
rout.files = list.files(,pattern='\\.Rout'); rout.files=gsub('\\.Rout','',rout.files)
for (ii in setdiff(sh.files,rout.files)) { system(paste('qsub -m n ',ii,'.sh',sep='')) }

