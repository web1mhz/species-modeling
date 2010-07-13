#define the directories
csv.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/'
model.dir = '/homes/31/jc165798/working/Wallace.Initiative/models/'
#define the datafiles for all but plants
data.files = c('amphibia.csv','aves.csv','mammalia.csv','reptilia.csv')
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

#deal with plants
data.file = 'plantae.csv'
tdata = read.csv(paste(csv.dir,data.file,sep=''),as.is=T) #read in the data
tdata2 = unique(tdata[1:6]) #get the unique families / species
families = as.character(unique(tdata2$family)) #get the unique families
for (fam in families) {
	tdata3 = tdata2[which(tdata2$family==fam),] #get a subset of the data for that family
	group.dir = paste(model.dir,'plantae/',fam,'/',sep=''); dir.create(group.dir,recursive=TRUE) #create the output directory
	species = unique(tdata3$specie_id) #get the unique species
	for (spp in species) {
		src = paste(model.dir,spp,'.tar.gz',sep='')
		#src = paste(model.dir,'plantae/',spp,'.tar.gz',sep='')
		dst = paste(group.dir,spp,'.tar.gz',sep='')
		if (file.exists(src)) { cat(src,'\n'); system(paste('mv ',src,' ',dst,sep='')) }	
	}
}
