#define some directories
work.dir = '/homes/31/jc165798/working/wallace/'; setwd(work.dir)
cur.asc.dir = '/home1/31/jc165798/working/wallace/future/current.0.1degree/ascii/'

#data file
system.time({
bkgd.file = 'background.csv'; bkgd = read.csv(bkgd.file)
occur.file = 'occur.tab'; occur = read.table(occur.file)
names(occur) = c('SPPCODE','lat','lon')
})
################################################################################
# do something
system.time({
#extract the swd information
.libPaths('/homes/31/jc165798/R_libraries'); library(SDMTools) #load the library
for (tfile in list.files(cur.asc.dir,pattern='asc.gz')) { #cycle throught and extract the ascii data
	cat(tfile,'\n')
	occur[[gsub('.asc.gz','',tfile)]] = extract.data(cbind(occur$lon,occur$lat),read.asc.gz(paste(cur.asc.dir,tfile,sep='')))
	bkgd[[gsub('.asc.gz','',tfile)]] = extract.data(cbind(bkgd$Lon,bkgd$Lat),read.asc.gz(paste(cur.asc.dir,tfile,sep='')))
}
bkgd = na.omit(bkgd)
write.csv(bkgd,'bkgd.swd',row.names=F) #write out the data
occur = na.omit(occur)
write.csv(occur,'occur.swd',row.names=F) #write out the data
})
###start setting up and running models
#get a count of the species occurrence records
species = unique(occur$SPPCODE)



#cycle through each of the species
for (spp in species) {
	#get the occur records for the species of interest & write them out
	toccur = occur[which(occur$SPPCODE==spp),]; toccur = na.omit(toccur)
	
	if (nrow(toccur)>=10){

		#create a folder for the species
		spp.folder = paste('models/',spp,"/",sep="")
		out.folder = paste(spp.folder,"output/",sep="");dir.create(out.folder, showWarnings=T, recursive=T)

		#write out hte occurrences
		write.csv(toccur,paste(spp.folder,'occur.csv',sep=''),row.names=F,na='')
		
		#create the pbs script
		z = file(paste(spp.folder,"01.maxent.pbs",sep=""),"w")
		cat('#!/bin/bash\n',file=z)
		cat('#!/usr/bin/qsub\n',file=z)
		cat('#PBS -c s\n',file=z)
		cat('#PBS -j oe\n',file=z)
		cat('#PBS -m ae\n',file=z)
		cat('#PBS -N ',spp,'\n',sep="",file=z)
		cat('#PBS -M jc165798@jcu.edu.au\n',file=z)
		cat('#PBS -l walltime=9999:00:00\n',file=z)
		cat('#PBS -l nodes=1:ppn=1 \n',file=z)
		cat('echo "------------------------------------------------------"\n',file=z)
		cat('echo " This job is allocated 2 cpu on "\n',file=z)
		cat('cat $PBS_NODEFILE\n',file=z)
		cat('echo "------------------------------------------------------"\n',file=z)
		cat('echo "PBS: Submitted to $PBS_QUEUE@$PBS_O_HOST"\n',file=z)
		cat('echo "PBS: Working directory is $PBS_O_WORKDIR"\n',file=z)
		cat('echo "PBS: Job identifier is $PBS_JOBID"\n',file=z)
		cat('echo "PBS: Job name is $PBS_JOBNAME"\n',file=z)
		cat('echo "------------------------------------------------------"\n',file=z)
		cat('cd $PBS_O_WORKDIR\n',file=z)
		cat('\n',file=z)
		cat('#run the model\n',file=z)
		cat('java -mx2000m -jar ',work.dir,'maxent.jar outputdirectory="',work.dir,out.folder,'" samplesfile="',work.dir,spp.folder,'occur.csv" environmentallayers="',work.dir,'bkgd.swd" nowarnings noaskoverwrite responsecurves novisible autorun \n',sep="",file=z)
		cat('\n',file=z)
		close(z)

		setwd(paste(work.dir,spp.folder,sep=''))
		system('qsub 01.maxent.pbs')
		setwd(work.dir)
	}
}
