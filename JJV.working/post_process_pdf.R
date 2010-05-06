#this is to post process a single species...
#this includes:
#	- unzipping the tar file of the models
#	- creating a Rnw file for sweave to summarize the data (creating all images, etc.)
#	- run the Sweave and pdflatex to create the summary outputs
#	- re-tar everything and put it back...

################################################################################
#test species
spp = 13274112

################################################################################
#load libraries & source
library(SDMTools)
library(raster)
source('/homes/31/jc165798/SCRIPTS/misc/R_scripts/PDFreports/Sweave.R')

################################################################################
#setup the constants

#define and set directories; extract the data to work with
data.dir = '/data/jc165798/models/'
base.work.dir = '/tmp/'; setwd(base.work.dir) #define and set the base working directory
file.copy(paste(data.dir,spp,'.tar.gz',sep=''),paste(base.work.dir,spp,'.tar.gz',sep=''),overwrite=T,recursive=T) #copy over the species data
system(paste('tar -xf ',spp,'.tar.gz',sep='')) #expand the species data
work.dir = paste('/tmp/',spp,'/',sep=''); setwd(work.dir) #move the working directory into the species directory
out.dir = paste(work.dir,'summaries/',sep=''); dir.create(out.dir) #defien the directory to put all summary information

#start writing out the Rnw file 
zz = file(paste(out.dir,spp,'.Rnw',sep=''),'w')
	cat('\\documentclass[a4paper]{article}','\n',sep='',file=zz)
	cat('\\title{',spp,' info}','\n',sep='',file=zz)
	cat('\\author{Jeremy VanDerWal}','\n',sep='',file=zz)
	cat('\\begin{document}','\n',sep='',file=zz)
	cat('\n',sep='',file=zz)
	cat('\\maketitle','\n',sep='',file=zz)
	cat('\n',sep='',file=zz)
	cat('this is a trial to make a pdf report for Wallace Initiative species','\n',sep='',file=zz)
	cat('\n',sep='',file=zz)
	cat('<<mainsetup,echo=false,results=hide>>=','\n',sep='',file=zz)
	cat('library(SDMTools)','\n',sep='',file=zz)
	cat('library(raster)','\n',sep='',file=zz)
	cat('library(sp)','\n',sep='',file=zz)
	cat('@\n','\n',sep='',file=zz)
	cat('<<>>=','\n',sep='',file=zz)
	cat('#do some work','\n',sep='',file=zz)
	cat('maxent.results = read.csv("',work.dir,'output/maxentResults.csv")','\n',sep='',file=zz)
	cat('print(maxent.results)','\n',sep='',file=zz)
	cat('@\n','\n',sep='',file=zz)
	cat('\\end{document}','\n',sep='',file=zz)
close(zz)

#move to the out.dir
setwd(out.dir)
Sweave(paste(spp,'.Rnw',sep=''))
system(paste('R CMD pdflatex ',spp,'.tex',sep=''))

file.copy(paste(spp,'.pdf',sep=''),paste('/homes/31/jc165798/',spp,'.pdf',sep=''),overwrite=T)

################################################################################
#work out the summarizing and visualization script prior to use in Rnw

work.dir = '/homes/31/jc165798/trial/13274112/'; setwd(work.dir)
out.dir = paste(work.dir,'summaries/',sep=''); dir.create(out.dir) #defien the directory to put all summary information

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
out = optim.thresh(pa$obs,pa$pred)
out = data.frame(type=names(out),accuracy(pa$obs,pa$pred,threshold=as.vector(unlist(out))))
#write out the data
write.csv(out,paste(out.dir,'summary.thresholds.csv',sep=''),row.names=F)

##read in the occur data
occur = read.csv('occur.csv')

#define the convex hull
hull = occur[chull(cbind(occur$lat,occur$lon)),2:3]
lons = lats = NULL
for (bear in seq(0,length=8,by=45)) {
	tt = destination(hull$lons,hull$lats,bearings = bear,distance = 500000)
	lons = c(lons,tt$lons2); lats = c(lats,tt$lats2)
}
hull.buff = chull(cbind(lats,lons))

