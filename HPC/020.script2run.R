################################################################################
#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in e.g.,...
# spp=13749423 
# work.dir="/data/jc165798/WallaceInitiative/models/mammalia/13749423/"
# disp.real = 1500 #m pa ... this is the realistic distance a species will disperse 
# disp.opt = 3000 #m pa ... this is the optimistic distance a species will disperse
# clip.dist = 2000000 #distance to clip species to

################################################################################
#load libraries & define functions
library(SDMTools)

################################################################################
setwd(work.dir) #set the working directory
indata = read.csv(gzfile('summaries/predictions.binary.csv.gz'),as.is=TRUE) #read in the data

#append columns to clip to domain & clip.dist
pos = which(is.finite(indata$occur)) #this defines the rows of data where the species occurred
indata$domain.clip = 0; indata$domain.clip[which(indata$ecozone0.5 %in% unique(indata$ecozone0.5[pos]))] = 1 #append column for suitable domains
tt = as.matrix(data.frame(lat1=indata$lat[pos],lon1=indata$lon[pos],lat2=0,lon2=0)) #prepare the matrix for getting distances
no.disp = pos #setup no dispersal rows
for (ii in c(1:nrow(indata))[-no.disp]) { if(ii%%1000==0) cat(ii,'\n') #cycle through all locations not in current distribution
	tt[,3] = indata$lat[ii]; tt[,4] = indata$lon[ii] #populate the data table
	min.dist = min(distance(tt)$distance,na.rm=TRUE) #get the minimum distance
	if(min.dist<=clip.dist) no.disp = c(no.disp,ii) #append the extend to the clip.dist
}
indata$dist.clip = 0; indata$dist.clip[no.disp] = 1 #set cells within clip.dist to 1
indata$current.clip = indata$current_0.5degrees * indata$dist.clip * indata$domain.clip #set current distributions clipped to distance and domain

#define the suitable dispersal rows of indata
no.disp = which(indata$current.clip==1) # current and no dispersal futures
pot.2020.real = pot.2050.real = pot.2080.real = no.disp #set up the basic location for the realistic dispersal
pot.2020.opt = pot.2050.opt = pot.2080.opt = no.disp #set up the basic location for the optimistic dispersal

#cycle through all locations, calculate distances and append rows as appropriate
tt = as.matrix(data.frame(lat1=indata$lat[no.disp],lon1=indata$lon[no.disp],lat2=0,lon2=0)) #prepare the matrix for getting distances
real.dists = c(disp.real*45,disp.real*75,disp.real*105); opt.dists = c(disp.opt*45,disp.opt*75,disp.opt*105) #define the distances for the years
for (ii in c(1:nrow(indata))[-no.disp]) { if(ii%%1000==0) cat(ii,'\n') #cycle through all locations not in current distribution
	tt[,3] = indata$lat[ii]; tt[,4] = indata$lon[ii] #populate the data table
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
indata$pot.2080.real = indata$pot.2050.real = indata$pot.2020.real = indata$no.disp = 0
indata$pot.2080.opt = indata$pot.2050.opt = indata$pot.2020.opt = 0
#populate indata dispersal info
indata$pot.2080.real[pot.2080.real] = indata$pot.2050.real[pot.2050.real] = indata$pot.2020.real[pot.2020.real] = indata$no.disp[no.disp] = 1
indata$pot.2080.opt[pot.2080.opt] = indata$pot.2050.opt[pot.2050.opt] = indata$pot.2020.opt[pot.2020.opt] = 1
#write out the projection data
write.csv(indata,gzfile('summaries/predictions.binary.dispersal.csv.gz'),row.names=FALSE)

#convert and work with matrix
tdata=as.matrix(indata);tnames = colnames(tdata)

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
write.csv(out,gzfile('summaries/prediction.area.csv.gz'),row.names=FALSE)

