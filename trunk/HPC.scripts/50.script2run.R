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
work.dir = paste('/home1/31/jc165798/working/Wallace.Initiative/summaries/csv/',group,'/',sep=''); setwd(work.dir)
out.dir = '/homes/31/jc165798/working/Wallace.Initiative/summaries/avoid.ms/'
#get a list of the species
species = list.files(,pattern='\\.prediction.area.csv.gz')
#define the output
out = NULL #setup the output and columns of interest
#cycle through the species
for (spp in species) { cat(spp,'\n')
	tdata = read.csv(gzfile(spp),as.is=TRUE) #read in the data
	if (is.null(out)) { out = tdata } else { out = rbind(out,tdata) }		
}
#write the output
write.csv(out,paste(out.dir,group,'.area.csv',sep=''),row.names=FALSE)
