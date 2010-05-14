#define the directories
csv.dir = '/home1/31/jc165798/working/Wallace.Initiative/training.data/'
model.dir = '/home1/31/jc165798/working/Wallace.Initiative/models/'
#define the datafiles
data.files = c('amphibia.csv','aves.csv','mammalia.csv','plantae.csv','reptilia.csv')
#cycle through the data files
for (data.file in data.files) {
	group.dir = paste(model.dir,gsub('\\.csv','',data.file),'/',sep=''); dir.create(group.dir,recursive=TRUE) #create the output directory
	tdata = read.csv(paste(csv.dir,data.file,sep=''),as.is=T) #read in the data
	species = unique(tdata$specie_id) #get the unique species
	for (spp in species) {
		src = paste(model.dir,spp,'.tar.gz',sep='')
		dst = paste(group.dir,spp,'.tar.gz',sep='')
		if (file.exists(src)) { cat(src,'\n'); system(paste('mv ',src,' ',dst,sep='')) }	
	}
}
