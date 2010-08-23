# grab interactive node to prepare background data using
# qsub -I -l place=excl -l select=1:ncpus=8:NodeType=medium -A q1086

#setup the libraries
library(SDMTools)

#define & set the working directory
work.dir = '/home/uqvdwj/WallaceInitiative/training.data/'; setwd(work.dir)

#read in the background file
bkgd = read.asc.gz('ecozone001degree.asc.gz')

#define the environmental variables to be used in appending data
enviro.dir = paste(work.dir,'current.0.1degree/',sep='')
enviro.layers = list.files(enviro.dir,pattern='asc.gz'); enviro.layers = gsub('\\.asc.gz','',enviro.layers) #list files and remove the suffix
#load the enviro.data
for (enviro in enviro.layers) { cat(enviro,'\n'); assign(enviro,read.asc.gz(paste(enviro.dir,enviro,'.asc.gz',sep=''))) }
cellsize = attr(get(enviro.layers[1]),'cellsize')

### cycle through each of the domains and...
# - extract 10000 random background points
# - append the environmental data
# - write out the file
for (ii in 1:8) {
	cat(ii,'\n')
	#extract the positions within the domain of interest
	pos = as.data.frame(which(bkgd==ii,arr.ind=T)) #get the locations of the domain
	pos$lon = getXYcoords(bkgd)$x[pos$row] #get the longitudes
	pos$lat = getXYcoords(bkgd)$y[pos$col] #get the latitudes
	#append the envirodata
	for (enviro in enviro.layers) { cat('appending',enviro,'\n'); pos[[enviro]] = extract.data(pos[,c('lon','lat')],get(enviro)) }
	pos = na.omit(pos) #remove any records with missing data
	#get the 10000 random positions
	if (nrow(pos)>10000) pos = pos[sample(1:nrow(pos),10000),]#keep on 10000 pnts
	#write out the data
	pos$row = pos$col = NULL
	pos = data.frame(spp=paste('domain.',ii,sep=''),pos)
	write.csv(pos,paste('bkgd.domain.',ii,'.csv',sep=''),row.names=F)
}

###prepare mask & points for summarizing all future model outputs...
bkgd05 = read.asc.gz('ecozone05degree.asc.gz') #read in the coarser background

mask = bkgd05; mask[which(is.finite(bkgd05))] = 0 #this is an mask of terrestrial environment
write.asc.gz(mask,'mask.asc') #write out the mask
pos = as.data.frame(which(is.finite(mask),arr.ind=TRUE)) #get the positions
pos$lat = getXYcoords(mask)$y[pos$col]; pos$lon = getXYcoords(mask)$x[pos$row] #convert to lat & long
pos$ecozone0.5 = extract.data(cbind(pos$lon,pos$lat),bkgd05)#append the domain (contenent) info
pos$ecozone0.01 = extract.data(cbind(pos$lon,pos$lat),bkgd)#append the domain (contenent) info

#append cell area rounded to the nearest square km
tx = grid.info(unique(pos$lat),0.5); #extract cell info
tx$top = tx$bottom = tx$side = tx$diagnal = NULL #set extra rows to null
tx$area = round(tx$area/1000^2) #convert to km2
pos = merge(pos,tx) #append the area column to tdata

#write out the position information
write.csv(pos,'mask.pos.csv',row.names=FALSE)
