################################################################################
#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in spp & out.dir

################################################################################
#load libraries & source
library(SDMTools)

###########################################################################################
###########################################################################################
#setup the constants / directory structure

#define and set directories
work.dir = paste('/tmp/',spp,'/',sep=''); setwd(work.dir) #move the working directory into the species directory

################################################################################
#work out the summarizing and visualization script prior to use in Rnw
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
write.csv(out,gzfile(paste(out.dir,spp,'.accuracy.csv.gz',sep='')),row.names=FALSE)

#stop here if the accuracy is shit
if (out$AUC[1]<0.7) quit('no')

###summarize thresholds and accuracy
out = optim.thresh(pa$obs,pa$pred); for (ii in names(out)) out[[ii]] = mean(out[[ii]])
out = data.frame(type=names(out),accuracy(pa$obs,pa$pred,threshold=as.vector(unlist(out))))
threshold = out$threshold[out$type=='min.ROC.plot.distance']
#write out the data& compress it
write.csv(out,gzfile(paste(out.dir,spp,'.thresholds.csv.gz',sep='')),row.names=FALSE)

### create comprehensive csv prediction files
##read in the occur data
occur = read.csv('occur.csv')

#define the convex hull
hull = occur[chull(cbind(occur$lat,occur$lon)),2:3] #get the convex hull of the current occurences
lons = lats = NULL #objects to store points buffering hull points
for (bear in seq(0,length=360,by=1)) { #cycle through 360 directions and get points at 500 km from hull points
	tt = destination(hull$lat,hull$lon,bearing = bear,distance = 500000)
	lons = c(lons,tt$lon2); lats = c(lats,tt$lat2)
}
hull.buff = chull(cbind(lats,lons)) #get the convex hull of the buffered points
hull.buff = data.frame(lon = lons[hull.buff], lat = lats[hull.buff]) #get lat/long of the buffered convex hull

##read in the current distribution
cur.asc = read.asc.gz('output/current_0.5degrees.asc.gz') #read in the data
cur.asc[which(is.finite(cur.asc) & cur.asc<threshold)] = 0 #set everything below the threshold to 0
#now clip the base asc to a 500 km buffer of the convex hull
pos = as.data.frame(which(is.finite(cur.asc) & cur.asc>=threshold, arr.ind=T)) #define the position of the potential distribution
pos$lat = getXYcoords(cur.asc)$y[pos$col]; pos$lon = getXYcoords(cur.asc)$x[pos$row] #convert to lat & long
pos$in.hull.buff = pnt.in.poly(cbind(pos$lon,pos$lat),cbind(hull.buff$lon,hull.buff$lat))$pip #check if lat/longs are with polygon defined by hull.buff
cur.asc[cbind(pos$row[which(pos$in.hull.buff==0)],pos$col[which(pos$in.hull.buff==0)])] = 0 #set all values outside hull to 0

#create a mask asc & pos dataframe if is does not exist
if (file.exists('/homes/31/jc165798/working/Wallace.Initiative/summaries/mask.pos.csv.gz')) {
	pos = out = read.csv(gzfile('/homes/31/jc165798/working/Wallace.Initiative/summaries/mask.pos.csv.gz'),as.is=TRUE)
} else {
	mask = cur.asc; mask[which(is.finite(cur.asc))] = 0 #this is an mask of terrestrial environment
	write.asc.gz(mask,'/homes/31/jc165798/working/Wallace.Initiative/summaries/mask.asc') #write out the mask
	pos = as.data.frame(which(is.finite(mask),arr.ind=TRUE)) #get the positions
	pos$lat = getXYcoords(mask)$y[pos$col]; pos$lon = getXYcoords(mask)$x[pos$row] #convert to lat & long
	pos$domain = extract.data(cbind(pos$lon,pos$lat),read.asc.gz('/homes/31/jc165798/working/Wallace.Initiative/training.data/background.selection.mask.asc.gz'))#append the domain (contenent) info
	out = pos; write.csv(out,gzfile('/homes/31/jc165798/working/Wallace.Initiative/summaries/mask.pos.csv.gz'),row.names=FALSE)
}
out$current.clipped = extract.data(cbind(pos$lon,pos$lat),cur.asc) #append the current known info

###process all future scenarios
projs = list.files('output/',pattern='\\.asc.gz') #get a list of all asc.gz files
if(length(grep('current_0.1',projs))>0) { projs = projs[-grep('current_0.1',projs)] } ; projs = gsub('\\.asc.gz','',projs) 
#cycle through the projections and extract the information
for (projx in projs) {
	cat(projx,'\n')
	tasc = read.asc.gz(paste('output/',projx,'.asc.gz',sep=''))#read in the data
	#track the data
	out[projx] = extract.data(cbind(pos$lon,pos$lat),tasc)
}

#for simplicity, append the threshold as a column
out$threshold = threshold
#write out the projection data
write.csv(out,gzfile(paste(out.dir,spp,'.predictions.raw.csv.gz',sep='')),row.names=FALSE)

#convert to binary by applying threshold & write out data
tout = as.matrix(out[6:length(out)])
tout[which(tout<threshold)] = 0; tout[which(tout>0)] = 1
out[6:length(out)] = tout
#write out the projection data
write.csv(out,gzfile(paste(out.dir,spp,'.predictions.binary.csv.gz',sep='')),row.names=FALSE)
 