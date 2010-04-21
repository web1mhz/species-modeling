#setup & load libraries needed for run
.libPaths(c(.libPaths(),'/homes/31/jc165798/R_libraries'))
library(SDMTools)

################################################################################

#define & set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/'; setwd(work.dir)

#define the location of the occur files and list the files
in.dir = '/homes/31/jc165798/working/Wallace.Initiative/raw.files.20100417/unzipped/'
infiles.occur = list.files(in.dir,pattern='\\.csv')

#training data directory
train.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/'

#define the environmental variables to be used in appending data
enviro.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/current.0.1degree/'
enviro.layers = list.files(enviro.dir,pattern='asc.gz'); enviro.layers = gsub('\\.asc.gz','',enviro.layers) #list files and remove the suffix
#load the enviro.data
for (enviro in enviro.layers) { cat(enviro,'\n'); assign(enviro,read.asc.gz(paste(enviro.dir,enviro,'.asc.gz',sep=''))) }
cellsize = attr(get(enviro.layers[1]),'cellsize')

#define the temporary script folder
tmp.pbs = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs/'

#cycle through each of the occurrence files
for (infile in infiles.occur) {
	cat(infile,'\n')
	#read in and prep occur data
	occur = read.csv(paste(in.dir,infile,sep=''),as.is=T) #read in the data
	occur = occur[,c('specie_id','lon','lat')] #exclude extra columns
	occur$lat = round(occur$lat/cellsize)*cellsize #round lat to nearest cellsize
	occur$lon = round(occur$lon/cellsize)*cellsize #round lon to nearest cellsize
	occur = unique(occur) #keep only unique occurrence records
	
	#append the environmental data to the occurrence records
	for (enviro in enviro.layers) { cat('appending',enviro,'\n'); occur[[enviro]] = extract.data(occur[,c('lon','lat')],get(enviro)) }
	occur = na.omit(occur) #remove any records with missing data
	
	#get a species list where the species counts are < 10 records
	counts = aggregate(occur$specie_id,by=list(specie_id=occur$specie_id),length)
	species = counts$specie_id[which(counts$x>=10)]
	save(species,file=paste(tmp.pbs,gsub('csv','',infile),'species.Rdata',sep=''))
	
	#remove occur  records for species not in species list
	occur = occur[which(occur$specie_id %in% species),]
	
	#write out the occurrance file
	write.csv(occur,paste(train.dir,infile,sep=''),row.names=F)#write out the occurrence records
	
	#define the number of bins for running the sh scripts
	bins = seq(1,length(species),100); bins = c(bins,length(species))
	
	#cycle through and submit the jobs
	for (ii in 1:(length(bins)-1)) {
		#create a temporary R script
		zz = file(paste(tmp.pbs,gsub('csv','',infile),sprintf('%05i',ii),'.R',sep=''),'w')
			cat('work.dir="/homes/31/jc165798/working/Wallace.Initiative/training.data/individual.spp.occur/"; setwd(work.dir) \n',file=zz)
			cat('occur=read.csv("',train.dir,infile,'") \n',sep='',file=zz)
			cat('load("',tmp.pbs,gsub('csv','',infile),'species.Rdata") \n',sep='',file=zz)
			cat('species=species[',bins[ii],':',bins[ii+1],'] \n',sep='',file=zz)
			cat("for (spp in species){ write.csv(occur[which(occur$specie_id==spp),],paste(spp,'.csv',sep=''),row.names=F) } \n",file=zz)
		#close the file
		close(zz)
		
		#create the job submission script
		zz = file(paste(tmp.pbs,gsub('csv','',infile),sprintf('%05i',ii),'.sh',sep=''),'w')
			cat('cd ',tmp.pbs,' \n',sep='',file=zz)
			cat('R CMD BATCH ',gsub('csv','',infile),sprintf('%05i',ii),'.R ',gsub('csv','',infile),sprintf('%05i',ii),'.Rout --no-save \n',sep='',file=zz)
		#close the file
		close(zz)
	}
}

#cycle through and submit all the sh scripts created
setwd(tmp.pbs)
sh.files = list.files(,pattern='\\.sh')
for (sh.file in sh.files) { system(paste('qsub -l nodes=1:ppn=1 ',sh.file,sep='')); system('sleep 0.5') }
 
