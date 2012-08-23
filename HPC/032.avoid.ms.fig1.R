wd = '~/working/WallaceInitiative_1.0/'; setwd(wd) 
tdata = read.csv('avoid_temperature_change.csv',as.is=TRUE) #read in the plot data
ghgdata = read.csv('avoid_GHG_change.csv',as.is=TRUE) #read in the plot data
ESs = c('A1B_2016_5_L','A1B_2016_4_L','A1B_2016_2_H','A1B_2030_5_L','A1B_2030_2_H','A1B') #define the emission scenarios

cols = c('#9898FF','#0000FF','#00008B','#98FF98','#00FF00','#FF0000') #define the line colors
cols.fill = paste(cols,'50',sep='') #define the polygon fill colors
ltys = c(1,2,5,1,2,1)

pdf("avoid.ms.fig1.pdf", width = 14, height = 7, pointsize=14 ); 
	layout(matrix(c(1,1,1,1,2,2,2,2,2),nr=1))
	par(mar=c(5,5,1,2), cex=1) #define the plot parameterspar()

#png(filename = "avoid.ms.fig1.png", width = 7, height = 7, units = "cm", pointsize = 6, bg = "white", res = 300)
	#par(mar=c(5,4,1,6),xpd=TRUE) #define the plot parameters
	plot(1,1,ylim=c(0,21),xlim=c(1990,2100),axes=FALSE,type='n',xlab='Year',ylab=expression(paste("Emissions (GtCeq yr"^{-1},")"))) #create the basic plot
	axis(2,at=seq(0,21,1),labels=c(0,NA,NA,NA,4,NA,NA,NA,8,NA,NA,NA,12,NA,NA,NA,16,NA,NA,NA,20,NA)); axis(1,at=seq(1990,2100,10),labels=c(NA,2000,NA,2020,NA,2040,NA,2060,NA,2080,NA,2100)) #add the axes
	for (ii in 1:length(ESs)) {
		ES = ESs[ii]
		lines(ghgdata$Year,ghgdata[,ES],col=cols[ii],lwd=2,lty=ltys[ii])
		#text(tp,0.1,gsub('_','-',ES),srt=90,adj=c(0,0.5))
	}
	legend('topright',legend='a)',bty='n')
	legend('bottomleft',legend=ESs[6:1],lty=ltys[6:1],col=cols[6:1],bty='n',lwd=3)
	
	par(mar=c(5,5,1,8),xpd=TRUE)
	plot(1,1,ylim=c(0,5.5),xlim=c(1990,2100),axes=FALSE,type='n',xlab='Year',ylab=expression(paste("Global temperature change ("^{'o'},"C)"))) #create the basic plot
	axis(2,at=seq(0,5.5,0.5),labels=c(0,NA,1,NA,2,NA,3,NA,4,NA,5,NA)); axis(1,at=seq(1990,2100,10),labels=c(NA,2000,NA,2020,NA,2040,NA,2060,NA,2080,NA,2100)) #add the axes
	lefts = seq(2105,2140,length=6) #define the mid years of the left side data

	for (ii in 1:length(ESs)) {
		ES = ESs[ii]
		lines(tdata$year,tdata[,paste(ES,'_50',sep='')],col=cols[ii],lwd=2,lty=ltys[ii])
		tp = lefts[ii]
		polygon(c(tp-2,tp+2,tp+2,tp-2),c(rep(tdata[nrow(tdata),paste(ES,'_10',sep='')],2),rep(tdata[nrow(tdata),paste(ES,'_90',sep='')],2)),col=cols.fill[ii],border=NA)
		lines(c(tp-2,tp+2),rep(tdata[nrow(tdata),paste(ES,'_50',sep='')],2),lwd=3,col=cols[ii])
		#text(tp,0,gsub('_','-',ES),srt=90,adj=c(0,0.5))
	}
	#legend('topleft',legend=ESs,lty=ltys,col=cols,bty='n',lwd=2)
	legend('topright',legend='b)',bty='n')
dev.off()

###################################################################################################
#map preparation...

#load the libraries
library(SDMTools)

################################################################################
#define some directories
work.dir = '~/tmp/summaries/richness/'; setwd(work.dir)
out.dir = '~/tmp/summaries/ascii/'; dir.create(out.dir)
train.dir = '~/working/WallaceInitiative_1.0/training.data/' #define the directory where generic training data is

#read in the mask and the positions
pos = read.csv(paste(train.dir,'mask.pos.csv',sep=''),as.is=TRUE)
mask = read.asc.gz(paste(train.dir,'mask.asc.gz',sep=''))

#start working with the data
groups = list.files(paste(work.dir,'taxa',sep=''))

tname = NULL
#cycle through each of the groups
for (group in groups) {
	#start with the species richness
	tdata = as.matrix(read.csv(gzfile(paste('taxa/',group,'/real.sum.csv.gz',sep='')),as.is=TRUE))
	if (is.null(tname)) {
		tnames = colnames(tdata) #get the column names
		years = c(2020,2050,2080)
		ESs = gsub('A1B_','',tnames); ESs = ESs[-which(ESs=="current_0.5degrees")]
		for (ii in years) { ESs = gsub(ii,'',ESs) } ; ESs = unique(ESs)
		for (ii in 1:length(ESs)) { ESs[ii] = strsplit(ESs[ii],'__')[[1]][1] } ; ESs = unique(ESs)
	}
	current = mask; current[cbind(pos$row,pos$col)] = tdata[,"current_0.5degrees"] #Create as ascii file for present
	current.richness = tdata[,"current_0.5degrees"]
	write.asc.gz(current,paste(out.dir,group,'.current.richness',sep=''))
	
	year=2080
	for (ES in ESs) {
		tmean = mask; tmean[cbind(pos$row,pos$col)] = rowMeans(tdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]])
		write.asc.gz(tmean,paste(out.dir,group,'.',ES,'.',year,'.richness',sep=''))
	}
	
}



