#set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/summaries/'
richness.dir = paste(work.dir,'richness/',sep=''); dir.create(richness.dir,recursive=TRUE)
pbs.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs/'; setwd(pbs.dir); system('rm -rf *')
script2run = '/homes/31/jc165798/working/Wallace.Initiative/scripts/HPC.scripts/04.script2run.R'
Rnwfile = '/homes/31/jc165798/working/Wallace.Initiative/scripts/HPC.scripts/04.report.Rnw'

#define the species groups
spp.groups = list.files(paste(work.dir,'csv/',sep=''))

for (spp.group in spp.groups){ #cycle through each of the species groups
	#create an sh file for the group
	zz = file(paste(spp.group,'.sh',sep=''),'w')
		cat('##################################\n',file=zz)
		cat('#!/bin/sh\n',file=zz)
		cat('cd $PBS_O_WORKDIR\n',file=zz)
		cat("R CMD BATCH '--args group=",'"',spp.group,'"',"' ",script2run,' ',pbs.dir,spp.group,'.Rout --no-save \n',sep='',file=zz)
		cat('#move to the output folder and create a pdf from the outputs\n',file=zz)
		cat('cd ',richness.dir,spp.group,'/\n',sep='',file=zz)
		cat('cp -af ',Rnwfile,' ',spp.group,'.Rnw\n',sep='',file=zz)
		cat('R CMD Sweave ',spp.group,'.Rnw\n',sep='',file=zz)
		cat('R CMD pdflatex ',spp.group,'.tex\n',sep='',file=zz)
		cat('##################################\n',file=zz)		
	close(zz)
	system(paste('qsub -l nodes=2:ppn=2 ',spp.group,'.sh',sep=''))
}
