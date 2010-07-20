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
# maxent="/data/jc165798/WallaceInitiative/maxent.jar"
# proj.dir="/data/jc165798/WallaceInitiative/projecting.data/"

################################################################################
#load libraries & source
library(SDMTools)

###########################################################################################
train.dir = '/data/jc165798/WallaceInitiative/training.data/' #define the directory where generic training data is
setwd(work.dir) #set the working directory

#run maxent
occur = read.csv('occur.csv')
if (nrow(occur) >= 40) { #run the maxent model once with full data and another cross validated
	system(paste('java -mx2000m -jar ',maxent,' outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv nowarnings replicates=5 noaskoverwrite novisible nooutputgrids autorun',sep=''))
	system('cp -af output/maxentResults.csv output/maxentResults.crossvalide.csv')
	system(paste('java -mx2000m -jar ',maxent,' outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv nowarnings noaskoverwrite responsecurves novisible writebackgroundpredictions nooutputgrids autorun',sep=''))
} else {
	system(paste('java -mx2000m -jar ',maxent,' outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv -N bio_5 -N bio_6 -N bio_16 -N bio_17 nowarnings replicates=5 noaskoverwrite novisible nooutputgrids autorun',sep=''))
	system('cp -af output/maxentResults.csv output/maxentResults.crossvalide.csv')
	system(paste('java -mx2000m -jar ',maxent,' outputdirectory=output samplesfile=occur.csv environmentallayers=bkgd.csv -N bio_5 -N bio_6 -N bio_16 -N bio_17 nowarnings noaskoverwrite responsecurves novisible writebackgroundpredictions nooutputgrids autorun',sep=''))
}

#do the projections
if (!file.exists(paste('output/',spp,'.lambdas',sep=''))){ quit('no') } #stop if maxent fails
proj.list = list.files(proj.dir)
for (projx in proj.list) { cat(projx,'\n')
	system(paste('java -cp ',maxent,' density.Project output/',spp,'.lambdas ',proj.dir,projx,' output/',projx,'.asc fadebyclamping nowriteclampgrid \n',sep=""))
}
system('gzip output/*.asc') #compress the ascii grid files

###########################################################################################
#start summarizing the outputs
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



