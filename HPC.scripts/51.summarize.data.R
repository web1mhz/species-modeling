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
	for (ii in unique(tdata$ES)) { tdata$year = gsub(paste(ii,'_',sep=''),'',tdata$year) } ; tdata$year[which(tdata$year=='current')] = 1990 ; tdata$year = as.numeric(tdata$year)
	for (ii in unique(tdata$ES)) { for (jj in unique(tdata$year)) { tdata$GCM = gsub(paste(ii,'_',jj,'_',sep=''),'',tdata$GCM) } } 
	tdata$scenario=NULL #set the scenario to null as it is no longer needed
	#get the current num.cells
	cur = tdata[which(tdata$ES=='current'),]; cur$ES=cur$GCM=cur$year=NULL; names(cur)[2] = 'current.num.cell' #remove excess columns and rename the num.cells
	tdata = merge(tdata,cur) #merge the data
	tdata$prop = tdata$num.cells/tdata$current.num.cell #calculate the proportion
	tdata$ex = ifelse(tdata$prop<=0.01,1,0) #get the high chance extinction
	tdata$cr = ifelse(tdata$prop<=0.1,1,0) #get the critically endangered
	tdata$en = ifelse(tdata$prop<=0.3,1,0) #get the endangered   &tdata$prop>0.1
	tdata$vu = ifelse(tdata$prop<=0.5,1,0) #get the vulnerable   &tdata$prop>0.3
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
summarize.status.counts = function(tdata) {
	tout = aggregate(tdata[,c('ex','cr','en','vu')],list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),sum)
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
amph = sum.data('amphibia.area.csv'); write.csv(amph,'amphibia.summary.csv',row.names=FALSE)
amph.ES.GCM = summarize.ES.GCM(amph); write.csv(amph.ES.GCM,'amphibia.ES.GCM.csv',row.names=FALSE)
amph.ES = summarize.ES(amph); write.csv(amph.ES,'amphibia.ES.csv',row.names=FALSE)
amph.status = summarize.status.counts(amph); write.csv(amph.status,'amphibia.status.counts.csv',row.names=FALSE)

aves = sum.data('aves.area.csv'); write.csv(aves,'aves.summary.csv',row.names=FALSE) 
aves.ES.GCM = summarize.ES.GCM(aves); write.csv(aves.ES.GCM,'aves.ES.GCM.csv',row.names=FALSE)
aves.ES = summarize.ES(aves); write.csv(aves.ES,'aves.ES.csv',row.names=FALSE)
aves.status = summarize.status.counts(aves); write.csv(aves.status,'aves.status.counts.csv',row.names=FALSE)

mamm = sum.data('mammalia.area.csv'); write.csv(mamm,'mammalia.summary.csv',row.names=FALSE)
mamm.ES.GCM = summarize.ES.GCM(mamm); write.csv(mamm.ES.GCM,'mammalia.ES.GCM.csv',row.names=FALSE)
mamm.ES = summarize.ES(mamm); write.csv(mamm.ES,'mammalia.ES.csv',row.names=FALSE)
mamm.status = summarize.status.counts(mamm); write.csv(mamm.status,'mammalia.status.counts.csv',row.names=FALSE)

rept = sum.data('reptilia.area.csv'); write.csv(rept,'reptilia.summary.csv',row.names=FALSE)
rept.ES.GCM = summarize.ES.GCM(rept); write.csv(rept.ES.GCM,'reptilia.ES.GCM.csv',row.names=FALSE)
rept.ES = summarize.ES(rept); write.csv(rept.ES,'reptilia.ES.csv',row.names=FALSE)
rept.status = summarize.status.counts(rept); write.csv(rept.status,'reptilia.status.counts.csv',row.names=FALSE)

#define some variables
years=c(2020,2050,2080)
GCMs=unique(amph$GCM); GCMs = GCMs[-which(GCMs=='current')]
ESs=unique(amph$ES); ESs = ESs[-which(ESs=='current')]

#create some plots
histplots(amph,'amphibia')
histplots(aves,'aves')
histplots(mamm,'mammalia')
histplots(rept,'reptilia')

library(Hmisc)

