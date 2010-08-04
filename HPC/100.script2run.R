#drafted by Jeremy VanDerWal ( jjvanderwal@gmail.com ... www.jjvanderwal.com )
#GNU General Public License .. feel free to use / distribute ... no warranties

################################################################################
################################################################################
#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in group
print(group)
#group = 'amphibia'

##############################################
#extract summary info to qualify richness measures
library(SDMTools)

#define the directories
work.dir = paste('/data/jc165798/WallaceInitiative/models/',group,'/',sep=''); setwd(work.dir)
train.dir = '/data/jc165798/WallaceInitiative/training.data/' #define the directory where generic training data is
out.dir = '/data/jc165798/WallaceInitiative/richness/ecozone_richness/'

#get a list of species
species = list.files()

#read in the mask and the positions
pos = read.csv(paste(train.dir,'mask.pos.csv',sep=''),as.is=TRUE)
mask = read.asc.gz(paste(train.dir,'mask.asc.gz',sep=''))

#need to append a column on pos which is ecozone800
pos$ecozone800 = read.asc.gz(paste(train.dir,'ecozone800.asc.gz',sep=''))[cbind(pos$row,pos$col)]
tt = read.csv(paste(train.dir,'ecozone800.definitions.csv',sep=''),as.is=TRUE)
pos$eco_code = NA; tpos = which(is.finite(pos$ecozone800));
t.ecozone800 = pos$ecozone800[tpos]; t.eco_code = NULL; n=0
for (ii in t.ecozone800) { t.eco_code = c(t.eco_code,tt$ECO_CODE[which(tt$VALUE==ii)]) }
pos$eco_code[tpos] = t.eco_code

#define the output dataset
out = read.csv(paste(train.dir,'ecozone800.definitions.csv',sep=''),as.is=TRUE)
out$richness = 0

#cycle through each of the species
for (spp in species) { cat('.')
	tfile = paste(spp,'/summaries/predictions.binary.dispersal.csv.gz',sep='')
	if (file.exists(tfile)) {
		indata = as.matrix(read.csv(gzfile(tfile),as.is=TRUE)) #read in the data	
		tdata = indata[,'current_0.5degrees'] * indata[,'no.disp'] #define the current species distriubtion
		tt = aggregate(tdata,list(eco_code=pos$eco_code),function(x) { return(max(x,na.rm=TRUE)) } ); tt = tt[which(tt$x>0),] #extract eco_codes for each species record
		for (ii in 1:nrow(tt)) { tpos = which(out$ECO_CODE==tt$eco_code[ii]); out$richness[tpos] = out$richness[tpos] + 1 }
	}
}; cat('\n')

#write out the data
write.csv(out,paste(out.dir,group,'.csv',sep=''),row.names=FALSE)
