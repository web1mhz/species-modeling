#setup the libraries
library(SDMTools)

#define & set the working directory
work.dir = '/data/jc165798/WallaceInitiative/training.data/'; setwd(work.dir)

#read in the background file
bkgd = read.asc.gz('ecozone001degree.asc.gz')

#define the environmental variables to be used in appending data
enviro.dir = '/data/jc165798/WallaceInitiative/training.data/current.0.1degree/'
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

latlon.grid.info = function(lats,cellsize) {
	r=6378137; r2 = r^2 #radius of earth
	###need checks to ensure lats will not go beyond 90 & -90
	if (length(cellsize)==1) cellsize=rep(cellsize,2) #ensure cellsize is defined for both lat & lon
	out = data.frame(lat=lats) #setup the output dataframe
	toplats = lats+(0.5*cellsize[1]); bottomlats = lats-(0.5*cellsize[1]) #define the top and bottom lats
	out$top = distance(toplats,rep(0,length(lats)),toplats,rep(cellsize[2],length(lats)))$distance
	out$bottom = distance(bottomlats,rep(0,length(lats)),bottomlats,rep(cellsize[2],length(lats)))$distance
	out$side = distance(toplats,rep(0,length(lats)),bottomlats,rep(0,length(lats)))$distance
	out$diagnal = distance(toplats,rep(0,length(lats)),bottomlats,rep(cellsize[2],length(lats)))$distance
	#calculate area of a spherical triangle using spherical excess associated by knowing distances
	#tan(E/4) = sqrt(tan(s/2)*tan((s-a)/2)*tan((s-b)/2)*tan((s-c)/2))
	#where a, b, c = sides of spherical triangle
	#s = (a + b + c)/2
	#from CRC Standard Mathematical Tables
	#calculate excess based on  l'Huiller's formula (http://williams.best.vwh.net/avform.htm for more info)
	#code modified from (http://forum.worldwindcentral.com/showthread.php?t=20724)
	excess = function(lam1,lam2,beta1,beta2){ #calculate excess... inputs are in radians
		haversine = function(y) { (1-cos(y))/2 }
		cosB1 = cos(beta1); cosB2 = cos(beta2)
		hav1 = haversine(beta2-beta1) + cosB1*cosB2*haversine(lam2-lam1)
		aa = 2 * asin(sqrt(hav1)); bb = 0.5*pi - beta2; cc = 0.5*pi - beta1
		ss = 0.5*(aa+bb+cc)
		tt = tan(ss/2)*tan((ss-aa)/2)*tan((ss-bb)/2)*tan((ss-cc)/2)
		return(abs(4*atan(sqrt(abs(tt)))))		
	}
	out$area = excess(lam1=0,lam2=cellsize[2]*pi/180,toplats*pi/180,toplats*pi/180)
	out$area = abs(out$area-excess(lam1=0,lam2=cellsize[2]*pi/180,bottomlats*pi/180,bottomlats*pi/180))*r2
	return(out)
}
#append cell area rounded to the nearest square km
tx = latlon.grid.info(unique(pos$lat),0.5); #extract cell info
tx$top = tx$bottom = tx$side = tx$diagnal = NULL #set extra rows to null
tx$area = round(tx$area/1000^2) #convert to km2
pos = merge(pos,tx) #append the area column to tdata

#write out the position information
write.csv(pos,'mask.pos.csv',row.names=FALSE)
