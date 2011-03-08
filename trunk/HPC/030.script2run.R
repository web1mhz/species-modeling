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

###########################################################################################
#define the woorking directory
work.dir = paste('/home/uqvdwj/WallaceInitiative/summaries/area/family/',group,'/',sep=''); setwd(work.dir)
out.dir = paste('/home/uqvdwj/WallaceInitiative/summaries/area/taxa/',group,'/',sep=''); dir.create(out.dir,recursive=TRUE)

#get a list of the species
species = list.files()
#define the output
out = NULL #setup the output and columns of interest
#cycle through the species
for (spp in species) { cat(spp,'\n')
	tfile = paste(spp,'/predicted.area.csv.gz',sep='')
	if (file.exists(tfile)) {
		tdata = read.csv(gzfile(tfile),as.is=TRUE) #read in the data
		out = rbind(out,tdata)
	}
}
#write the output
write.csv(out,gzfile(paste(out.dir,'predicted.area.csv.gz',sep='')),row.names=FALSE)
