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
library(raster)

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
#write out the data
write.csv(out,paste(out.dir,'summary.accuracy.contributions.csv',sep=''),row.names=F)

###summarize thresholds and accuracy
out = optim.thresh(pa$obs,pa$pred); for (ii in names(out)) out[[ii]] = mean(out[[ii]])
out = data.frame(type=names(out),accuracy(pa$obs,pa$pred,threshold=as.vector(unlist(out))))
threshold = out$threshold[out$type=='min.ROC.plot.distance']
#write out the data
write.csv(out,paste(out.dir,'summary.thresholds.csv',sep=''),row.names=F)

### create summary images & outputs
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

##set some common plotting information
legend.local = cbind(c(-130,-135,-135,-130),c(-40,-40,0,0)) 
cols = c('gray', colorRampPalette(c('yellow','red'))(100))

##read in the current distribution
cur.asc = read.asc.gz('output/current_0.5degrees.asc.gz') #read in the data
cur.asc[which(is.finite(cur.asc) & cur.asc<threshold)] = 0 #set everything below the threshold to 0
#plot the current unclipped distribution
png(paste(out.dir,'current_unclipped.png',sep=''),width=dim(cur.asc)[1]*2,height=dim(cur.asc)[2]*2)
	par(mar=c(0,0,0,0))	
	image(cur.asc,zlim=c(0,1),col = cols)
	polygon(hull.buff$lon,hull.buff$lat)
	points(occur$lon,occur$lat,pch='+')
	legend.gradient(legend.local,cols,title='suitability') 
dev.off()
#now clip the base asc to a 500 km buffer of the convex hull
pos = as.data.frame(which(is.finite(cur.asc) & cur.asc>=threshold, arr.ind=T)) #define the position of the potential distribution
pos$lat = getXYcoords(cur.asc)$y[pos$col]; pos$lon = getXYcoords(cur.asc)$x[pos$row] #convert to lat & long
pos$in.hull.buff = pnt.in.poly(cbind(pos$lon,pos$lat),cbind(hull.buff$lon,hull.buff$lat))$pip #check if lat/longs are with polygon defined by hull.buff
cur.asc[cbind(pos$row[which(pos$in.hull.buff==0)],pos$col[which(pos$in.hull.buff==0)])] = 0 #set all values outside hull to 0
#plot the new distribution
png(paste(out.dir,'current.png',sep=''),width=dim(cur.asc)[1]*2,height=dim(cur.asc)[2]*2)
	par(mar=c(0,0,0,0))	
	image(cur.asc,zlim=c(0,1),col = cols)
	polygon(hull.buff$lon,hull.buff$lat)
	legend.gradient(legend.local,cols,title='suitability')
dev.off()
#create a mask for 'no migration' scenario
no.migrate.mask = cur.asc; no.migrate.mask[which(is.finite(cur.asc) & cur.asc>0)] = 1 #this is an mask to apply to future scenarios
write.asc.gz(no.migrate.mask,paste(out.dir,'no.migrate.mask.asc',sep='')) #write out the mask
pos = as.data.frame(which(is.finite(no.migrate.mask),arr.ind=TRUE)) #get the positions
pos$lat = getXYcoords(no.migrate.mask)$y[pos$col]; pos$lon = getXYcoords(no.migrate.mask)$x[pos$row] #convert to lat & long
out = pos

###process all future scenarios
projs = list.files('output/',pattern='\\.asc.gz') #get a list of all asc.gz files
if(length(grep('current_0.1',projs))>0) { projs = projs[-grep('current_0.1',projs)] } ; projs = gsub('\\.asc.gz','',projs) 
#cycle through the projections and extract the information
for (projx in projs) {
	cat(projx,'\n')
	tasc = read.asc.gz(paste('output/',projx,'.asc.gz',sep=''))#read in the data
	tasc = tasc * no.migrate.mask #apply the no migration mask
	#track the data
	out[projx] = extract.data(cbind(pos$lon,pos$lat),tasc)
	tasc[which(is.finite(tasc) & tasc<threshold)] = 0 #remove anything below the threshold
	#write.asc.gz(tasc,paste(out.dir,projx,'.asc',sep='')) #write out the gis data
	#plot the image
	png(paste(out.dir,projx,'.png',sep=''),width=dim(cur.asc)[1]*2,height=dim(cur.asc)[2]*2)
		par(mar=c(0,0,0,0))	
		image(tasc,zlim=c(0,1),col = c('gray',heat.colors(100)[100:1]))
		legend.gradient(legend.local,cols,title='suitability')
	dev.off()
}

###summarize changes
#get sum & sd of 2020, 2050 & 2080
out.binary = as.matrix(out[,5:length(out)])
out$mean_2020 = rowMeans(out.binary[,grep('_2020_',colnames(out.binary))],na.rm=T)
out$mean_2050 = rowMeans(out.binary[,grep('_2050_',colnames(out.binary))],na.rm=T)
out$mean_2080 = rowMeans(out.binary[,grep('_2080_',colnames(out.binary))],na.rm=T)
out$sd_2020 = apply(out.binary[,grep('_2020_',colnames(out.binary))],1,function(x) { return(sd(x,na.rm=TRUE)) })
out$sd_2050 = apply(out.binary[,grep('_2050_',colnames(out.binary))],1,function(x) { return(sd(x,na.rm=TRUE)) })
out$sd_2080 = apply(out.binary[,grep('_2080_',colnames(out.binary))],1,function(x) { return(sd(x,na.rm=TRUE)) })
out$worst_2020 = out$mean_2020 - (1.96 * out$sd_2020); out$best_2020 = out$mean_2020 + (1.96 * out$sd_2020)
out$worst_2050 = out$mean_2050 - (1.96 * out$sd_2050); out$best_2050 = out$mean_2050 + (1.96 * out$sd_2050)
out$worst_2080 = out$mean_2080 - (1.96 * out$sd_2080); out$best_2080 = out$mean_2050 + (1.96 * out$sd_2080)
#create the plots
image.vars = expand.grid(x=c('worst','mean','best'),y=c(2020,2050,2080)) #define the variable we want plotted
image.vars = paste(image.vars$x,'_',image.vars$y,sep='')#define the variable we want plotted
for (image.var in image.vars) { 
	values = out[,image.var]; values[which(values<threshold)] = 0 #set anything less than threshold to 0
	png(paste(out.dir,image.var,'.png',sep=''),width=dim(no.migrate.mask)[1]*2,height=dim(no.migrate.mask)[2]*2)
		par(mar=c(0,0,0,0))	
		tasc = no.migrate.mask; tasc[cbind(out$row,out$col)] = values
		image(tasc,zlim=c(0,1),col = cols)
		legend.gradient(legend.local,cols,title='suitability')
	dev.off()
}
#for simplicity, append the threshold as a column
out$threshold = threshold
#write out the projection data and no.migrate.mask
write.csv(out,paste(out.dir,'no.migrate.data.csv',sep=''),row.names=FALSE)
