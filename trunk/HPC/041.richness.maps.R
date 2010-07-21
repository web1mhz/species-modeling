#load the libraries
library(SDMTools)

#define some directories
work.dir = '/data/jc165798/WallaceInitiative/richness/data/'; setwd(work.dir)
out.dir = '/data/jc165798/WallaceInitiative/richness/images/'; dir.create(out.dir)
train.dir = '/data/jc165798/WallaceInitiative/training.data/' #define the directory where generic training data is

#read in the mask and the positions
pos = read.csv(paste(train.dir,'mask.pos.csv',sep=''),as.is=TRUE)
mask = read.asc.gz(paste(train.dir,'mask.asc.gz',sep=''))

#start working with the data
groups = list.files(,pattern='no.disp.sum.csv.gz'); groups = gsub('\\.no.disp.sum.csv.gz','',groups)

tname = NULL
#cycle through each of the groups
for (group in groups) {
	#start with the no dispersal & species richness
	tdata = as.matrix(read.csv(gzfile(paste(group,'.no.disp.sum.csv.gz',sep='')),as.is=TRUE))
	if (is.null(tname)) {
		tnames = colnames(tdata) #get the column names
		years = c(2020,2050,2080)
		ESs = gsub('A1B_','',tnames); ESs = ESs[-which(ESs=="current_0.5degrees")]
		for (ii in years) { ESs = gsub(ii,'',ESs) } ; ESs = unique(ESs)
		for (ii in 1:length(ESs)) { ESs[ii] = strsplit(ESs[ii],'__')[[1]][1] } ; ESs = unique(ESs)
		
	}
	current = mask.asc; current[cbind(pos$row,pos$col)] = tdata[,"current_0.5degrees"] #Create as ascii file for present
	#****
	for (year in years) { 
		for (ES in ESs) {
			tmean = mask; tmean[cbind(pos$row,pos$col)] = rowMeans(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]])
			tmin = mask; tmin[cbind(pos$row,pos$col)] = apply(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,min)
			tmax = mask; tmax[cbind(pos$row,pos$col)] = apply(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,max)
			#****
			#proportion change?
			tmean = tmean / current; tmin = tmin / current; tmax = tmax / current
			#****
		}
	}
	#work with no.disp loss
	for (year in years) { 
		for (ES in ESs) {
			tmean = mask; tmean[cbind(pos$row,pos$col)] = rowMeans(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]])
			tmin = mask; tmin[cbind(pos$row,pos$col)] = apply(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,min)
			tmax = mask; tmax[cbind(pos$row,pos$col)] = apply(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,max)
			#****
			#proportion change?
		}
	}	
	
}