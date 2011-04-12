#drafted by Jeremy VanDerWal ( jjvanderwal@gmail.com ... www.jjvanderwal.com )
#GNU General Public License .. feel free to use / distribute ... no warranties

################################################################################
################################################################################
#define the directories
work.dir = '/home/uqvdwj/WallaceInitiative/ms/avoid.ms/'; dir.create(work.dir,recursive=TRUE); setwd(work.dir)
data.dir = '/home/uqvdwj/WallaceInitiative/summaries/area/taxa/'

###################################################################################################
#define some common functions

summarize.ES.GCM = function(tdata){
	#get the mean and sd of the data
	cois = grep('prop',names(tdata))#coliumns of interest
	out.mean = aggregate(tdata[cois],list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),mean);names(out.mean)[4:6] = paste(names(out.mean)[4:6],'.mean',sep='')
	out.sd = aggregate(tdata[cois],list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),sd);names(out.sd)[4:6] = paste(names(out.sd)[4:6],'.sd',sep='')
	return(merge(out.mean,out.sd,all=TRUE))
}

summarize.status.counts = function(tdata) {
	cois = grep('prop',names(tdata))#coliumns of interest
	ex = function(x) { return(length(x[x<0.01])) }
	out.ex = aggregate(tdata[cois],list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),ex)
	names(out.ex)[4:6] = paste(gsub('prop.','',names(out.ex)[4:6]),'.ex',sep='')

	en = function(x) { return(length(x[x<0.3])) }
	out.en = aggregate(tdata[cois],list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),en)
	names(out.en)[4:6] = paste(gsub('prop.','',names(out.en)[4:6]),'.en',sep='')

	cr = function(x) { return(length(x[x<0.1])) }
	out.cr = aggregate(tdata[cois],list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),cr)
	names(out.cr)[4:6] = paste(gsub('prop.','',names(out.cr)[4:6]),'.cr',sep='')

	vu = function(x) { return(length(x[x<0.5])) }
	out.vu = aggregate(tdata[cois],list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),vu)
	names(out.vu)[4:6] = paste(gsub('prop.','',names(out.vu)[4:6]),'.vu',sep='')

	out = merge(out.ex,out.cr,all=TRUE); out = merge(out,out.en,all=TRUE); out = merge(out,out.vu,all=TRUE)
	return(out)
}

summarize.ES.status = function(status,n) {
	cois = c(grep('ex',names(status)),grep('cr',names(status)),grep('en',names(status)),grep('vu',names(status))) #define the columns of interst
	status[,cois] = status[,cois] / n #make these proportions
	status.mean = aggregate(status[,cois],list(ES=status$ES,year=status$year),mean)
	status.sd = aggregate(status[,cois],list(ES=status$ES,year=status$year),sd)	
	out = NULL #setup the basic output
	for (tvar in names(status.mean[-c(1:2)])) {
		tt = strsplit(tvar,'\\.')
		out = rbind(out,data.frame(status.mean[1:2],dispersal=tt[[1]][2],iucn=tt[[1]][4],mean=status.mean[,tvar],sd=status.sd[,tvar]))
	}
	out = out[-which(out$ES=='current'),]#remove current
	return(out)
}


