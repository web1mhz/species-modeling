################################################################################
#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in disp.real, disp.opt, spp & out.dir
# disp.real = 1500 #m pa ... this is the realistic distance a species will disperse 
# disp.opt = 3000 #m pa ... this is the optimistic distance a species will disperse
# spp = 13798185
# out.dir = '/homes/31/jc165798/working/Wallace.Initiative/summaries/csv/amphibia/'

################################################################################
#load libraries & define functions
library(SDMTools)

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

################################################################################
#
#read in the data
tfile = paste(out.dir,spp,'.predictions.binary.csv.gz',sep='') #this is the binary data file
tdata = read.csv(gzfile(tfile),as.is=TRUE)
if (length(grep('threshold',names(tdata)))>0) tdata$threshold=NULL #remove the threshold column if there

#append cell area rounded to the nearest square km
tx = latlon.grid.info(unique(tdata$lat),0.5); #extract cell info
tx$top = tx$bottom = tx$side = tx$diagnal = NULL #set extra rows to null
tx$area = round(tx$area/1000^2) #convert to km2
tdata = merge(tdata,tx) #append the area column to tdata

#define the suitable dispersal rows of tdata
no.disp = which(tdata$current.clipped==1) # current and no dispersal futures
pot.2020.real = pot.2050.real = pot.2080.real = no.disp #set up the basic location for the realistic dispersal
pot.2020.opt = pot.2050.opt = pot.2080.opt = no.disp #set up the basic location for the optimistic dispersal

#cycle through all locations, calculate distances and append rows as appropriate
tt = as.matrix(data.frame(lat1=tdata$lat[no.disp],lon1=tdata$lon[no.disp],lat2=0,lon2=0)) #prepare the matrix for getting distances
real.dists = c(disp.real*45,disp.real*75,disp.real*105); opt.dists = c(disp.opt*45,disp.opt*75,disp.opt*105) #define the distances for the years
for (ii in c(1:nrow(tdata))[-no.disp]) { if(ii%%1000==0) cat(ii,'\n') #cycle through all locations not in current distribution
	tt[,3] = tdata$lat[ii]; tt[,4] = tdata$lon[ii] #populate the data table
	min.dist = min(distance(tt)$distance,na.rm=TRUE) #get the minimum distance
	#check the distances
	if (min.dist<=opt.dists[3]) {
		pot.2080.opt = c(pot.2080.opt,ii) #append the row as suitable
		if (min.dist<=opt.dists[2]) {
			pot.2050.opt = c(pot.2050.opt,ii) #append the row as suitable
			if (min.dist<=opt.dists[1]) {
				pot.2020.opt = c(pot.2020.opt,ii) #append the row as suitable
			}
		}
		if (min.dist<=real.dists[3]) {
			pot.2080.real = c(pot.2080.real,ii) #append the row as suitable
			if (min.dist<=real.dists[2]) {
				pot.2050.real = c(pot.2050.real,ii) #append the row as suitable
				if (min.dist<=real.dists[1]) {
					pot.2020.real = c(pot.2020.real,ii) #append the row as suitable
				}
			}
		}		
	}
}

#append the dispersal columns
tdata$pot.2080.real = tdata$pot.2050.real = tdata$pot.2020.real = tdata$no.disp = 0
tdata$pot.2080.opt = tdata$pot.2050.opt = tdata$pot.2020.opt = 0
#populate tdata dispersal info
tdata$pot.2080.real[pot.2080.real] = tdata$pot.2050.real[pot.2050.real] = tdata$pot.2020.real[pot.2020.real] = tdata$no.disp[no.disp] = 1
tdata$pot.2080.opt[pot.2080.opt] = tdata$pot.2050.opt[pot.2050.opt] = tdata$pot.2020.opt[pot.2020.opt] = 1
#write out the projection data
write.csv(tdata,gzfile(paste(out.dir,spp,'.predictions.binary.dispersal.csv.gz',sep='')),row.names=FALSE)

#convert and work with matrix
tdata=as.matrix(tdata);tnames = colnames(tdata)

