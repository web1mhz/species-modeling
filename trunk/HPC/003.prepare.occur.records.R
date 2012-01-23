# grab interactive node to prepare background data using
# for UQ -- qsub -I -l place=excl -l select=1:ncpus=8:NodeType=medium -A q1086

#setup & load libraries needed for run
library(SDMTools)

################################################################################

#define & set the working directory
work.dir = '/home/jc165798/working/WallaceInitiative/'; setwd(work.dir)

#define the location of the occur files and list the files
in.dir = '/home/jc165798/working/WallaceInitiative/raw.files.20100417/unzipped/'
infiles.occur = list.files(in.dir,pattern='\\.csv')

#training data directory
train.dir = '/home/jc165798/working/WallaceInitiative/training.data/occur/'

#define the environmental variables to be used in appending data
enviro.dir = paste(work.dir,'training.data/current.0.1degree/',sep='')
enviro.layers = list.files(enviro.dir,pattern='asc.gz'); enviro.layers = gsub('\\.asc.gz','',enviro.layers) #list files and remove the suffix
#load the enviro.data
for (enviro in enviro.layers) { cat(enviro,'\n'); assign(enviro,read.asc.gz(paste(enviro.dir,enviro,'.asc.gz',sep=''))) }
cellsize = attr(get(enviro.layers[1]),'cellsize')

#define the temporary script folder
tmp.pbs = paste(work.dir,'tmp.pbs/',sep=''); dir.create(tmp.pbs); setwd(tmp.pbs); system('rm -rf *')

#cycle through each of the raw occurrence files
for (infile in infiles.occur) {
	cat(infile,'\n')
	#read in and prep occur data
	occur = read.csv(paste(in.dir,infile,sep=''),as.is=T) #read in the data
	occur = occur[,c('family','genus','specie_id','lon','lat')] #exclude extra columns
	occur$lat = round(occur$lat/cellsize)*cellsize #round lat to nearest cellsize
	occur$lon = round(occur$lon/cellsize)*cellsize #round lon to nearest cellsize
	occur = unique(occur) #keep only unique occurrence records
	
	#append the environmental data to the occurrence records
	for (enviro in enviro.layers) { cat('appending',enviro,'\n'); occur[[enviro]] = extract.data(occur[,c('lon','lat')],get(enviro)) }
	occur = na.omit(occur) #remove any records with missing data
	
	#get a species list where the species counts are < 10 records
	counts = aggregate(occur$specie_id,by=list(specie_id=occur$specie_id),length)
	species = counts$specie_id[which(counts$x>=10)]

	#remove occur  records for species not in species list
	occur = occur[which(occur$specie_id %in% species),]
	
	#write out the occurrance file
	for (fam in unique(occur$family)) {
		pos = which(occur$family==fam)
		if (length(pos)>0) {
			fam.dir = paste(train.dir,gsub('\\.csv','',infile),'/',fam,'/',sep=''); dir.create(fam.dir,recursive=TRUE)
			write.csv(occur[pos,-1:-2],paste(fam.dir,'occur.csv',sep=''),row.names=FALSE)#write out the occurrence records
		}
	}
}

###########################################################################################
#read in the processed occurance files and process them
infiles.occur = list.files(train.dir,pattern='occur.csv',recursive=TRUE); infiles.occur = gsub('/occur.csv','',infiles.occur)

#cycle through each of the files and create the necessary R script
for (infile in infiles.occur) {	cat(infile,'\n')
	outfile = gsub('/','_',infile)
	zz = file(paste(tmp.pbs,outfile,'.R',sep=''),'w') #create a temporary R script
		cat("#load the libraries \n",file=zz)
		cat("library(SDMTools) \n",file=zz)
		cat('\n',file=zz)
		cat("#read in the background file asc & individual domains \n",file=zz)
		cat("bkgd = read.asc.gz('/home/jc165798/working/WallaceInitiative/training.data/ecozone001degree.asc.gz') \n",file=zz)
		cat("for (ii in 1:8) assign(paste('bkgd.',ii,sep=''),read.csv(paste('/home/jc165798/working/WallaceInitiative/training.data/bkgd.domain.',ii,'.csv',sep=''))) \n",file=zz)
		cat('\n',file=zz)
		cat("#prepare the occurrences \n",file=zz)
		cat('work.dir="/home/jc165798/working/WallaceInitiative/models/',infile,'/"; dir.create(work.dir,recursive=TRUE); setwd(work.dir) \n',sep='',file=zz)
		cat('occur=read.csv("',train.dir,infile,'/occur.csv','",as.is=TRUE) \n',sep='',file=zz)
		cat('species=unique(occur$specie_id) \n',sep='',file=zz)
		cat('\n',file=zz)
		cat("#cycle through the species \n",file=zz)
		cat("for (spp in species){  \n",file=zz)
		cat("    dir.create(as.character(spp))  \n",file=zz)
		cat("    out.occur = occur[which(occur$specie_id==spp),]  \n",file=zz)
		cat("    tbkgd = extract.data(cbind(out.occur$lon,out.occur$lat),bkgd); tbkgd = na.omit(unique(tbkgd)) #get the unique domains \n",file=zz)
		cat("    out.bkgd = NULL; for (ii in tbkgd) out.bkgd = rbind(out.bkgd,get(paste('bkgd.',ii,sep=''))) #grab the background data for the domains \n",file=zz)
		cat("    write.csv(out.bkgd,paste(spp,'/bkgd.csv',sep=''),row.names=F) #write out the data \n",file=zz)
		cat("    write.csv(out.occur,paste(spp,'/occur.csv',sep=''),row.names=F) #write out the data \n",file=zz)
		cat("} \n",file=zz)
		cat('\n',file=zz)			
	close(zz)#close the file
}

#cycle through and submit all the sh scripts created
setwd(tmp.pbs)
R.files = list.files(,pattern='\\.R')
for (R.file in R.files) { #cycle through each of the files... create sh file and start the jobs
	zz = file(gsub('.R','.sh',R.file),'w') #start the file
		cat('#!/bin/bash\n',file=zz)
		cat('cd $PBS_O_WORKDIR\n',file=zz)
		cat('R CMD BATCH --no-save --no-restore ',R.file,'\n',sep='',file=zz)
	close(zz)#close the file
	system(paste('qsub -m n -l nodes=1:ppn=2 -l pmem=6gb ',gsub('.R','.sh',R.file),sep=''))
}
