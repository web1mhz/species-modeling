#this is to post process a single species...
#this includes:
#	- unzipping the tar file of the models
#	- creating a Rnw file for sweave to summarize the data (creating all images, etc.)
#	- run the Sweave and pdflatex to create the summary outputs
#	- re-tar everything and put it back...

################################################################################
#test species
spp = 13274112

################################################################################
#load libraries & source
library(SDMTools)
library(raster)
source('/homes/31/jc165798/SCRIPTS/misc/R_scripts/PDFreports/Sweave.R')

################################################################################
#setup the constants

#define and set directories; extract the data to work with
data.dir = '/data/jc165798/models/'
base.work.dir = '/tmp/'; setwd(base.work.dir) #define and set the base working directory
file.copy(paste(data.dir,spp,'.tar.gz',sep=''),paste(base.work.dir,spp,'.tar.gz',sep=''),overwrite=T,recursive=T) #copy over the species data
system(paste('tar -xf ',spp,'.tar.gz',sep='')) #expand the species data
work.dir = paste('/tmp/',spp,'/',sep=''); setwd(work.dir) #move the working directory into the species directory
out.dir = paste(work.dir,'summaries/',sep=''); dir.create(out.dir) #defien the directory to put all summary information

#start writing out the Rnw file 
zz = file(paste(out.dir,spp,'.Rnw',sep=''),'w')
	cat('\\documentclass[a4paper]{article}','\n',sep='',file=zz)
	cat('\\title{',spp,' info}','\n',sep='',file=zz)
	cat('\\author{Jeremy VanDerWal}','\n',sep='',file=zz)
	cat('\\begin{document}','\n',sep='',file=zz)
	cat('\n',sep='',file=zz)
	cat('\\maketitle','\n',sep='',file=zz)
	cat('\n',sep='',file=zz)
	cat('this is a trial to make a pdf report for Wallace Initiative species','\n',sep='',file=zz)
	cat('\n',sep='',file=zz)
	cat('<<mainsetup,echo=false,results=hide>>=','\n',sep='',file=zz)
	cat('library(SDMTools)','\n',sep='',file=zz)
	cat('library(raster)','\n',sep='',file=zz)
	cat('library(sp)','\n',sep='',file=zz)
	cat('@\n','\n',sep='',file=zz)
	cat('<<>>=','\n',sep='',file=zz)
	cat('#do some work','\n',sep='',file=zz)
	cat('maxent.results = read.csv("',work.dir,'output/maxentResults.csv")','\n',sep='',file=zz)
	cat('print(maxent.results)','\n',sep='',file=zz)
	cat('@\n','\n',sep='',file=zz)
	cat('\\end{document}','\n',sep='',file=zz)
close(zz)

#move to the out.dir
setwd(out.dir)
Sweave(paste(spp,'.Rnw',sep=''))
system(paste('R CMD pdflatex ',spp,'.tex',sep=''))

file.copy(paste(spp,'.pdf',sep=''),paste('/homes/31/jc165798/',spp,'.pdf',sep=''),overwrite=T)




