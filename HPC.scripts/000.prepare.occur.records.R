#setup & load libraries needed for run
.libPaths(c(.libPaths(),'/homes/31/jc165798/R_libraries'))
library(SDMTools)

################################################################################

#define & set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/'; setwd(work.dir)

#define the location of the occur files and list the files
in.dir = '/homes/31/jc165798/working/Wallace.Initiative/raw.files.recieved.20100414/occur.play/'
infiles.occur = list.files(in.dir,pattern='\\.csv')

#define the output basedir
base.out.dir = '/homes/31/jc165798/working/Wallace.Initiative/models/'

#training data directory
train.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/'

#define the environmental variables to be used in appending data
enviro.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/current.0.1degree/'
enviro.layers = list.files(enviro.dir,pattern='asc.gz'); enviro.layers = gsub('\\.asc.gz','',enviro.layers) #list files and remove the suffix
#load the enviro.data
for (enviro in enviro.layers) { cat(enviro,'\n'); assign(enviro,read.asc.gz(paste(enviro.dir,enviro,'.asc.gz',sep=''))) }
cellsize = attr(get(enviro.layers[1]),'cellsize')

# rm -rf occur.play
# cp -af InputOccurrenceData occur.play
# cd occur.play
# ls -s
# tr -cd "[:alnum:] ,.\n" < amphibia.csv > amphibia2.csv
# tr -cd "[:alnum:] ,.\n" < aves.csv > aves2.csv
# tr -cd "[:alnum:] ,.\n" < mammalia.csv > mammalia2.csv
# tr -cd "[:alnum:] ,.\n" < plantae.csv > plantae2.csv
# tr -cd "[:alnum:] ,.\n" < reptilia.csv > reptilia2.csv
# ls -s
# rm *a.csv
# rm *s.csv
# rm *e.csv
# rename the files
#grep Ensatina amphibia.csv > trial.csv

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
	write.csv(occur,paste(train.dir,infile,sep=''),row.names=F)#write out the occurrence records
	
	#get a species list where the species counts are < 10 records
	counts = aggregate(occur$taxon,by=list(taxon=occur$taxon),length)
	species = counts$taxon[which(counts$x>=10)]
	
	#cycle through each of the species
	cnt = 0
	for (spp in species){
		if (cnt %% 50 == 0) { cat(round(cnt/length(species)*100,2),'%\n') } else { cat('.') }
		out.dir = paste(base.out.dir,gsub('\\.csv','/',infile),spp,'/',sep=''); dir.create(out.dir,recursive=T) #define the output directory and create it
		system(paste('grep -e taxon -e ',spp,' ',train.dir,infile,' > ',out.dir,'occur.csv',sep=''))
		#write.csv(occur[which(occur$taxon==spp),],paste(out.dir,'occur.csv',sep=''),row.names=F) #write out the the subset of the data for the species
		cnt = cnt + 1
	} 
	cat('\n')
}
