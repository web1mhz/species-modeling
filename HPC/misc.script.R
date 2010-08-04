##############################################
#merge and summarize the richness outputs

#define and set the working directory
work.dir = 'c:/tmp2/ecozone_richness/'; setwd(work.dir)

#read in the basic wwf data
wwf.basedata = read.csv('eco_code_richness.data.wwf.csv',as.is=TRUE)

#read in the Wallace data
amph = read.csv('amphibia.csv',as.is=TRUE)[2:3]; names(amph)[2] = 'Rich_amp_Wallace'
aves = read.csv('aves.csv',as.is=TRUE); names(aves)[2] = 'Rich_avi_Wallace'
mamm = read.csv('mammalia.csv',as.is=TRUE); names(mamm)[2] = 'Rich_mam_Wallace'
rept = read.csv('reptilia.csv',as.is=TRUE); names(rept)[2] = 'Rich_rep_Wallace'

#merge the data
out = merge(wwf.basedata,amph,all=TRUE)
out = merge(out,rept,all=TRUE)
out = merge(out,mamm,all=TRUE)
out = merge(out,aves,all=TRUE)

#create some plots
plot(out$Rich_amp_WWF,out$Rich_amp_Wallace,xlab='WWF amphibian richness',ylab='Wallace amphibian richness')
abline(lm(out$Rich_amp_Wallace~out$Rich_amp_WWF),col='red')


#write out the data to use in ArcMap
write.csv(out,'data4ArcMap.csv',row.names=FALSE)


##############################################3
#misc for luke to play
library(SDMTools)

#define and set the working directory
work.dir = 'c:/tmp2/'; setwd(work.dir)

#read in the mask and the positions
pos = read.csv('mask.pos.csv',as.is=TRUE)
mask = read.asc.gz('mask.asc.gz')

#read in the avian dataset
tdata = as.matrix(read.csv(gzfile('aves.no.disp.sum.csv.gz'),as.is=TRUE))

#define the current species richness
current.richness = tdata[,"current_0.5degrees"]

#convert the data to be a proportion of the present
xdata = tdata[,] / current.richness

#define the output dataset
out = pos

#extract the year and emmission scenario info
tnames = colnames(tdata) #get the column names
years = c(2020,2050,2080)
ESs = gsub('A1B_','',tnames); ESs = ESs[-which(ESs=="current_0.5degrees")]
for (ii in years) { ESs = gsub(ii,'',ESs) } ; ESs = unique(ESs)
for (ii in 1:length(ESs)) { ESs[ii] = strsplit(ESs[ii],'__')[[1]][1] } ; ESs = unique(ESs)

#cycle through each year and emmission scenario
for (year in years) { 
	for (ES in ESs) {
		tt = xdata[,tnames[intersect(grep(year,tnames),grep(ES,tnames))]]; tt[which(tt<0.75)] = 0; tt[which(tt>0)] = 1
		tt = rowSums(tt) #refugica certainty
		#uncomment following statements if you want to create the ascii grid files
		#refuge.certainty = mask; refuge.certainty[cbind(pos$row,pos$col)] = (tt) 
		out[paste(ES,year,sep='_')] = tt
	}
}


###
#work on areas
cois = names(out)[c(grep('A30r5l',names(out)),grep('SRES',names(out)))]
#setup the output data
out2 = NULL
#Cycle through each column
for (coi in cois) {
	tdata = out[which(out[,coi]>0 & is.finite(out[,coi])),] #get the subset of data for the column of interest
	tt = aggregate(tdata$area,by=list(realm=tdata$ecozone0.5,certainty=tdata[,coi]),sum)
	names(tt)[3] = coi #reset the column name
	if (is.null(out2)) { out2 = tt } else { out2 = merge(out2,tt,all=TRUE) } #create or merge data as necessary
}