#create species loss plots for all spp and images
sum.plot = function(tfile,tdata,status){
	
	pdf(tfile,width=7.2,height=9.6,pointsize=8)
		par(oma=c(1,3,3,0))
		layout(matrix(1:12,nr=4,byrow=TRUE))
		par(mar=c(4,4,1,1))
		n = length(unique(tdata$spp)) #define the data
		cois = c(grep('ex',names(status)),grep('cr',names(status)),grep('en',names(status)),grep('vu',names(status)))
		status[,cois] = status[,cois]/n #make this proportionate
		cols = c('#FF0000','#2E8B57','#0000FF') #define the line colors
		cols.fill = paste(cols,'30',sep='') #define the polygon fill colors
		#create some summary stats for plotting
		status.mean = aggregate(status[,cois],list(ES=status$ES,year=status$year),mean)
		status.sd = aggregate(status[,cois],list(ES=status$ES,year=status$year),sd)
		status.min = status.max = status.mean
		status.min[,3:14] = status.mean[,3:14] - status.sd[,3:14]; for (ii in 3:14) status.min[which(status.min[ii]<0),ii] = 0
		status.max[,3:14] = status.mean[,3:14] + status.sd[,3:14]
		
		tplot = function(tdata,title,ylim,tlegend=FALSE) {
			#start plotting
			tout = aggregate(tdata[,4],list(ES=tdata$ES,year=tdata$year),mean); names(tout)[3] = 'mean'
			tout$sd = aggregate(tdata[,4],list(ES=tdata$ES,year=tdata$year),sd)[,3]
			tout$min = tout$mean-tout$sd; tout$min[which(tout$min<0)] = 0
			tout$max = tout$mean+tout$sd
			#create the basic plot
			plot(c(2020,2080),c(0,max(tout$max,na.rm=T)),ylab='proportion of species',xlab='year',type='n',axes=F,main=title,ylim=ylim)
			axis(2); axis(1,at=seq(2020,2080,10),labels=c(2020,NA,NA,2050,NA,NA,2080))
			#add the polygons
			pos = which(tout$ES=='SRES'); polygon(c(tout$year[pos],tout$year[pos[3:1]]),c(tout$min[pos],tout$max[pos[3:1]]),col=cols.fill[1],border=NA)
			pos = grep('30',tout$ES); tt = tout[pos,]; tt.min = aggregate(tt$min,by=list(year=tt$year),min); tt.max = aggregate(tt$max,by=list(year=tt$year),max)
			polygon(c(tt.min$year,tt.max$year[3:1]),c(tt.min$x,tt.max$x[3:1]),col=cols.fill[2],border=NA)
			pos = grep('16',tout$ES); tt = tout[pos,]; tt.min = aggregate(tt$min,by=list(year=tt$year),min); tt.max = aggregate(tt$max,by=list(year=tt$year),max)
			polygon(c(tt.min$year,tt.max$year[3:1]),c(tt.min$x,tt.max$x[3:1]),col=cols.fill[3],border=NA)
			#add the lines
			for (ES in ESs) {
				if (ES=='SRES') { ii=1 } else if (length(grep('30',ES))>0) { ii=2 } else { ii=3 }
				pos = which(tout$ES==ES); points(tout$year[pos],tout$mean[pos],type='o',pch=19,col=cols[ii])
			}
			if (tlegend) legend('topleft',legend=c('SRES','Avoid 2030','Avoid 2016'),col=cols,pch=19,bty='n')
		}
		
		tplot(status[,c('ES','GCM','year','cur.no.disp.ex')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('ex',names(status.max))]),na.rm=TRUE)),tlegend=TRUE)
		tplot(status[,c('ES','GCM','year','cur.real.disp.ex')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('ex',names(status.max))]),na.rm=TRUE)))
		tplot(status[,c('ES','GCM','year','cur.opt.disp.ex')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('ex',names(status.max))]),na.rm=TRUE)))
		
		tplot(status[,c('ES','GCM','year','cur.no.disp.cr')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('cr',names(status.max))]),na.rm=TRUE)))
		tplot(status[,c('ES','GCM','year','cur.real.disp.cr')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('cr',names(status.max))]),na.rm=TRUE)))
		tplot(status[,c('ES','GCM','year','cur.opt.disp.cr')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('cr',names(status.max))]),na.rm=TRUE)))
		
		tplot(status[,c('ES','GCM','year','cur.no.disp.en')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('en',names(status.max))]),na.rm=TRUE)))
		tplot(status[,c('ES','GCM','year','cur.real.disp.en')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('en',names(status.max))]),na.rm=TRUE)))
		tplot(status[,c('ES','GCM','year','cur.opt.disp.en')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('en',names(status.max))]),na.rm=TRUE)))
		
		tplot(status[,c('ES','GCM','year','cur.no.disp.vu')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('vu',names(status.max))]),na.rm=TRUE)))
		tplot(status[,c('ES','GCM','year','cur.real.disp.vu')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('vu',names(status.max))]),na.rm=TRUE)))
		tplot(status[,c('ES','GCM','year','cur.opt.disp.vu')],title=' ',ylim=c(0,max(as.vector(status.max[,grep('vu',names(status.max))]),na.rm=TRUE)))
		
		mtext(c('no dispersal','Realistic','Optimistic'),side=3,line=0,outer=TRUE,at=c(0.165,0.5,0.825),adj=0.5)
		mtext(c('< 50% current','< 30% current','< 10% current','< 1% current'),side=2,line=0.5,outer=TRUE,at=c(0.125,0.375,0.625,0.875),adj=0.5)
	dev.off()
}

####################################################################################################
#read in the data
amph = read.csv(paste(data.dir,'amphibia/predicted.area.csv.gz',sep=''),as.is=TRUE)
amph.ES.GCM = summarize.ES.GCM(amph); write.csv(amph.ES.GCM,'amphibia.ES.GCM.csv',row.names=FALSE)
amph.status = summarize.status.counts(amph); write.csv(amph.status,'amphibia.status.counts.csv',row.names=FALSE)
amph.ES.status = summarize.ES.status(amph.status, length(unique(amph$spp))); write.csv(amph.ES.status,'amphibia.ES.status.csv',row.names=FALSE)

aves = read.csv(paste(data.dir,'aves/predicted.area.csv.gz',sep=''),as.is=TRUE) 
aves.ES.GCM = summarize.ES.GCM(aves); write.csv(aves.ES.GCM,'aves.ES.GCM.csv',row.names=FALSE)
aves.status = summarize.status.counts(aves); write.csv(aves.status,'aves.status.counts.csv',row.names=FALSE)
aves.ES.status = summarize.ES.status(aves.status, length(unique(aves$spp))); write.csv(aves.ES.status,'aves.ES.status.csv',row.names=FALSE)

