#load the libraries
library(SDMTools)

#define some directories
work.dir = '/data/jc165798/WallaceInitiative/richness/data/'; setwd(work.dir)
out.dir = '/data/jc165798/WallaceInitiative/richness/images/'; dir.create(out.dir)
train.dir = '/data/jc165798/WallaceInitiative/training.data/' #define the directory where generic training data is

#read in the mask and the positions
pos = read.csv(paste(train.dir,'mask.pos.csv',sep=''),as.is=TRUE)
mask = read.asc.gz(paste(train.dir,'mask.asc.gz',sep=''))

#start working with the data
groups = list.files(,pattern='no.disp.sum.csv.gz'); groups = gsub('\\.no.disp.sum.csv.gz','',groups)

tname = NULL
#cycle through each of the groups
for (group in groups) {
	#start with the no dispersal & species richness
	tdata = as.matrix(read.csv(gzfile(paste(group,'.no.disp.sum.csv.gz',sep='')),as.is=TRUE))
	if (is.null(tname)) {
		tnames = colnames(tdata) #get the column names
		years = c(2020,2050,2080)
		ESs = gsub('A1B_','',tnames); ESs = ESs[-which(ESs=="current_0.5degrees")]
		for (ii in years) { ESs = gsub(ii,'',ESs) } ; ESs = unique(ESs)
		for (ii in 1:length(ESs)) { ESs[ii] = strsplit(ESs[ii],'__')[[1]][1] } ; ESs = unique(ESs)
		
	}
	current = mask; current[cbind(pos$row,pos$col)] = tdata[,"current_0.5degrees"] #Create as ascii file for present
	plot.data(current,paste(out.dir,group,'.current.png',sep=''),header='Richness',prop=FALSE,invert=FALSE)
	for (year in years) { 
		for (ES in ESs) {
			tmean = mask; tmean[cbind(pos$row,pos$col)] = rowMeans(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]])
			tmin = mask; tmin[cbind(pos$row,pos$col)] = apply(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,min)
			tmax = mask; tmax[cbind(pos$row,pos$col)] = apply(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,max)
			t.luke = tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]]; t.luke[,] = t.luke[,]/tdata[,"current_0.5degrees"]; t.luke[which(t.luke<0.75)] = 0; t.luke[which(t.luke>0)] = 1
			t.luke2 = mask; t.luke2[cbind(pos$row,pos$col)] = rowSums(t.luke)
			#proportion change?
			tmean = tmean / current; tmin = tmin / current; tmax = tmax / current
			plot.data(tmean,paste(out.dir,group,'.',ES,'.',year,'.mean.png',sep=''),header=paste(year,'proportions'),prop=TRUE,invert=FALSE)
			plot.data(tmax,paste(out.dir,group,'.',ES,'.',year,'.max.png',sep=''),header=paste(year,'proportions'),prop=TRUE,invert=FALSE)
			plot.data(tmin,paste(out.dir,group,'.',ES,'.',year,'.min.png',sep=''),header=paste(year,'proportions'),prop=TRUE,invert=FALSE)
			plot.data(t.luke2,paste(out.dir,group,'.',ES,'.',year,'.luke.png',sep=''),header=paste(year,'concordance'),prop=FALSE,invert=FALSE)
		}
	}
	#work with no.disp loss
	for (year in years) { 
		for (ES in ESs) {
			tmean = mask; tmean[cbind(pos$row,pos$col)] = rowMeans(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]])
			tmin = mask; tmin[cbind(pos$row,pos$col)] = apply(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,min)
			tmax = mask; tmax[cbind(pos$row,pos$col)] = apply(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,max)
			#****
			#proportion change?
		}
	}	
	
}

tfile=paste(out.dir,group,'.current.png',sep='')
tasc = current
header = 'current richness'
prop=FALSE
invert=FALSE

plot.data = function(tasc,tfile,header,prop=FALSE,invert=FALSE) {
	cols = c('gray',colorRampPalette(c('red4','tan','yellow','lightblue','forestgreen','darkolivegreen'))(100))
	if (invert) cols = cols[length(cols):1]
	legend.local = cbind(c(-130,-135,-135,-130),c(-40,-40,0,0)) 
	if (prop) { zlim = range(c(0,1,as.vector(tasc)),na.rm=TRUE) } else { zlim = range(tasc,na.rm=TRUE) }
	png(tfile,width=dim(tasc)[1]/100*2,height=dim(tasc)[2]/100*2,res=300,pointsize=6,units='cm')
		par(mar=c(.1,.1,.1,.1))
		#image(mask,ann=FALSE,axes=FALSE,col='gray')
		tasc[which(is.finite(mask) & !is.finite(tasc))] = 0
		image(tasc,ann=FALSE,axes=FALSE,col=cols)
		legend.gradient(legend.local,cols,limits=zlim,title=header)
	dev.off()

}


