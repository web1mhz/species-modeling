#load the libraries
library(SDMTools); library(maptools)

#setup soem functions for plotting

plot.richness = function(tasc,tfile,header) {
	cols = c('gray',colorRampPalette(c('red4','tan','yellow','lightblue','forestgreen','darkgreen'))(max(tasc,na.rm=T)))
	zlim = range(c(0,1,as.vector(tasc)),na.rm=TRUE)
	png(tfile,width=dim(tasc)[1]/100*2,height=dim(tasc)[2]/100*2,res=300,pointsize=6,units='cm')
		par(mar=c(.1,.1,.1,.1))
		image(mask,ann=FALSE,axes=FALSE,col='gray95')
		image(tasc,ann=FALSE,axes=FALSE,col=cols,add=TRUE)
		plot(shape,add=T,border="black",pbg="transparent",lwd=0.6) #add the subregions
		legend.gradient(legend.local,cols,limits=zlim,title=header)
	dev.off()
}
plot.proportions = function(tasc,tfile,header) {
	cols = colorRampPalette(c('red4','tan','yellow','lightblue','forestgreen','darkgreen'))(100)
	zlim = range(c(0,1,as.vector(tasc)),na.rm=TRUE)
	png(tfile,width=dim(tasc)[1]/100*2,height=dim(tasc)[2]/100*2,res=300,pointsize=6,units='cm')
		par(mar=c(.1,.1,.1,.1))
		image(mask,ann=FALSE,axes=FALSE,col='gray95')
		image(tasc,ann=FALSE,axes=FALSE,col=cols,add=TRUE)
		plot(shape,add=T,border="black",pbg="transparent",lwd=0.6) #add the subregions
		legend.gradient(legend.local,cols,limits=round(zlim,2),title=header)
	dev.off()
}
plot.proportions.loss = function(tasc,tfile,header) {
	cols = colorRampPalette(c('red4','tan','yellow','lightblue','forestgreen','darkgreen'))(100)[100:1]
	zlim = range(c(0,1,as.vector(tasc)),na.rm=TRUE)
	png(tfile,width=dim(tasc)[1]/100*2,height=dim(tasc)[2]/100*2,res=300,pointsize=6,units='cm')
		par(mar=c(.1,.1,.1,.1))
		image(mask,ann=FALSE,axes=FALSE,col='gray95')
		image(tasc,ann=FALSE,axes=FALSE,col=cols,add=TRUE)
		plot(shape,add=T,border="black",pbg="transparent",lwd=0.6) #add the subregions
		legend.gradient(legend.local,cols,limits=round(zlim,2),title=header)
	dev.off()
}
plot.certainty = function(tasc,tfile,header) {
	cols = c('gray',colorRampPalette(c('red4','tan','yellow','lightblue','forestgreen','darkgreen'))(7))
	zlim = c(0,7)
	png(tfile,width=dim(tasc)[1]/100*2,height=dim(tasc)[2]/100*2,res=300,pointsize=6,units='cm')
		par(mar=c(.1,.1,.1,.1))
		image(mask,ann=FALSE,axes=FALSE,col='gray95')
		image(tasc,ann=FALSE,axes=FALSE,col=cols,add=TRUE)
		plot(shape,add=T,border="black",pbg="transparent",lwd=0.6) #add the subregions
		legend.gradient(legend.local,cols,limits=zlim,title=header)
	dev.off()
}

