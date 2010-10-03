################################################################################
#get the command line arguements
args=(commandArgs(TRUE))

#evaluate the arguments
for(i in 1:length(args)) {
 eval(parse(text=args[[i]]))
}
#should have read in something like
# group="amphibia"
# tname='no.disp.sum.csv.gz'

################################################################################
# load libraries and add functions
library(SDMTools)

################################################################################
# start doing some work

#define / create some directories
base.dir = '/home/uqvdwj/WallaceInitiative/summaries/richness/'; setwd(base.dir) #this is the basic input and output directory

#cycle through and get richness for taxa
out = NULL #defien the output file
tfiles=list.files(paste('family/',group,sep=''),pattern=tname,full.names=TRUE,recursive=TRUE) #get a list of the files
for (tfile in tfiles) {
	tdata = as.matrix(read.csv(gzfile(tfile),as.is=TRUE))
	if (is.null(out)) { out=tdata } else { out = out[,] + tdata[,] }
}
#write out the data
dir.create(paste('taxa/',group,'/',sep=''),recursive=TRUE)
write.csv(out,gzfile(paste('taxa/',group,'/',tname,sep='')),row.names=FALSE)