mamm = read.csv(paste(data.dir,'mammalia/predicted.area.csv.gz',sep=''),as.is=TRUE)
mamm.ES.GCM = summarize.ES.GCM(mamm); write.csv(mamm.ES.GCM,'mammalia.ES.GCM.csv',row.names=FALSE)
mamm.status = summarize.status.counts(mamm); write.csv(mamm.status,'mammalia.status.counts.csv',row.names=FALSE)
mamm.ES.status = summarize.ES.status(mamm.status, length(unique(mamm$spp))); write.csv(mamm.ES.status,'mammalia.ES.status.csv',row.names=FALSE)

rept = read.csv(paste(data.dir,'reptilia/predicted.area.csv.gz',sep=''),as.is=TRUE)
rept.ES.GCM = summarize.ES.GCM(rept); write.csv(rept.ES.GCM,'reptilia.ES.GCM.csv',row.names=FALSE)
rept.status = summarize.status.counts(rept); write.csv(rept.status,'reptilia.status.counts.csv',row.names=FALSE)
rept.ES.status = summarize.ES.status(rept.status, length(unique(rept))); write.csv(rept.ES.status,'reptilia.ES.status.csv',row.names=FALSE)

plant = read.csv(paste(data.dir,'plantae/predicted.area.csv.gz',sep=''),as.is=TRUE)
plant.ES.GCM = summarize.ES.GCM(plant); write.csv(plant.ES.GCM,'plantae.ES.GCM.csv',row.names=FALSE)
plant.status = summarize.status.counts(plant); write.csv(plant.status,'plantae.status.counts.csv',row.names=FALSE)
plant.ES.status = summarize.ES.status(plant.status, length(unique(plant$spp))); write.csv(plant.ES.status,'plantae.ES.status.csv',row.names=FALSE)

animal = rbind(amph, aves, mamm, rept)
animal.ES.GCM = summarize.ES.GCM(animal); write.csv(animal.ES.GCM,'animal.ES.GCM.csv',row.names=FALSE)
animal.status = summarize.status.counts(animal); write.csv(animal.status,'animal.status.counts.csv',row.names=FALSE)
animal.ES.status = summarize.ES.status(animal.status, length(unique(animal$spp))); write.csv(animal.ES.status,'animal.ES.status.csv',row.names=FALSE)


#define some variables
years=c(2020,2050,2080)
GCMs=unique(amph$GCM); GCMs = GCMs[-which(GCMs=='current')]
ESs=unique(amph$ES); ESs = ESs[-which(ESs=='current')]

#create the summary plots
sum.plot('amphibia.summary.pdf',amph,amph.status)
sum.plot('aves.summary.pdf',aves,aves.status)
sum.plot('mammalia.summary.pdf',mamm,mamm.status)
sum.plot('reptilia.summary.pdf',rept,rept.status)
sum.plot('plantae.summary.pdf',plant,plant.status)
sum.plot('animal.summary.pdf',animal,animal.status)

################################################################################
################################################################################
#need to extract information on initial sizes of species (n occur & area)

###first get the number of occurrences per species
wd = '/home/uqvdwj/WallaceInitiative/training.data/occur/'; setwd(wd) #define and set the initial working directory
occur.files = list.files(,pattern='occur.csv',recursive=TRUE,full.names=TRUE) #get a list of all occurrence files
out = NULL #default output information
for (occur.file in occur.files) {cat(occur.file,'\n') #cycle through each of the files
	tdata = read.csv(occur.file,as.is=TRUE);tdata = na.omit(unique(tdata)) #read in the data, keeping ony data with information and is unique
	tt = strsplit(occur.file,'/'); taxa = tt[[1]][2]; fam = tt[[1]][3] #define the family and taxa
	tt = aggregate(tdata$lon,list(tdata$specie_id),length) #get the number of unique occurrences
	out = rbind(out,data.frame(taxa=taxa,family=fam,species=tt[,1],n_unique_occur_at_10minute=tt[,2])) #append the output
}
###now get out the current species area
wd = '/home/uqvdwj/WallaceInitiative/summaries/area/taxa/'; setwd(wd) #define and set the new working directory
tfiles = list.files(,pattern='predicted.area.csv.gz',recursive=TRUE,full.names=TRUE) #get a list of all area files
out2 = NULL #setup the default output
for (tfile in tfiles) {cat(tfile,'\n') #cycle through each of the files
	tdata = read.csv(tfile,as.is=TRUE);tdata = tdata[which(tdata$ES=='current'),c('spp','area.no.disp')] #read in the data, keeping ony data on current area
	out2 = rbind(out2,tdata) #append the output
}
#now bring both datasets together
output = merge(out,out2,by.x='species',by.y='spp')
names(output)[5] = 'area_km2'
###now create some summaries
wd = '/home/uqvdwj/WallaceInitiative/ms/avoid.ms/'; setwd(wd) #define and set the new working directory
write.csv(output,'n_occur.and.area.csv',row.names=FALSE) #write out the summary data

