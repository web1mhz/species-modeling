################################################################################
#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in e.g.,...
# spp=13800736 
# work.dir="/home/uqvdwj/WallaceInitiative/models/amphibia/Ambystomatidae/13800736/"
# maxent="/home/uqvdwj/WallaceInitiative/maxent.jar"
# proj.dir="/home/uqvdwj/WallaceInitiative/projecting.data/"
# train.dir="/home/uqvdwj/WallaceInitiative/training.data/" #define the directory where generic training data is
# models=TRUE
# project=TRUE
# summarize=TRUE
# clip=TRUE
# rich=TRUE
# disp.real = 100 #m pa ... this is the realistic distance a species will disperse 
# disp.opt = 500 #m pa ... this is the optimistic distance a species will disperse
# clip.dist = 2000000 #distance to clip species to

################################################################################
#load libraries & source
library(SDMTools)

#define the core functions...
#model the species distribution
model.species = function() {
	dir.create('output') #create the output directory
	#run maxent
	if (nrow(occur) >= 40) { #run the maxent model once with full data and another cross validated
		system(paste('java -mx2000m -jar ',maxent,' outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv nowarnings replicates=10 noaskoverwrite novisible nooutputgrids autorun',sep=''))
		system('cp -af output/maxentResults.csv output/maxentResults.crossvalide.csv')
		system(paste('java -mx2000m -jar ',maxent,' outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv nowarnings noaskoverwrite responsecurves novisible writebackgroundpredictions nooutputgrids autorun',sep=''))
	} else {
		system(paste('java -mx2000m -jar ',maxent,' outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv -N bio_5 -N bio_6 -N bio_16 -N bio_17 nowarnings replicates=10 noaskoverwrite novisible nooutputgrids autorun',sep=''))
		system('cp -af output/maxentResults.csv output/maxentResults.crossvalide.csv')
		system(paste('java -mx2000m -jar ',maxent,' outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv -N bio_5 -N bio_6 -N bio_16 -N bio_17 nowarnings noaskoverwrite responsecurves novisible writebackgroundpredictions nooutputgrids autorun',sep=''))
	}
}

#do the projections
project.species = function() {
	if (!file.exists(paste('output/',spp,'.lambdas',sep=''))){ quit('no') } #stop if maxent fails
	proj.list = list.files(proj.dir)
	for (projx in proj.list) { cat(projx,'\n')
		system(paste('java -cp ',maxent,' density.Project output/',spp,'.lambdas ',proj.dir,projx,' output/',projx,'.asc fadebyclamping nowriteclampgrid \n',sep=""))
	}
	system('gzip output/*.asc') #compress the ascii grid files
}

