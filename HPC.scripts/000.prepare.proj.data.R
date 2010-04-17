#define & set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/'; setwd(work.dir)

#define some directories
in.dir = '/homes/31/jc165798/working/Wallace.Initiative/raw.files.20100417/'
tmp.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp/'
out.dir = '/homes/31/jc165798/working/Wallace.Initiative/projecting.data/'

#define the location of the occur files and list the files
infiles = list.files(in.dir,pattern='\\.asc',recursive=T,full.names=T); infiles = gsub('//','/',infiles)
ascfiles = paste('bio_',c(1,4,5,6,12,15,16,17),'.asc',sep='')
pos = NULL; for (ii in ascfiles) pos = c(pos,grep(ii,infiles))
infiles = infiles[pos]

#define the output files
outfiles = infiles
outfiles = gsub(in.dir,'',outfiles) #remove the 'work.dir' from the locations
outfiles = gsub('0s/','0/',outfiles) #remove the s on  2080s etc...
outfiles = gsub('/2020/','_2020_',outfiles) #replace / with _
outfiles = gsub('/2050/','_2050_',outfiles) #replace / with _
outfiles = gsub('/2080/','_2080_',outfiles) #replace / with _

#create the output directories
out.dirs = dirname(outfiles); out.dirs = unique(out.dirs)
for (ii in out.dirs) { dir.create(paste(tmp.dir,ii,sep=''),recursive=T);dir.create(paste(out.dir,ii,sep=''),recursive=T) }

#copy asc files to the tmp directory
for (ii in 1:length(infiles)) { file.copy(infiles[ii],paste(tmp.dir,outfiles[ii],sep=''),overwrite=T,recursive=T) }

#convert the files to mxe
for (ii in out.dirs) { cat(ii,'\n'); system(paste('java -mx1024m -cp ',work.dir,'maxent.jar density.Convert ',paste(tmp.dir,ii,sep=''),' asc ',paste(out.dir,ii,sep=''),' mxe',sep='')) }

#delete the tmp folder
system(paste('rm -rf ',tmp.dir,sep=''))
