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
proj.list = list.files(proj.dir)

#define the output model directory
model.dir = '/homes/31/jc165798/working/Wallace.Initiative/models/'

#list the species for which we have occurrences
occur.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/individual.spp.occur/'
species = list.files(occur.dir,pattern='\\.csv'); species = gsub('\\.csv','',species)

#bkgd directory & shell script.dir
bkgd.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/individual.spp.bkgd/'
sh.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/individual.spp.00.script/'

#cycle through each of the models
for (spp in species) {
	##prepare the background file
	occur = read.csv(paste(occur.dir,spp,'.csv',sep=''),as.is=T) #read in the occur records
	tbkgd = extract.data(cbind(occur$lon,occur$lat),bkgd); tbkgd = na.omit(unique(tbkgd)) #get the unique domains
	out.bkgd = NULL; for (ii in tbkgd) out.bkgd = rbind(out.bkgd,get(paste('bkgd.',ii,sep=''))) #grab the background data for the domains
	write.csv(out.bkgd,paste(bkgd.dir,spp,'.csv',sep=''),row.names=F) #write out the data

	#create a shell script for running the models
	zz = file(paste(sh.dir,spp,'.sh',sep=''),'w')
		cat('#create the local directory and move to it \n',file=zz)
		cat('md /tmp/',spp,'\n',sep='',file=zz)
		cat('cd /tmp/',spp,'\n',sep='',file=zz)
		cat('\n',file=zz)
		cat('#copy over the necessary files \n',file=zz)
		cat('cp -af ',occur.dir,spp,'.csv occur.csv \n',sep='',file=zz)
		cat('cp -af ',bkgd.dir,spp,'.csv bkgd.csv \n',sep='',file=zz)
		cat('cp -af ',work.dir,'maxent.jar maxent.jar \n',sep='',file=zz)
		cat('\n',file=zz)
		cat('#create the output directory \n',file=zz)
		cat('md output \n',sep='',file=zz)
		cat('\n',file=zz)
		cat('# create the maxent model \n',file=zz)
		if (nrow(occur) >= 40) { #run the maxent model once with full data and another cross validated
			cat('java -mx2000m -jar maxent.jar outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv nowarnings replicates=10 noaskoverwrite novisible nooutputgrids autorun \n',sep='',file=zz)
			cat('cp -af output/maxentResults.csv output/maxentResults.crossvalide.csv \n',file=zz)
			cat('java -mx2000m -jar maxent.jar outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv nowarnings noaskoverwrite responsecurves novisible writebackgroundpredictions nooutputgrids autorun \n',sep='',file=zz)
		} else {
			cat('java -mx2000m -jar maxent.jar outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv -N bio_5 -N bio_6 -N bio_16 -N bio_17 nowarnings replicates=10 noaskoverwrite novisible nooutputgrids autorun \n',sep='',file=zz)
			cat('cp -af output/maxentResults.csv output/maxentResults.crossvalide.csv \n',file=zz)
			cat('java -mx2000m -jar maxent.jar outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv -N bio_5 -N bio_6 -N bio_16 -N bio_17 nowarnings noaskoverwrite responsecurves novisible writebackgroundpredictions nooutputgrids autorun \n',sep='',file=zz)
		}
		cat('\n',file=zz)
		cat('# project the model \n',file=zz)
		for (projx in proj.list) {
			cat('test -e output/',spp,'.lambdas && java -cp maxent.jar density.Project output/',spp,'.lambdas /tmp/proj/',projx,' output/',projx,'.asc fadebyclamping nowriteclampgrid \n',sep="",file=zz)
        }
		cat('\n',file=zz)
		cat('# compress the projections \n',file=zz)
		cat('gzip output/*.asc \n',file=zz)
		cat('\n',file=zz)
		cat('# move to the outer direct, tar the folder and copy it the model directory \n',file=zz)
		cat('cd /tmp/ \n',file=zz)
		cat('tar -zcf ',spp,'.tar.gz ',spp,' \n',sep='',file=zz)
		cat('cp -af ',spp,'.tar.gz ',model.dir,spp,'.tar.gz \n',sep='',file=zz)
		cat('rm -rf ',spp,' \n',sep='',file=zz)
		cat('rm -rf ',spp,'.tar.gz \n',sep='',file=zz)
		cat('\n',file=zz)		
		
	close(zz)
	
}


 #bash -x 00.model.species.sh

