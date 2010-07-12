
#define the necessary info
pbs.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs/'; setwd(pbs.dir); system('rm -rf *')
script2run = '/homes/31/jc165798/working/Wallace.Initiative/scripts/HPC.scripts/50.script2run.R'

#define the directory with the data
csv.dir = '/homes/31/jc165798/working/Wallace.Initiative/summaries/csv/'
#get a list of groups of species
spp.groups = list.files(csv.dir)
#cycle through each of the species groups
for (spp.group in spp.groups){ 
	#create an sh file for the group
	zz = file(paste(spp.group,'.sh',sep=''),'w')
		cat('##################################\n',file=zz)
		cat('#!/bin/sh\n',file=zz)
		cat('cd $PBS_O_WORKDIR\n',file=zz)
		cat("R CMD BATCH '--args group=",'"',spp.group,'"',"' ",script2run,' ',pbs.dir,spp.group,'.Rout --no-save \n',sep='',file=zz)
		cat('##################################\n',file=zz)		
	close(zz)
	system(paste('qsub -l nodes=2:ppn=2 ',spp.group,'.sh',sep=''))
}
