################################################################################
#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in something like
# group="amphibia"
# fam="Ambystomatidae"

################################################################################
# load libraries and add functions
library(SDMTools)

################################################################################
# start doing some work

#define / create some directories
base.dir = '/home/uqvdwj/WallaceInitiative/' #this is the basic input and output directory
tmp.dir = paste('/scratch/uqvdwj/',group,'_',fam,'/',sep=''); dir.create(tmp.dir,recursive=TRUE); setwd(tmp.dir) #setup a temporary dir on /scratch
dir.create('GIS',recursive=TRUE);dir.create('area');dir.create('richness');#other misc directories needed
train.dir = '/home/uqvdwj/WallaceInitiative/training.data/' #define the directory where generic training data is

#read in the mask and the positions
pos = read.csv(paste(train.dir,'mask.pos.csv',sep=''),as.is=TRUE)
mask = read.asc.gz(paste(train.dir,'mask.asc.gz',sep=''))

#get a list of species to be summariezed
species = list.files(paste(base.dir,'models/',group,'/',fam,sep=''),pattern='tar.gz'); species = gsub('\\.tar.gz','',species) 
#define the output dir for the species GIS files
spp.out.dir = paste(base.dir,'summaries/GIS/species/',group,'/',fam,'/',sep=''); dir.create(spp.out.dir,recursive=TRUE)

#data to be tracked
out.area = NULL #this is the output of the areas
n = 0 #track the number of species
no.sum = no.loss = real.sum = real.loss = real.gain = opt.sum = opt.loss = opt.gain = NULL #these are the basic data outputs for richness

