#setup the libraries
.libPaths(c(.libPaths(),'/homes/31/jc165798/R_libraries'))
library(SDMTools)

#define & set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/'; setwd(work.dir)

#read in the background file
bkgd = read.asc.gz('background.selection.mask.asc.gz')

#define the environmental variables to be used in appending data
enviro.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/current.0.1degree/'
enviro.layers = list.files(enviro.dir,pattern='asc.gz'); enviro.layers = gsub('\\.asc.gz','',enviro.layers) #list files and remove the suffix
#load the enviro.data
for (enviro in enviro.layers) { cat(enviro,'\n'); assign(enviro,read.asc.gz(paste(enviro.dir,enviro,'.asc.gz',sep=''))) }
cellsize = attr(get(enviro.layers[1]),'cellsize')

### cycle through each of the domains and...
# - extract 10000 random background points
# - append the environmental data
# - write out the file
for (ii in 1:6) {
	cat(ii,'\n')
	#extract the positions within the domain of interest
	pos = as.data.frame(which(bkgd==ii,arr.ind=T)) #get the locations of the domain
	pos$lon = getXYcoords(bkgd)$x[pos$row] #get the longitudes
	pos$lat = getXYcoords(bkgd)$y[pos$col] #get the latitudes
	#append the envirodata
	for (enviro in enviro.layers) { cat('appending',enviro,'\n'); pos[[enviro]] = extract.data(pos[,c('lon','lat')],get(enviro)) }
	pos = na.omit(pos) #remove any records with missing data
	#get the 10000 random positions
	pos = pos[sample(1:nrow(pos),10000),]#keep on 10000 pnts
	#write out the data
	pos$row = pos$col = NULL
	pos = data.frame(spp=paste('domain.',ii,sep=''),pos)
	write.csv(pos,paste('bkgd.domain.',ii,'.csv',sep=''),row.names=F)
}