legend.gradient = function (pnts, cols = heat.colors(100), limits = c(0, 1), title = "Legend", ...)
{
    pnts = try(as.matrix(pnts), silent = T)
    if (!is.matrix(pnts))
        stop("you must have a 4x2 matrix")
    if (dim(pnts)[1] != 4 || dim(pnts)[2] != 2)
        stop("Matrix must have dimensions of 4 rows and 2 columms")
    if (length(cols) < 2)
        stop("You must have 2 or more colors")
    yvals = seq(min(pnts[, 2]), max(pnts[, 2]), length=length(cols)+1)
    for (i in 1:length(cols)) {
        polygon(x = pnts[, 1], y = c(yvals[i], yvals[i], yvals[i + 1], yvals[i + 1]), col = cols[i], border = F)
    }
    text(max(pnts[, 1]), min(pnts[, 2]), labels = limits[1], pos = 4, ...)
    text(max(pnts[, 1]), max(pnts[, 2]), labels = limits[2], pos = 4, ...)
    text(min(pnts[, 1]), max(pnts[, 2]), labels = title, adj = c(0, -1), ...)
}


################################################################################
#define some directories
work.dir = '/data/jc165798/WallaceInitiative/richness/data/'; setwd(work.dir)
out.dir = '/data/jc165798/WallaceInitiative/richness/images/'; dir.create(out.dir)
train.dir = '/data/jc165798/WallaceInitiative/training.data/' #define the directory where generic training data is

#read in the mask and the positions
pos = read.csv(paste(train.dir,'mask.pos.csv',sep=''),as.is=TRUE)
mask = read.asc.gz(paste(train.dir,'mask.asc.gz',sep=''))

#plot options
legend.local = cbind(c(-130,-135,-135,-130),c(-40,-40,0,0)) 
shape = readShapePoly(paste(train.dir,'world/continent.shp',sep=''))

#start working with the data
groups = list.files(,pattern='no.disp.sum.csv.gz'); groups = gsub('\\.no.disp.sum.csv.gz','',groups)