#cycle through each of the species and extract the necessary info
for (spp in species) { cat(spp,'\n')
	#copy over the data files
	file.copy(paste(base.dir,'models/',group,'/',fam,'/',spp,'.tar.gz',sep=''),tmp.dir,overwrite=TRUE) 
	untar(paste(spp,'.tar.gz',sep='')) #untar the species data
	unlink(paste(spp,'.tar.gz',sep='')) #remove the tar file
	
	### start with area of the predictions
	tfile = paste(spp,'/summaries/prediction.area.csv.gz',sep='')
	if (file.exists(tfile)) {
		tdata = read.csv(gzfile(tfile),as.is=TRUE) #read in the data
		if (is.null(out.area)) { out.area = tdata } else { out.area = rbind(out.area,tdata) }		
	}	
	
	### summarize the species richness 
	tfile = paste(spp,'/summaries/predictions.binary.dispersal.csv.gz',sep='')
	if (file.exists(tfile)) { n = n + 1
		indata = as.matrix(read.csv(gzfile(tfile),as.is=TRUE)) #read in the data
		if (is.null(no.sum)) { #setup all storage outputs
			tnames = colnames(indata); outnames = tnames[grep('_',tnames)]
			no.sum = indata[,outnames] #just keep the columns of interest
			no.sum[,] = 0 #set everything == 0
			no.loss = real.sum = real.loss = real.gain = opt.sum = opt.loss = opt.gain = no.sum #set starting work to all 0
		} 		
		#append all the information
		#first No dispersal
		tdata=as.matrix(indata) #get a copy of indata
		for (tname in outnames) { tdata[,tname] = tdata[,tname] * tdata[,'no.disp'] } #apply NO dispersal clip
		no.sum[,] = no.sum[,] + tdata[,outnames] #append the sum of the species to the sum
		for (tname in outnames) { if (tname!="current_0.5degrees") { tdata[,tname] = tdata[,tname] - tdata[,"current_0.5degrees"] } } #subtract all data from current
		tdata2 = tdata[,outnames]; tdata2[which(tdata2>0)] = 0; no.loss[,] = no.loss[,] + tdata2[,] #tally the losses
		
		#now for realistic dispersal
		tdata=as.matrix(indata) #get a copy of indata
		tdata[,"current_0.5degrees"] = tdata[,'current_0.5degrees'] * tdata[,'no.disp'] #define the current
		for (tname in outnames[grep('_2020_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2020.real'] } #apply dispersal clip
		for (tname in outnames[grep('_2050_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2050.real'] } #apply dispersal clip
		for (tname in outnames[grep('_2080_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2080.real'] } #apply dispersal clip
		real.sum[,] = real.sum[,] + tdata[,outnames] #append the sum of the species to the sum
		for (tname in outnames) { if (tname!="current_0.5degrees") { tdata[,tname] = tdata[,tname] - tdata[,"current_0.5degrees"] } } #subtract all data from current
		tdata2 = tdata[,outnames]; tdata2[which(tdata2>0)] = 0; real.loss[,] = real.loss[,] + tdata2[,] #tally the losses
		tdata2 = tdata[,outnames]; tdata2[which(tdata2<0)] = 0; real.gain[,] = real.gain[,] + tdata2[,] #tally the gains

		#now for optimistic dispersal
		tdata=as.matrix(indata) #get a copy of indata
		tdata[,"current_0.5degrees"] = tdata[,'current_0.5degrees'] * tdata[,'no.disp'] #define the current
		for (tname in outnames[grep('_2020_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2020.opt'] } #apply dispersal clip
		for (tname in outnames[grep('_2050_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2050.opt'] } #apply dispersal clip
		for (tname in outnames[grep('_2080_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2080.opt'] } #apply dispersal clip
		opt.sum[,] = opt.sum[,] + tdata[,outnames] #append the sum of the species to the sum
		for (tname in outnames) { if (tname!="current_0.5degrees") { tdata[,tname] = tdata[,tname] - tdata[,"current_0.5degrees"] } } #subtract all data from current
		tdata2 = tdata[,outnames]; tdata2[which(tdata2>0)] = 0; opt.loss[,] = opt.loss[,] + tdata2[,] #tally the losses
		tdata2 = tdata[,outnames]; tdata2[which(tdata2<0)] = 0; opt.gain[,] = opt.gain[,] + tdata2[,] #tally the gains
	}

	### write out the associated GIS files for the website
	#this is data associated with the realistic dispersal for only ES of a1b & A30r5l and means for 2020, 2050, 2080
	tfile = paste(spp,'/summaries/predictions.raw.csv.gz',sep='')
	if (file.exists(tfile)) {
		tdata=as.matrix(read.csv(gzfile(tfile),as.is=TRUE)) #get the raw predictions
		threshold = read.csv(gzfile(paste(spp,'/summaries/thresholds.csv.gz',sep='')),as.is=TRUE); threshold = threshold$threshold[threshold$type=='min.ROC.plot.distance'] #get the threshold values
		tdata[,"current_0.5degrees"] = tdata[,'current_0.5degrees'] * indata[,'no.disp'] #define the current
		for (tname in outnames[grep('_2020_',outnames)]) { tdata[,tname] = tdata[,tname] * indata[,'pot.2020.real'] } #apply dispersal clip
		for (tname in outnames[grep('_2050_',outnames)]) { tdata[,tname] = tdata[,tname] * indata[,'pot.2050.real'] } #apply dispersal clip
		for (tname in outnames[grep('_2080_',outnames)]) { tdata[,tname] = tdata[,tname] * indata[,'pot.2080.real'] } #apply dispersal clip
		tdir = paste('GIS/species/',spp,'/',sep=''); dir.create(tdir,recursive=TRUE) #create a directory for the gis output
		tasc = mask; tasc[cbind(pos$row,pos$col)] = tdata[,'current_0.5degrees']; tasc[which(tasc<threshold)]=0; write.asc.gz(tasc,paste(tdir,'current.asc',sep='')) #write out the current gis file	
		for (ES in c('SRES_A1B','A1B_A30r5l')) {
			for (year in c(2020,2050,2080)) {
				tasc = mask; tasc[cbind(pos$row,pos$col)] = rowMeans(tdata[,outnames[intersect(grep(year,outnames),grep(ES,outnames))]]) #extract the mean for the columns of interest
				tasc[which(tasc<threshold)]=0 #remove anything below the threshold
				write.asc.gz(tasc,paste(tdir,year,'_',ES,'_mean.asc',sep='')) #write out the current gis file
			}
		}
		#now copy the species GIS files
		file.copy(paste(spp,'/occur.csv',sep=''),paste('GIS/species/',spp,'/occur.csv',sep=''),overwrite=TRUE)
		system(paste('cp -af GIS/species/',spp,' ',spp.out.dir,sep=''))
		system(paste('rm -rf GIS/species/',spp,sep=''))
	}
}

#write out some of the data
write.csv(out.area,gzfile('area/predicted.area.csv.gz'),row.names=FALSE) #write out the area information
write.csv(no.sum,gzfile('richness/no.disp.sum.csv.gz'),row.names=FALSE)
write.csv(no.loss,gzfile('richness/no.disp.loss.csv.gz'),row.names=FALSE)
write.csv(real.sum,gzfile('richness/real.sum.csv.gz'),row.names=FALSE)
write.csv(real.loss,gzfile('richness/real.loss.csv.gz'),row.names=FALSE)
write.csv(real.gain,gzfile('richness/real.gain.csv.gz'),row.names=FALSE)
write.csv(opt.sum,gzfile('richness/opt.sum.csv.gz'),row.names=FALSE)
write.csv(opt.loss,gzfile('richness/opt.loss.csv.gz'),row.names=FALSE)
write.csv(opt.gain,gzfile('richness/opt.gain.csv.gz'),row.names=FALSE)

### write out the associated GIS files for the website
#this is data associated with the realistic dispersal for only ES of a1b & A30r5l and means for 2020, 2050, 2080
tdata=real.sum #richness for the real.sum
tdir ='GIS/richness/'; dir.create(tdir,recursive=TRUE) #create a directory for the gis output
tasc = mask; tasc[cbind(pos$row,pos$col)] = tdata[,'current_0.5degrees']; write.asc.gz(tasc,paste(tdir,'current.asc',sep='')) #write out the current gis file	
for (ES in c('SRES_A1B','A1B_A30r5l')) {
	for (year in c(2020,2050,2080)) {
		tasc = mask; tasc[cbind(pos$row,pos$col)] = rowMeans(tdata[,outnames[intersect(grep(year,outnames),grep(ES,outnames))]]) #extract the mean for the columns of interest
		write.asc.gz(tasc,paste(tdir,year,'_',ES,'_mean.asc',sep='')) #write out the current gis file
	}
}	

################################################################################
# copying data back to /home

#first the area info
out.dir = paste(base.dir,'summaries/area/family/',group,'/',fam,'/',sep=''); dir.create(out.dir,recursive=TRUE)
file.copy('area/predicted.area.csv.gz',paste(out.dir,'predicted.area.csv.gz',sep=''),overwrite=TRUE)
#now for the richness info
out.dir = paste(base.dir,'summaries/richness/family/',group,'/',fam,'/',sep=''); dir.create(out.dir,recursive=TRUE)
file.copy(list.files('richness',pattern='csv.gz',full.names=TRUE),out.dir,overwrite=TRUE)
#now copy the species GIS files
out.dir = paste(base.dir,'summaries/GIS/family/',group,'/',fam,'/',sep=''); dir.create(out.dir,recursive=TRUE)
file.copy(list.files('GIS/richness',pattern='asc.gz',full.names=TRUE),out.dir,overwrite=TRUE)

################################################################################
# clean up 

setwd(base.dir) #change the working directory
system(paste('rm -rf ',tmp.dir,sep='')) #remove the data from scratch
