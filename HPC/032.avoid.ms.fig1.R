wd = '~/working/WallaceInitiative_1.0/'; setwd(wd) 
tdata = read.csv('avoid_temperature_change.csv',as.is=TRUE) #read in the plot data
ESs = c('A1B_2016_5_L','A1B_2016_4_L','A1B_2016_2_H','A1B_2030_5_L','A1B_2030_2_H','A1B') #define the emission scenarios

cols = c('#0000FF','#0000FF','#0000FF','#2E8B57','#2E8B57','#FF0000') #define the line colors
cols.fill = paste(cols,'30',sep='') #define the polygon fill colors

pdf("avoid.ms.fig1.pdf", width = 7, height = 7, pointsize=14 ); 
	par(mar=c(5,4,1,8),xpd=TRUE,cex=1) #define the plot parameterspar()

#png(filename = "avoid.ms.fig1.png", width = 7, height = 7, units = "cm", pointsize = 6, bg = "white", res = 300)
	#par(mar=c(5,4,1,6),xpd=TRUE) #define the plot parameters
	
	
	plot(1,1,ylim=c(0,5.5),xlim=c(1990,2100),axes=FALSE,type='n',xlab='Year',ylab='Temperature change (celcius)') #create the basic plot
	axis(2,at=seq(0,5.5,0.5),labels=c(0,NA,1,NA,2,NA,3,NA,4,NA,5,NA)); axis(1,at=seq(1990,2100,10),labels=c(NA,2000,NA,2020,NA,2040,NA,2060,NA,2080,NA,2100)) #add the axes
	lefts = seq(2105,2140,length=6) #define the mid years of the left side data

	for (ii in 1:length(ESs)) {
		ES = ESs[ii]
		lines(tdata$year,tdata[,paste(ES,'_50',sep='')],col=cols[ii],lwd=2)
		tp = lefts[ii]
		polygon(c(tp-2,tp+2,tp+2,tp-2),c(rep(tdata[nrow(tdata),paste(ES,'_10',sep='')],2),rep(tdata[nrow(tdata),paste(ES,'_90',sep='')],2)),col=cols.fill[ii],border=NA)
		lines(c(tp-2,tp+2),rep(tdata[nrow(tdata),paste(ES,'_50',sep='')],2),lwd=3,col=cols[ii])
		text(tp,0.1,gsub('_','-',ES),srt=90,adj=c(0,0.5))
	}

dev.off()

