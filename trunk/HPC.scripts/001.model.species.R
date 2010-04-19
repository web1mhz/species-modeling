#setup & load libraries needed for run
.libPaths(c(.libPaths(),'/homes/31/jc165798/R_libraries'))
library(SDMTools)

################################################################################

#define & set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/'; setwd(work.dir)

#read in the background file asc & individual domains
bkgd = read.asc.gz('training.data/background.selection.mask.asc.gz')
for (ii in 1:6) assign(paste('bkgd.',ii,sep=''),read.csv(paste('training.data/bkgd.domain.',ii,'.csv',sep='')))

#define the projection directory
proj.dir = '/homes/31/jc165798/working/Wallace.Initiative/projecting.data/'
proj.list = list.files(proj.dir,full.names=T)

##define the model directory
#model.dir = '/homes/31/jc165798/working/Wallace.Initiative/models/'; model.list = NULL
#for (tdir in list.files(model.dir)) model.list = c(model.list,list.files(paste(model.dir,tdir,sep=''),full.names=T))
#model.list = paste(model.list,'/occur.csv',sep='')
load('/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs/model.list.Rdata')

#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in lines.of.interest

#cycle through each of the models
for (model in model.list[lines.of.interest]) {
	#get the model path
	model.path = paste(dirname(model),'/',sep='')
	#define the spp name
	spp = strsplit(model.path,'/'); spp = spp[[1]][length(spp[[1]])]
	cat(spp,'\n')
	#read in the occurrences
	occur = read.csv(model)
	#check which domain for background
	tbkgd = extract.data(cbind(occur$lon,occur$lat),bkgd); tbkgd = na.omit(unique(tbkgd)) #get the unique domains
	out.bkgd = NULL; for (ii in tbkgd) out.bkgd = rbind(out.bkgd,get(paste('bkgd.',ii,sep=''))) #grab the background data for the domains
	write.csv(out.bkgd,paste(model.path,'bkgd.csv',sep=''),row.names=F) #write out the data
	#copy over the maxent.jar file
	file.copy('maxent.jar',paste(model.path,'maxent.jar',sep=''))
	#create the model output directory
	dir.create(paste(model.path,'output',sep=''))
	
	#create a shell script for running the models
	zz = file(paste(model.path,'00.model.species.sh',sep=''),'w')
		cat('cd ',model.path,'\n',sep='',file=zz)
		cat('\n',file=zz)
		cat('# create the maxent model \n',file=zz)
		if (nrow(occur) >= 40) { #run the maxent model once with full data and another cross validated
			cat('java -mx2000m -jar maxent.jar outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv nowarnings replicates=10 noaskoverwrite responsecurves novisible writebackgroundpredictions nooutputgrids autorun \n',sep='',file=zz)
			cat('cp -af output/maxentResults.csv output/maxentResults.crossvalide.csv \n',file=zz)
			cat('java -mx2000m -jar maxent.jar outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv nowarnings noaskoverwrite responsecurves novisible writebackgroundpredictions nooutputgrids autorun \n',sep='',file=zz)
		} else {
			cat('java -mx2000m -jar maxent.jar outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv -N bio_5 -N bio_6 -N bio_16 -N bio_17 nowarnings replicates=10 noaskoverwrite responsecurves novisible writebackgroundpredictions nooutputgrids autorun \n',sep='',file=zz)
			cat('cp -af output/maxentResults.csv output/maxentResults.crossvalide.csv \n',file=zz)
			cat('java -mx2000m -jar maxent.jar outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv -N bio_5 -N bio_6 -N bio_16 -N bio_17 nowarnings noaskoverwrite responsecurves novisible writebackgroundpredictions nooutputgrids autorun \n',sep='',file=zz)
		}
		cat('\n',file=zz)
		cat('# project the model \n',file=zz)
		for (projx in proj.list) {
			cat('test -e output/',spp,'.lambdas && java -cp maxent.jar density.Project output/',spp,'.lambdas ',projx,' output/',strsplit(projx,'//')[[1]][2],'.asc fadebyclamping nowriteclampgrid \n',sep="",file=zz)
        }
		cat('\n',file=zz)
		cat('# compress the projections \n',file=zz)
		cat('gzip output/*.asc \n',file=zz)
		cat('\n',file=zz)
	close(zz)
}


 #bash -x 00.model.species.sh