tname = NULL
#cycle through each of the groups
for (group in groups) {
	#define functions
	richness.calc = function(xdata,disp) {
		#cycle through each ES & year
		for (year in years) { 
			for (ES in ESs) {
				tmean = mask; tmean[cbind(pos$row,pos$col)] = rowMeans(xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]])
				tmin = mask; tmin[cbind(pos$row,pos$col)] = apply(xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,min)
				tmax = mask; tmax[cbind(pos$row,pos$col)] = apply(xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,max)
				tt = xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]]; tt[which(tt<0.75)] = 0; tt[which(tt>0)] = 1
				refuge.certainty = mask; refuge.certainty[cbind(pos$row,pos$col)] = rowSums(tt) #refugica certainty
				tt = xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]]; tt[,] = 1-tt[,]; tt[which(tt<0.75)] = 0; tt[which(tt>0)] = 1
				AOC.certainty = mask; AOC.certainty[cbind(pos$row,pos$col)] = rowSums(tt) #AOC is area of concern
				#do the plots
				plot.proportions(tmean,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.mean.png',sep=''),header=paste(year,'proportions'))
				plot.proportions(tmax,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.max.png',sep=''),header=paste(year,'proportions'))
				plot.proportions(tmin,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.min.png',sep=''),header=paste(year,'proportions'))
				plot.certainty(refuge.certainty,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.refuge.certainty.png',sep=''),header=paste(year,'Certainty'))
				plot.certainty(AOC.certainty,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.AreaOfConcern.certainty.png',sep=''),header=paste(year,'Certainty'))
			}
		}
	}
	loss.calc = function(xdata,disp){
		for (year in years) { 
			for (ES in ESs) {
				tmean = mask; tmean[cbind(pos$row,pos$col)] = rowMeans(xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]])
				tmin = mask; tmin[cbind(pos$row,pos$col)] = apply(xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,min)
				tmax = mask; tmax[cbind(pos$row,pos$col)] = apply(xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,max)
				#do the plots
				plot.proportions.loss(tmean,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.mean.png',sep=''),header=paste(year,'proportions'))
				plot.proportions.loss(tmax,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.max.png',sep=''),header=paste(year,'proportions'))
				plot.proportions.loss(tmin,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.min.png',sep=''),header=paste(year,'proportions'))
			}
		}	
	}
	gain.calc = function(xdata,disp){
		for (year in years) { 
			for (ES in ESs) {
				tmean = mask; tmean[cbind(pos$row,pos$col)] = rowMeans(xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]])
				tmin = mask; tmin[cbind(pos$row,pos$col)] = apply(xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,min)
				tmax = mask; tmax[cbind(pos$row,pos$col)] = apply(xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]],1,max)
				#do the plots
				plot.proportions(tmean,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.mean.png',sep=''),header=paste(year,'proportions'))
				plot.proportions(tmax,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.max.png',sep=''),header=paste(year,'proportions'))
				plot.proportions(tmin,paste(out.dir,group,'.',disp,'.',ES,'.',year,'.min.png',sep=''),header=paste(year,'proportions'))
			}
		}	
	}
		
	#start with the species richness
	tdata = as.matrix(read.csv(gzfile(paste(group,'.no.disp.sum.csv.gz',sep='')),as.is=TRUE))
	if (is.null(tname)) {
		tnames = colnames(tdata) #get the column names
		years = c(2020,2050,2080)
		ESs = gsub('A1B_','',tnames); ESs = ESs[-which(ESs=="current_0.5degrees")]
		for (ii in years) { ESs = gsub(ii,'',ESs) } ; ESs = unique(ESs)
		for (ii in 1:length(ESs)) { ESs[ii] = strsplit(ESs[ii],'__')[[1]][1] } ; ESs = unique(ESs)
		
	}
	current = mask; current[cbind(pos$row,pos$col)] = tdata[,"current_0.5degrees"] #Create as ascii file for present
	current.richness = tdata[,"current_0.5degrees"]
	plot.richness(current,paste(out.dir,group,'.current.png',sep=''),header='Richness')
	
	#convert the data to proportion
	richness.calc(tdata[,] / current.richness,'no.disp') #convert to proportion and summarize
	tdata = as.matrix(read.csv(gzfile(paste(group,'.real.sum.csv.gz',sep='')),as.is=TRUE))
	richness.calc(tdata[,] / current.richness,'real') #convert to proportion and summarize
	tdata = as.matrix(read.csv(gzfile(paste(group,'.opt.sum.csv.gz',sep='')),as.is=TRUE))
	richness.calc(tdata[,] / current.richness,'opt') #convert to proportion and summarize
	
	#work with species loss
	tdata = as.matrix(read.csv(gzfile(paste(group,'.no.disp.loss.csv.gz',sep='')),as.is=TRUE))
	loss.calc(abs(tdata[,]) / current.richness, 'no.disp.loss') #convert to proportion and summarize
	tdata2a = as.matrix(read.csv(gzfile(paste(group,'.real.loss.csv.gz',sep='')),as.is=TRUE))
	loss.calc(abs(tdata2a[,]) / current.richness, 'real.loss') #convert to proportion and summarize
	tdata3a = as.matrix(read.csv(gzfile(paste(group,'.opt.loss.csv.gz',sep='')),as.is=TRUE))
	loss.calc(abs(tdata3a[,]) / current.richness, 'opt.loss') #convert to proportion and summarize
	
	#work with species gain
	tdata2b = as.matrix(read.csv(gzfile(paste(group,'.real.gain.csv.gz',sep='')),as.is=TRUE))
	gain.calc(tdata2b[,] / current.richness, 'real.gain') #convert to proportion and summarize
	tdata3b = as.matrix(read.csv(gzfile(paste(group,'.opt.gain.csv.gz',sep='')),as.is=TRUE))
	gain.calc(tdata3b[,] / current.richness, 'opt.gain') #convert to proportion and summarize
	
	#calculate the novelty information
	gain.calc(((abs(tdata2a[,]) / current.richness)+(tdata2b[,] / current.richness))/2,'real.novelty')
	gain.calc(((abs(tdata3a[,]) / current.richness)+(tdata3b[,] / current.richness))/2,'opt.novelty')	

	}