spp.loss = function(x,tfile,n) {
	pdf(paste(tfile,'.spp.loss.pdf',sep=''),width=15,height=8.5,pointsize=9)
		par(mfrow=c(4,8),mar=c(3,3,1,1),oma=c(0,3,3,0))
		#change counts to %
		x[,c('ex','cr','en','vu')] = x[,c('ex','cr','en','vu')]/n
		#start plotting ex
		tout = aggregate(x$ex,list(ES=x$ES,year=x$year),mean); names(tout)[3] = 'mean'
		tout$sd = aggregate(x$ex,list(ES=x$ES,year=x$year),sd)[,3]
		tout$min = tout$mean-tout$sd
		tout$max = tout$mean+tout$sd
		pos = which(tout$ES=='SRES'); plot(tout$year[pos],tout$mean[pos],type='o',lty=1,xlab='',ylab='prop spp loss',ylim=range(x$ex),col='red'); errbar(tout$year[pos],tout$mean[pos],tout$max[pos],tout$min[pos],add=TRUE)
		for (ii in 1:5) { if(ESs[ii]!='SRES') {
			pos = which(tout$ES==ESs[ii]); points(tout$year[pos],tout$mean[pos],type='o',lty=ii+1); errbar(tout$year[pos],tout$mean[pos],tout$max[pos],tout$min[pos],add=TRUE)
		} }
		legend('top',legend='mean & sd',bty='n')
		for(GCM in GCMs) {
			pos = which(x$ES=='SRES' & x$GCM==GCM); plot(x$year[pos],x$ex[pos],type='o',lty=1,xlab='',ylab='prop spp loss',ylim=range(x$ex),col='red')
			for (ii in 1:5) { if(ESs[ii]!='SRES') {
				pos = which(x$ES==ESs[ii] & x$GCM==GCM); points(x$year[pos],x$ex[pos],type='o',lty=ii+1)
			} }
			legend('top',legend=GCM,bty='n')
		}

		#start plotting cr
		tout = aggregate(x$cr,list(ES=x$ES,year=x$year),mean); names(tout)[3] = 'mean'
		tout$sd = aggregate(x$cr,list(ES=x$ES,year=x$year),sd)[,3]
		tout$min = tout$mean-tout$sd
		tout$max = tout$mean+tout$sd
		pos = which(tout$ES=='SRES'); plot(tout$year[pos],tout$mean[pos],type='o',lty=1,xlab='',ylab='prop spp loss',ylim=range(x$cr),col='red'); errbar(tout$year[pos],tout$mean[pos],tout$max[pos],tout$min[pos],add=TRUE)
		for (ii in 1:5) { if(ESs[ii]!='SRES') {
			pos = which(tout$ES==ESs[ii]); points(tout$year[pos],tout$mean[pos],type='o',lty=ii+1); errbar(tout$year[pos],tout$mean[pos],tout$max[pos],tout$min[pos],add=TRUE)
		} }
		legend('top',legend='mean & sd',bty='n')
		for(GCM in GCMs) {
			pos = which(x$ES=='SRES' & x$GCM==GCM); plot(x$year[pos],x$cr[pos],type='o',lty=1,xlab='',ylab='prop spp loss',ylim=range(x$cr),col='red')
			for (ii in 1:5) { if(ESs[ii]!='SRES') {
				pos = which(x$ES==ESs[ii] & x$GCM==GCM); points(x$year[pos],x$cr[pos],type='o',lty=ii+1)
			} }
			legend('top',legend=GCM,bty='n')
		}
		
		#start plotting en
		tout = aggregate(x$en,list(ES=x$ES,year=x$year),mean); names(tout)[3] = 'mean'
		tout$sd = aggregate(x$en,list(ES=x$ES,year=x$year),sd)[,3]
		tout$min = tout$mean-tout$sd
		tout$max = tout$mean+tout$sd
		pos = which(tout$ES=='SRES'); plot(tout$year[pos],tout$mean[pos],type='o',lty=1,xlab='',ylab='prop spp loss',ylim=range(x$en),col='red'); errbar(tout$year[pos],tout$mean[pos],tout$max[pos],tout$min[pos],add=TRUE)
		for (ii in 1:5) { if(ESs[ii]!='SRES') {
			pos = which(tout$ES==ESs[ii]); points(tout$year[pos],tout$mean[pos],type='o',lty=ii+1); errbar(tout$year[pos],tout$mean[pos],tout$max[pos],tout$min[pos],add=TRUE)
		} }
		legend('top',legend='mean & sd',bty='n')
		for(GCM in GCMs) {
			pos = which(x$ES=='SRES' & x$GCM==GCM); plot(x$year[pos],x$en[pos],type='o',lty=1,xlab='',ylab='prop spp loss',ylim=range(x$en),col='red')
			for (ii in 1:5) { if(ESs[ii]!='SRES') {
				pos = which(x$ES==ESs[ii] & x$GCM==GCM); points(x$year[pos],x$en[pos],type='o',lty=ii+1)
			} }
			legend('top',legend=GCM,bty='n')
		}
		
		#start plotting vu
		tout = aggregate(x$vu,list(ES=x$ES,year=x$year),mean); names(tout)[3] = 'mean'
		tout$sd = aggregate(x$vu,list(ES=x$ES,year=x$year),sd)[,3]
		tout$min = tout$mean-tout$sd
		tout$max = tout$mean+tout$sd
		pos = which(tout$ES=='SRES'); plot(tout$year[pos],tout$mean[pos],type='o',lty=1,xlab='',ylab='prop spp loss',ylim=range(x$vu),col='red'); errbar(tout$year[pos],tout$mean[pos],tout$max[pos],tout$min[pos],add=TRUE)
		for (ii in 1:5) { if(ESs[ii]!='SRES') {
			pos = which(tout$ES==ESs[ii]); points(tout$year[pos],tout$mean[pos],type='o',lty=ii+1); errbar(tout$year[pos],tout$mean[pos],tout$max[pos],tout$min[pos],add=TRUE)
		} }
		legend('top',legend='mean & sd',bty='n')
		for(GCM in GCMs) {
			pos = which(x$ES=='SRES' & x$GCM==GCM); plot(x$year[pos],x$vu[pos],type='o',lty=1,xlab='',ylab='prop spp loss',ylim=range(x$vu),col='red')
			for (ii in 1:5) { if(ESs[ii]!='SRES') {
				pos = which(x$ES==ESs[ii] & x$GCM==GCM); points(x$year[pos],x$vu[pos],type='o',lty=ii+1)
			} }
			legend('top',legend=GCM,bty='n')
		}
				
	dev.off()
}	

spp.loss(amph.status,'amphibia',length(unique(amph$spp)))
spp.loss(aves.status,'aves',length(unique(aves$spp)))
spp.loss(mamm.status,'mammalia',length(unique(mamm$spp)))
spp.loss(rept.status,'reptilia',length(unique(rept$spp)))
all.data = rbind(amph,aves,mamm,rept)
all.status = summarize.status.counts(all.data) 
spp.loss(all.status,'all',length(c(unique(amph$spp),unique(aves$spp),unique(mamm$spp),unique(rept$spp))))


hist(all.data$num.cells[which(all.data$ES=='current')],breaks=seq(0,22500,100))
hist(all.data$num.cells[which(all.data$ES=='current' & all.data$num.cells<=100)],breaks=seq(0,100,10))
dev.off()


