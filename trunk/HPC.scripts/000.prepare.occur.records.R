#setup & load libraries needed for run
.libPaths(c(.libPaths(),'/homes/31/jc165798/R_libraries'))
library(SDMTools)

################################################################################

#define & set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/'; setwd(work.dir)

#define the location of the occur files and list the files
in.dir = '/homes/31/jc165798/working/Wallace.Initiative/raw.files.recieved.20100414/InputOccurrenceData/'
infiles.occur = list.files(in.dir,pattern='\\.csv')

#define the output basedir
base.out.dir = '/homes/31/jc165798/working/Wallace.Initiative/models/'

#define the environmental variables to be used in appending data
enviro.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/current.0.1degree/'
enviro.layers = list.files(enviro.dir,pattern='asc.gz'); enviro.layers = gsub('\\.asc.gz','',enviro.layers) #list files and remove the suffix
cellsize = attr(get(enviro.layers[1]),'cellsize')
#load the enviro.data
for (enviro in enviro.layers) { cat(enviro,'\n'); assign(enviro,read.asc.gz(paste(enviro.dir,enviro,'.asc.gz',sep=''))) }

#cycle through each of the occurrence files
for (infile in infiles.occur) {
	cat(infile,'\n')
	#read in and prep occur data
	occur = read.csv(paste(in.dir,infile,sep=''),as.is=T) #read in the data
	occur = occur[,c('taxon','lon','lat')] #exclude extra columns
	occur$taxon = gsub(' ','\\.',occur$taxon) #replace spaces in taxon names
	occur$lat = round(occur$lat/cellsize)*cellsize #round lat to nearest cellsize
	occur$lon = round(occur$lon/cellsize)*cellsize #round lon to nearest cellsize
	occur = unique(occur) #keep only unique occurrence records
	
	#append the environmental data to the occurrence records
	for (enviro in enviro.layers) { cat('appending',enviro,'\n'); occur[[enviro]] = extract.data(occur[,c('lon','lat')],get(enviro)) }
	occur = na.omit(occur) #remove any records with missing data
	
	#split up the occurrence records and file them into individual folders 
	# *** ONLY IF they have >10 unique records
	species = unique(occur$taxon)
	for (spp in species){
		cat('.')
		if ( length(which(occur$taxon==spp))>=10 ) { #only work with species if number of occur >=10
			out.dir = paste(base.out.dir,gsub('\\.csv','/',infile),spp,'/',sep=''); dir.create(out.dir,recursive=T) #define the output directory and create it
			write.csv(occur[which(occur$taxon==spp),],paste(out.dir,'occur.csv',sep=''),row.names=F) #write out the the subset of the data for the species
		}
	}; cat('\n')
}