#summarizing the model outputs
summarize.species =function() {
	if (!file.exists(paste('output/',spp,'.lambdas',sep=''))){ quit('no') } #stop if maxent was not run
	
	out.dir = paste(work.dir,'summaries/',sep=''); dir.create(out.dir) #define the summary output directory

	###summarize the accuracy of the models
	out = data.frame(spp = spp)
	maxent.results = read.csv('output/maxentResults.csv')
	maxent.results.cross.validate = read.csv('output/maxentResults.crossvalide.csv')
	pa = data.frame(obs=1,pred=read.csv(paste('output/',spp,'_samplePredictions.csv',sep=''))$Logistic.prediction)
	pa = rbind(pa,data.frame(obs=0,pred=read.csv(paste('output/',spp,'_backgroundPredictions.csv',sep=''))$logistic))
	#get the AUCs
	out$AUC.training = maxent.results$Training.AUC
	out$AUC.train.mean = maxent.results.cross.validate$Training.AUC[nrow(maxent.results.cross.validate)]
	out$AUC.test.mean = maxent.results.cross.validate$Test.AUC[nrow(maxent.results.cross.validate)]
	out$AUC = auc(pa$obs,pa$pred)
	#extract the variables of importance
	for (ii in grep('contrib',names(maxent.results))) out[names(maxent.results)[ii]] = maxent.results[,ii]
	#write out the data & compress it
	write.csv(out,gzfile(paste(out.dir,'accuracy.csv.gz',sep='')),row.names=FALSE)

	#stop here if the accuracy is shit
	if (out$AUC[1]<0.7) quit('no')

	###summarize thresholds and accuracy
	out = optim.thresh(pa$obs,pa$pred); for (ii in names(out)) out[[ii]] = mean(out[[ii]])
	out = data.frame(type=names(out),accuracy(pa$obs,pa$pred,threshold=as.vector(unlist(out))))
	threshold = out$threshold[out$type=='min.ROC.plot.distance']
	#write out the data& compress it
	write.csv(out,gzfile(paste(out.dir,'thresholds.csv.gz',sep='')),row.names=FALSE)

	###########################################################################################
	#create a summary dataset for applying dispersal and richness to
	pos = out = read.csv(paste(train.dir,'mask.pos.csv',sep=''),as.is=TRUE)
	#append the occurrences
	toccur = occur[,c('lat','lon')]; 
	lats = unique(pos$lat)-0.25; lats = c(lats,max(lats+0.5)); lats = sort(lats)
	toccur$lat = as.numeric(as.character(cut(toccur$lat,lats,labels=lats[-length(lats)]-0.25)))
	lons = unique(pos$lon)-0.25; lons = c(lons,max(lons+0.5)); lons = sort(lons)
	toccur$lon = as.numeric(as.character(cut(toccur$lon,lons,labels=lons[-length(lons)]-0.25)))
	toccur$occur=1; toccur = unique(toccur) #define occur locations
	out = merge(out,toccur,all.x=TRUE,all.y=FALSE)

	###process all future scenarios
	proj.list = list.files('output/',pattern='\\.asc.gz') #get a list of all asc.gz files
	if(length(grep('current_0.1',proj.list))>0) { proj.list = proj.list[-grep('current_0.1',proj.list)] } ; proj.list = gsub('\\.asc.gz','',proj.list) 
	#cycle through the projections and extract the information
	for (projx in proj.list) { cat(projx,'\n')
		out[projx] = extract.data(cbind(pos$lon,pos$lat),read.asc.gz(paste('output/',projx,'.asc.gz',sep='')))
	}
	#write out the projection data
	write.csv(out,gzfile(paste(out.dir,'predictions.raw.csv.gz',sep='')),row.names=FALSE)
	#convert to binary by applying threshold & write out data
	tout = as.matrix(out[proj.list])
	tout[which(tout<threshold)] = 0; tout[which(tout>0)] = 1
	out[proj.list] = tout
	#write out the projection data
	write.csv(out,gzfile(paste(out.dir,'predictions.binary.csv.gz',sep='')),row.names=FALSE)
}

#clip the species distributions and apply dispersal values
clip.species = function() {
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
}

#summarize info for richness calculations
rich.species = function(){
	indata = as.matrix(read.csv(gzfile('summaries/predictions.binary.dispersal.csv.gz'),as.is=TRUE)) #read in the data

	out.dir = paste(work.dir,'richness/',sep=''); dir.create(out.dir) #define the summary output directory
	
	#define the outputs
	n = 0 #track the number of species
	no.sum = no.loss = real.sum = real.loss = real.gain = opt.sum = opt.loss = opt.gain = NULL #these are the basic data outputs
	tnames = colnames(indata); outnames = tnames[grep('_',tnames)]
	no.sum = indata[,outnames] #just keep the columns of interest
	no.sum[,] = 0 #set everything == 0
	no.loss = real.sum = real.loss = real.gain = opt.sum = opt.loss = opt.gain = no.sum #set starting work to all 0
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
	
	#write the outputs
	write.csv(no.sum,gzfile(paste(out.dir,'no.disp.sum.csv.gz',sep='')),row.names=FALSE)
	write.csv(no.loss,gzfile(paste(out.dir,'no.disp.loss.csv.gz',sep='')),row.names=FALSE)
	write.csv(real.sum,gzfile(paste(out.dir,'real.sum.csv.gz',sep='')),row.names=FALSE)
	write.csv(real.loss,gzfile(paste(out.dir,'real.loss.csv.gz',sep='')),row.names=FALSE)
	write.csv(real.gain,gzfile(paste(out.dir,'real.gain.csv.gz',sep='')),row.names=FALSE)
	write.csv(opt.sum,gzfile(paste(out.dir,'opt.sum.csv.gz',sep='')),row.names=FALSE)
	write.csv(opt.loss,gzfile(paste(out.dir,'opt.loss.csv.gz',sep='')),row.names=FALSE)
	write.csv(opt.gain,gzfile(paste(out.dir,'opt.gain.csv.gz',sep='')),row.names=FALSE)
}

###########################################################################################
setwd(work.dir) #set the working directory
occur = read.csv('occur.csv') #read in the occurance records

if (models) model.species()
if (project) project.species()
if (summarize) summarize.species()
if (clip) clip.species()
if (rich) rich.species()



