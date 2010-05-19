#load the library
library(SDMTools)

#define the groups
groups = c('amphibia','aves','mammalia','reptilia')

#cycle through the groups
for (group in groups) {
	cat(group,'\n')

	#define and set the working directory
	work.dir = paste('/homes/31/jc165798/working/Wallace.Initiative/summaries/richness/',group,'/',sep=''); setwd(work.dir)

	#delete the current png files
	for (tfile in list.files(,pattern='\\.png')) unlink(tfile)

	#create image directories
	dir.create('images/richness/',recursive=T)
	dir.create('images/absolute_loss/',recursive=T)
	dir.create('images/percent_loss/',recursive=T)

	#define the base map
	base.asc = read.asc.gz('/homes/31/jc165798/working/Wallace.Initiative/summaries/no.migrate.mask.asc.gz')

	#read in the richness data
	rich = read.csv(paste(group,'.csv',sep=''),as.is=T)
	#adjust best to min of best & current
	rich$best_2020 = apply(cbind(rich$best_2020,rich$current),1,min)
	rich$best_2050 = apply(cbind(rich$best_2050,rich$current),1,min)
	rich$best_2080 = apply(cbind(rich$best_2080,rich$current),1,min)

	#create the change maps
	change = rich; change.percent = rich
	for (tname in names(rich)[5:length(rich)]) { 
		change[tname] = rich$current - rich[tname] 
		pos = which(rich$current>0)
		change.percent[pos,tname] = round((change[pos,tname] / rich$current[pos]) * 100,1)
	}

	#get the limits of rich and change
	rich.limits = range(rich[5:length(rich)])
	change.limits = range(change[5:length(rich)]); change.limits[2] = ceiling(change.limits[2])

	##set some common plotting information
	legend.local = cbind(c(-130,-135,-135,-130),c(-40,-40,0,0)) 
	cols = c('gray', colorRampPalette(c('yellow','red'))(100))

	#create the images
	for (tname in names(rich)[5:length(rich)]) {
		#work on the richness maps
		values = rich[,tname] #set anything less than threshold to 0
		png(paste('images/richness/',tname,'.png',sep=''),width=dim(base.asc)[1]*2,height=dim(base.asc)[2]*2)
			par(mar=c(0,0,0,0))	
			tasc = base.asc; tasc[cbind(rich$row,rich$col)] = values
			image(tasc,zlim=rich.limits,col = cols)
			legend.gradient(legend.local,cols,title='Richness',limits=rich.limits,cex=2)
		dev.off()
		#work on the change maps
		values = change[,tname] #set anything less than threshold to 0
		png(paste('images/absolute_loss/',tname,'.png',sep=''),width=dim(base.asc)[1]*2,height=dim(base.asc)[2]*2)
			par(mar=c(0,0,0,0))	
			tasc = base.asc; tasc[cbind(rich$row,rich$col)] = values
			image(tasc,zlim=change.limits,col = cols)
			legend.gradient(legend.local,cols,title='Species Loss',limits=change.limits,cex=2)
		dev.off()	
		#work on the percent change maps
		values = change.percent[,tname] #set anything less than threshold to 0
		png(paste('images/percent_loss/',tname,'.png',sep=''),width=dim(base.asc)[1]*2,height=dim(base.asc)[2]*2)
			par(mar=c(0,0,0,0))	
			tasc = base.asc; tasc[cbind(rich$row,rich$col)] = values
			image(tasc,zlim=c(0,100),col = cols)
			legend.gradient(legend.local,cols,title='Percent Loss',limits=c(0,100),cex=2)
		dev.off()	
	}
}


#####################################
R CMD Sweave report.Rnw
R CMD pdflatex report.tex