#define the variables of interest
tarea = sum(tdata[,'current_0.5degrees'] * tdata[,'no.disp'] * tdata[,'area'],na.rm=TRUE) #get the current area
out = data.frame(spp=spp,scenario='current_0.5degrees',area.no.disp=tarea,area.real.disp=NA,area.real.novel=NA,area.opt.disp=NA,area.opt.novel=NA) #start the output data.frame
for (tname in tnames[grep('_2020_',tnames)]) {
	tarea.novel = NA
	tarea = sum(tdata[,tname] * tdata[,'no.disp'] * tdata[,'area'],na.rm=TRUE)
	tarea = c(tarea,sum(tdata[,tname] * tdata[,'pot.2020.real'] * tdata[,'area'],na.rm=TRUE))
	tarea.novel = c(tarea.novel, tarea[2] - sum(tdata[,tname] * tdata[,'no.disp'] * tdata[,'area'],na.rm=TRUE))
	tarea = c(tarea,sum(tdata[,tname] * tdata[,'pot.2020.opt'] * tdata[,'area'],na.rm=TRUE))
	tarea.novel = c(tarea.novel, tarea[3] - sum(tdata[,tname] * tdata[,'no.disp'] * tdata[,'area'],na.rm=TRUE))
	out = rbind(out,data.frame(spp=spp,scenario=tname,area.no.disp=tarea[1],area.real.disp=tarea[2],area.real.novel=tarea.novel[2],area.opt.disp=tarea[3],area.opt.novel=tarea.novel[3]))
}
for (tname in tnames[grep('_2050_',tnames)]) {
	tarea.novel = NA
	tarea = sum(tdata[,tname] * tdata[,'no.disp'] * tdata[,'area'],na.rm=TRUE)
	tarea = c(tarea,sum(tdata[,tname] * tdata[,'pot.2050.real'] * tdata[,'area'],na.rm=TRUE))
	tarea.novel = c(tarea.novel, tarea[2] - sum(tdata[,tname] * tdata[,'no.disp'] * tdata[,'area'],na.rm=TRUE))
	tarea = c(tarea,sum(tdata[,tname] * tdata[,'pot.2050.opt'] * tdata[,'area'],na.rm=TRUE))
	tarea.novel = c(tarea.novel, tarea[3] - sum(tdata[,tname] * tdata[,'no.disp'] * tdata[,'area'],na.rm=TRUE))
	out = rbind(out,data.frame(spp=spp,scenario=tname,area.no.disp=tarea[1],area.real.disp=tarea[2],area.real.novel=tarea.novel[2],area.opt.disp=tarea[3],area.opt.novel=tarea.novel[3]))
}
for (tname in tnames[grep('_2080_',tnames)]) {
	tarea.novel = NA
	tarea = sum(tdata[,tname] * tdata[,'no.disp'] * tdata[,'area'],na.rm=TRUE)
	tarea = c(tarea,sum(tdata[,tname] * tdata[,'pot.2080.real'] * tdata[,'area'],na.rm=TRUE))
	tarea.novel = c(tarea.novel, tarea[2] - sum(tdata[,tname] * tdata[,'no.disp'] * tdata[,'area'],na.rm=TRUE))
	tarea = c(tarea,sum(tdata[,tname] * tdata[,'pot.2080.opt'] * tdata[,'area'],na.rm=TRUE))
	tarea.novel = c(tarea.novel, tarea[3] - sum(tdata[,tname] * tdata[,'no.disp'] * tdata[,'area'],na.rm=TRUE))
	out = rbind(out,data.frame(spp=spp,scenario=tname,area.no.disp=tarea[1],area.real.disp=tarea[2],area.real.novel=tarea.novel[2],area.opt.disp=tarea[3],area.opt.novel=tarea.novel[3]))
}

#calulate proportions
out$prop.cur.no.disp = out$area.no.disp/out$area.no.disp[1]
out$prop.cur.real.disp = out$area.real.disp/out$area.no.disp[1]
out$prop.cur.opt.disp = out$area.opt.disp/out$area.no.disp[1]

out$scenario = gsub('A1B_','',out$scenario) #get rid of emmission scenario
out$scenario[grep('current',out$scenario)] = 'current' #redefine the cuurent name
out$year = out$GCM = out$ES = out$scenario #set new columns to out$scenario
out$year = gsub('_cccma_cgcm31','',out$year)
out$year = gsub('_csiro_mk30','',out$year)
out$year = gsub('_ipsl_cm4','',out$year)
out$year = gsub('_mpi_echam5','',out$year)
out$year = gsub('_ncar_ccsm30','',out$year)
out$year = gsub('_ukmo_hadcm3','',out$year)
out$year = gsub('_ukmo_hadgem1','',out$year)
out$ES = out$year; out$ES = gsub('_2020','',out$ES); out$ES = gsub('_2050','',out$ES); out$ES = gsub('_2080','',out$ES); 
for (ii in unique(out$ES)) { out$year = gsub(paste(ii,'_',sep=''),'',out$year) } ; out$year[which(out$year=='current')] = 1990 ; out$year = as.numeric(out$year)
for (ii in unique(out$ES)) { for (jj in unique(out$year)) { out$GCM = gsub(paste(ii,'_',jj,'_',sep=''),'',out$GCM) } } 
out$scenario=NULL #set the scenario to null as it is no longer needed
out = out[,c(1,10:12,2:9)] #reorder columns

#write out the projection data
write.csv(out,gzfile(paste(out.dir,spp,'.prediction.area.csv',sep='')),row.names=FALSE)

