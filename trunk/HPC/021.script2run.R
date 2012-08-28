################################################################################
#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in something like
# group="amphibia"
# tname='real.sum.csv.gz'

################################################################################
# load libraries and add functions
library(SDMTools)

################################################################################
# start doing some work

#define / create some directories
base.dir = '/home/jc165798/working/WallaceInitiative_1.0/summaries/'; setwd(base.dir) #this is the basic input and output directory

#cycle through and get richness for taxa
out = NULL #defien the output file
tfiles=list.files(paste('richness/family/',group,sep=''),pattern=tname,full.names=TRUE,recursive=TRUE) #get a list of the files
for (tfile in tfiles) { cat(tfile,'\n')
	tdata = as.matrix(read.csv(gzfile(tfile),as.is=TRUE))
	if (is.null(out)) { out=tdata } else { out = out[,] + tdata[,] }
}
#write out the data
dir.create(paste('richness/taxa/',group,'/',sep=''),recursive=TRUE)
write.csv(out,gzfile(paste('richness/taxa/',group,'/',tname,sep='')),row.names=FALSE)

## create GIS files if tname=='real.sum.csv.gz'
if (tname=='real.sum.csv.gz') {
	#create output directory
	tdir = paste('GIS/taxa/',group,'/',sep=''); dir.create(tdir,recursive=TRUE)
	
	#read in the mask and the positions
	train.dir = '/home/jc165798/working/WallaceInitiative_1.0/training.data/' #define the directory where generic training data is
	pos = read.csv(paste(train.dir,'mask.pos.csv',sep=''),as.is=TRUE)
	mask = read.asc.gz(paste(train.dir,'mask.asc.gz',sep=''))

	#start summarizing data
	outnames=colnames(out); tdata = out;
	tasc = mask; tasc[cbind(pos$row,pos$col)] = tdata[,'current_0.5degrees']; write.asc.gz(tasc,paste(tdir,'current.asc',sep='')) #write out the current gis file	
	for (ES in c('A1B_A30r5l','A1B_A30r2h','A1B_A16r5l','A1B_A16r4l','A1B_A16r2h','SRES_A1B')) {
		for (year in c(2020,2050,2080)) {
			tasc = mask; tasc[cbind(pos$row,pos$col)] = rowMeans(tdata[,outnames[intersect(grep(year,outnames),grep(ES,outnames))]]) #extract the mean for the columns of interest
			write.asc.gz(tasc,paste(tdir,year,'_',ES,'_mean.asc',sep='')) #write out the current gis file
		}
	}	
}

# create GIS files if tname=='no.disp.sum.csv.gz'
# if (tname=='no.disp.sum.csv.gz') {
	##create output directory
	# tdir = paste('GIS/taxa/',group,'/',sep=''); dir.create(tdir,recursive=TRUE)
	
	##read in the mask and the positions
	# train.dir = '/home/jc165798/working/WallaceInitiative_1.0/training.data/' #define the directory where generic training data is
	# pos = read.csv(paste(train.dir,'mask.pos.csv',sep=''),as.is=TRUE)
	# mask = read.asc.gz(paste(train.dir,'mask.asc.gz',sep=''))

	##start summarizing data
	# outnames=colnames(out); tdata = out;
	# tdata = tdata[,] / tdata[,"current_0.5degrees"] #make everything a proportion of current
	# for (ES in c('A1B_A30r5l','A1B_A30r2h','A1B_A16r5l','A1B_A16r4l','A1B_A16r2h','SRES_A1B')) {
		# for (year in c(2020,2050,2080)) {
			# tt = tdata[,outnames[intersect(grep(year,outnames),grep(ES,outnames))]]; tt[which(tt<0.75)] = 0; tt[which(tt>0)] = 1
			# refuge.certainty = mask; refuge.certainty[cbind(pos$row,pos$col)] = rowSums(tt) #refugica certainty
			# tt = tdata[,outnames[intersect(grep(year,outnames),grep(ES,outnames))]]; tt[,] = 1-tt[,]; tt[which(tt<0.75)] = 0; tt[which(tt>0)] = 1
			# AOC.certainty = mask; AOC.certainty[cbind(pos$row,pos$col)] = rowSums(tt) #AOC is area of concern
			
			# write.asc.gz(refuge.certainty,paste(tdir,year,'_',ES,'_refuge.certainty.asc',sep='')) #write out the current gis file
			# write.asc.gz(AOC.certainty,paste(tdir,year,'_',ES,'_AOC.certainty.asc',sep='')) #write out the current gis file
		# }
	# }	
# }

			