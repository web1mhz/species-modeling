#define the directories
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/summaries/avoid.ms/'; setwd(work.dir)

#define some common functions
sum.data = function(tdata) {
	tdata = read.csv(tdata,as.is=TRUE) #read in teh data 
	tdata$spp = as.numeric(tdata$spp)
	#append the data and restructure it
	tdata$scenario = gsub('A1B_','',tdata$scenario) #get rid of emmission scenario
	tdata$scenario[grep('current',tdata$scenario)] = 'current' #redefine the cuurent name
	tdata$year = tdata$GCM = tdata$ES = tdata$scenario #set new columns to tdata$scenario
	tdata$year = gsub('_cccma_cgcm31','',tdata$year)
	tdata$year = gsub('_csiro_mk30','',tdata$year)
	tdata$year = gsub('_ipsl_cm4','',tdata$year)
	tdata$year = gsub('_mpi_echam5','',tdata$year)
	tdata$year = gsub('_ncar_ccsm30','',tdata$year)
	tdata$year = gsub('_ukmo_hadcm3','',tdata$year)
	tdata$year = gsub('_ukmo_hadgem1','',tdata$year)
	tdata$ES = tdata$year; tdata$ES = gsub('_2020','',tdata$ES); tdata$ES = gsub('_2050','',tdata$ES); tdata$ES = gsub('_2080','',tdata$ES); 
	for (ii in unique(tdata$ES)) { tdata$year = gsub(paste(ii,'_',sep=''),'',tdata$year) } ; tdata$year[which(tdata$year=='current')] = 2000 ; tdata$year = as.numeric(tdata$year)
	for (ii in unique(tdata$ES)) { for (jj in unique(tdata$year)) { tdata$GCM = gsub(paste(ii,'_',jj,'_',sep=''),'',tdata$GCM) } } 

	#cycle through each of the species and get the proportion data
	tdata$prop = 0
	for (spp in unique(tdata$spp)){ cat(spp,'\n')
		current = tdata$num.cells[which(tdata$ES == 'current' & tdata$spp==spp)[1]] #get the current value for the spp
		rois = which(tdata$spp==spp) #get the rows of interst for the species
		tdata$prop[rois] = tdata$num.cells[rois]/current #get the proportions
	}
	return(tdata)
}

summarize.ES.GCM = function(tdata){
	#get the mean and sd of the data
	tout = aggregate(tdata$prop,list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),mean); names(tout)[4] = 'mean'
	tout$sd = aggregate(tdata$prop,list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),sd)[,4]
	tout$n = aggregate(tdata$prop,list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),length)[,4]
	return(tout)
}
summarize.ES = function(tdata){
	#get the mean and sd of the data
	tout = aggregate(tdata$prop,list(ES=tdata$ES,year=tdata$year),mean); names(tout)[3] = 'mean'
	tout$sd = aggregate(tdata$prop,list(ES=tdata$ES,year=tdata$year),sd)[,3]
	tout$n = aggregate(tdata$prop,list(ES=tdata$ES,year=tdata$year),length)[,3]
	return(tout)
}

#create some plots
histplots = function(x,tfile) {
	pdf(paste(tfile,'.hist.pdf',sep=''),width=11,height=8.5,pointsize=9)
		par(mfrow=c(3,6),mar=c(4,4,1,1),oma=c(0,3,3,0))
		##plot the average
		#get the y limits for this plot
		ylim = 0; for (year in years) { for (ES in ESs) { ylim = range(ylim,hist(x$prop[which(x$year==year & x$ES==ES)],breaks=seq(0,1,0.05),plot=FALSE)$counts) } }
		for (year in years) { for (ES in ESs) { 
			hist(x$prop[which(x$year==year & x$ES==ES)],breaks=seq(0,1,0.05),ylim=ylim,xlab='Proportion remaining',main='')
			legend('top',legend=ES,bty='n')
			mtext(paste(tfile,'-- All GCM average'),3,1.5,outer=TRUE)
			mtext(years[3:1],2,1.5,outer=TRUE,at=c(0.2,0.5,0.8),adj=0.5)
		} }
		##plot the individual GCMs
		#get the y limits for this plot
		for (GCM in GCMs) {
			ylim = 0; for (year in years) { for (ES in ESs) { ylim = range(ylim,hist(x$prop[which(x$GCM==GCM & x$year==year & x$ES==ES)],breaks=seq(0,1,0.05),plot=FALSE)$counts) } }
			for (year in years) { for (ES in ESs) { 
				hist(x$prop[which(x$GCM==GCM & x$year==year & x$ES==ES)],breaks=seq(0,1,0.05),ylim=ylim,xlab='Proportion remaining',main='')
				legend('top',legend=ES,bty='n')
				mtext(paste(tfile,'--', GCM),3,1.5,outer=TRUE)
				mtext(years[3:1],2,1.5,outer=TRUE,at=c(0.2,0.5,0.8),adj=0.5)
			} }
		}		
	dev.off()
}


#read in the data, extract summaries & write them out
if (file.exists('amphibia.summary.csv')) { amph=read.csv('amphibia.summary.csv',as.is=TRUE) } else { amph = sum.data('amphibia.area.csv'); write.csv(amph,'amphibia.summary.csv',row.names=FALSE) }
amph.ES.GCM = summarize.ES.GCM(amph); write.csv(amph.ES.GCM,'amphibia.ES.GCM.csv',row.names=FALSE)
amph.ES = summarize.ES(amph); write.csv(amph.ES,'amphibia.ES.csv',row.names=FALSE)

if (file.exists('aves.summary.csv')) { aves=read.csv('aves.summary.csv',as.is=TRUE) } else { aves = sum.data('aves.area.csv'); write.csv(aves,'aves.summary.csv',row.names=FALSE) }
aves.ES.GCM = summarize.ES.GCM(aves); write.csv(aves.ES.GCM,'aves.ES.GCM.csv',row.names=FALSE)
aves.ES = summarize.ES(aves); write.csv(aves.ES,'aves.ES.csv',row.names=FALSE)

if (file.exists('mammalia.summary.csv')) { mamm=read.csv('mammalia.summary.csv',as.is=TRUE) } else { mamm = sum.data('mammalia.area.csv'); write.csv(mamm,'mammalia.summary.csv',row.names=FALSE) }
mamm.ES.GCM = summarize.ES.GCM(mamm); write.csv(mamm.ES.GCM,'mammalia.ES.GCM.csv',row.names=FALSE)
mamm.ES = summarize.ES(mamm); write.csv(mamm.ES,'mammalia.ES.csv',row.names=FALSE)

if (file.exists('reptilia.summary.csv')) { rept=read.csv('reptilia.summary.csv',as.is=TRUE) } else { rept = sum.data('reptilia.area.csv'); write.csv(rept,'reptilia.summary.csv',row.names=FALSE) }
rept.ES.GCM = summarize.ES.GCM(rept); write.csv(rept.ES.GCM,'reptilia.ES.GCM.csv',row.names=FALSE)
rept.ES = summarize.ES(rept); write.csv(rept.ES,'reptilia.ES.csv',row.names=FALSE)

#define some variables
years=c(2020,2050,2080)
GCMs=unique(amph$GCM); GCMs = GCMs[-which(GCMs=='current')]
ESs=unique(amph$ES); ESs = ESs[-which(ESs=='current')]

#create some plots
histplots(amph,'amphibia')
histplots(aves,'aves')
histplots(mamm,'mammalia')
histplots(rept,'reptilia')
