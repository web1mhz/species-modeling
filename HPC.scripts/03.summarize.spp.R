#define some directories
data.dir = '/data/jc165798/models/'
out.dir = '/homes/31/jc165798/working/Wallace.Initiative/summaries/'
pbs.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs/'; setwd(pbs.dir); system('rm -rf *')
script2run = '/homes/31/jc165798/working/Wallace.Initiative/scripts/HPC.scripts/03.script2run.R'
Rnwfile = '/homes/31/jc165798/working/Wallace.Initiative/scripts/HPC.scripts/03.report.Rnw'

#get the species groups
spp.groups = list.files(data.dir)

#cycle through each of the species groups
for (spp.group in spp.groups){
	#create the out.sum.dir
	out.sum.dir = paste(out.dir,spp.group,'/',sep=''); dir.create(out.sum.dir,recursive=TRUE)
	pdf.dir = paste(out.dir,'pdf/',spp.group,sep=''); dir.create(pdf.dir,recursive=TRUE) #directory for pdf files
	csv.dir = paste(out.dir,'csv/',spp.group,sep=''); dir.create(csv.dir,recursive=TRUE) #directory for csv files
	#cycle through each of the species
	species = gsub('\\.tar.gz','',list.files(paste(data.dir,spp.group,sep='')))
	for (spp in species) {
		#create the spp.sum.dir
		spp.sum.dir = paste(out.sum.dir,spp,'/',sep=''); dir.create(spp.sum.dir,recursive=TRUE)
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
			cat("R CMD BATCH '--args spp=",spp," out.dir=",'"',spp.sum.dir,'"',"' ",spp,'.R ',pbs.dir,spp,'.Rout --no-save \n',sep='',file=zz)
			cat('#remove the local files\n',file=zz)
			cat('cd /tmp/\n',file=zz)
			cat('rm -rf ',spp,'*\n',sep='',file=zz)
			cat('#move to the output folder and create a pdf from the outputs\n',file=zz)
			cat('cd ',spp.sum.dir,'\n',sep='',file=zz)
			cat('cp -af ',Rnwfile,' ',spp,'.Rnw\n',sep='',file=zz)
			cat('R CMD Sweave ',spp,'.Rnw\n',sep='',file=zz)
			cat('R CMD pdflatex ',spp,'.tex\n',sep='',file=zz)
			cat('#copy the csv & pdf file to the output folders\n',file=zz)
			cat('cp -af no.migrate.data.csv ',csv.dir,'/',spp,'.csv\n',sep='',file=zz)
			cat('cp -af ',spp,'.pdf ',pdf.dir,'/',spp,'.pdf\n',sep='',file=zz)
			cat('#tar the original summary files\n',file=zz)
			cat('cd ',out.sum.dir,'\n',sep='',file=zz)
			cat('tar -zcf ',spp,'.tar.gz ',spp,' \n',sep='',file=zz)
			cat('rm -rf ',spp,' \n',sep='',file=zz)
			cat('##################################\n',file=zz)		
		close(zz)
		system(paste('qsub ',spp,'.sh',sep=''))
		system('sleep 0.1')
	}
}

