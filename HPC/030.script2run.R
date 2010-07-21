################################################################################
#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in group

###########################################################################################
#define the woorking directory
work.dir = paste('/data/jc165798/WallaceInitiative/models/',group,'/',sep=''); setwd(work.dir)
out.dir = '/data/jc165798/WallaceInitiative/richness/avoid.ms/'
#get a list of the species
species = list.files()
#define the output
out = NULL #setup the output and columns of interest
#cycle through the species
for (spp in species) { cat(spp,'\n')
	tfile = paste(spp,'/summaries/prediction.area.csv.gz',sep='')
	if (file.exists(tfile)) {
		tdata = read.csv(gzfile(tfile),as.is=TRUE) #read in the data
		if (is.null(out)) { out = tdata } else { out = rbind(out,tdata) }		
	}
}
#write the output
write.csv(out,paste(out.dir,group,'.area.csv',sep=''),row.names=FALSE)
