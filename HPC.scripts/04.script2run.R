################################################################################
#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in group

###########################################################################################
#load the library
library(SDMTools)

###########################################################################################
#set the directories
in.dir = paste('/homes/31/jc165798/working/Wallace.Initiative/summaries/csv/',group,'/',sep='')
out.dir = paste('/homes/31/jc165798/working/Wallace.Initiative/summaries/richness/',group,'/',sep=''); dir.create(out.dir,recursive=TRUE)

#define the base map
base.asc = read.asc.gz('/homes/31/jc165798/working/Wallace.Initiative/summaries/no.migrate.mask.asc.gz')

###########################################################################################
#do the work

species = list.files(in.dir,pattern='\\.csv') #get the species

out = cois = NULL #setup the output and columns of interest

for (spp in species) { #cycle through each of the species
	cat(spp,'\n')
	tdata = as.matrix(read.csv(paste(in.dir,spp,sep=''),as.is=T)) #read in the data
	threshold = tdata[1,dim(tdata)[2]] #get the threshold
	tnames = colnames(tdata) #get the column names
	if (is.null(cois)) { cois = c(grep("_2020_",tnames),grep("_2050_",tnames),grep("_2080_",tnames),grep("current",tnames)); cois = cois[order(cois)] } #get the columns of interest
	if (is.null(out)) { out = tdata; out[,cois] = 0; out = out[,c(1:4,cois)] } #setup the basic output
	tdata = tdata[,cois]; tdata[which(tdata<threshold)] = 0; tdata[which(tdata>0)] = 1 #only keep columns needed, convert to binary
	out[,cois] = out[,cois] + tdata #add the info to the output dataset		
}

#get sum & sd of 2020, 2050 & 2080
out = as.data.frame(out)
out$mean_2020 = round(rowMeans(out[,grep('_2020_',names(out))],na.rm=T))
out$mean_2050 = round(rowMeans(out[,grep('_2050_',names(out))],na.rm=T))
out$mean_2080 = round(rowMeans(out[,grep('_2080_',names(out))],na.rm=T))
out$sd_2020 = apply(out[,grep('_2020_',names(out))],1,function(x) { return(sd(x,na.rm=TRUE)) })
out$sd_2050 = apply(out[,grep('_2050_',names(out))],1,function(x) { return(sd(x,na.rm=TRUE)) })
out$sd_2080 = apply(out[,grep('_2080_',names(out))],1,function(x) { return(sd(x,na.rm=TRUE)) })
out$worst_2020 = round(out$mean_2020 - (1.96 * out$sd_2020)); out$best_2020 = round(out$mean_2020 + (1.96 * out$sd_2020)); out$worst_2020[which(out$worst_2020<0)] = 0
out$worst_2050 = round(out$mean_2050 - (1.96 * out$sd_2050)); out$best_2050 = round(out$mean_2050 + (1.96 * out$sd_2050)); out$worst_2050[which(out$worst_2050<0)] = 0
out$worst_2080 = round(out$mean_2080 - (1.96 * out$sd_2080)); out$best_2080 = round(out$mean_2050 + (1.96 * out$sd_2080)); out$worst_2080[which(out$worst_2080<0)] = 0

#rename the current column
names(out)[grep('current',names(out))] = 'current'

#write the data
write.csv(out,paste(out.dir,group,'.csv',sep=''),row.names=FALSE)

##set some common plotting information
legend.local = cbind(c(-130,-135,-135,-130),c(-40,-40,0,0)) 
cols = c('gray', colorRampPalette(c('yellow','red'))(100))

#create the images
for (tname in names(out)[5:length(out)]) {
	values = out[,tname] #set anything less than threshold to 0
	zlimits = range(values)
	png(paste(out.dir,tname,'.png',sep=''),width=dim(base.asc)[1]*2,height=dim(base.asc)[2]*2)
		par(mar=c(0,0,0,0))	
		tasc = base.asc; tasc[cbind(out$row,out$col)] = values
		image(tasc,zlim=zlimits,col = cols)
		legend.gradient(legend.local,cols,title='Richness',limits=zlimits,cex=2)
	dev.off()
}
