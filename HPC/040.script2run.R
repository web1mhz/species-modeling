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
out.dir = '/data/jc165798/WallaceInitiative/richness/data/'; dir.create(out.dir)

#get a list of the species
species = list.files()
#define the outputs
n = 0 #track the number of species
no.sum = no.loss = real.sum = real.loss = real.gain = opt.sum = opt.loss = opt.gain = NULL #these are the basic data outputs
#cycle through the species
for (spp in species) { cat(spp,'\n')
	tfile = paste(spp,'/summaries/predictions.binary.dispersal.csv.gz',sep='')
	if (file.exists(tfile)) { n = n + 1
		indata = as.matrix(read.csv(gzfile(tfile),as.is=TRUE)) #read in the data
		if (is.null(no.sum)) { #setup all storage outputs
			tnames = colnames(indata); outnames = tnames[grep('_',tnames)]
			no.sum = indata[,outnames] #just keep the columns of interest
			no.sum[,] = 0 #set everything == 0
			no.loss = real.sum = real.loss = real.gain = opt.sum = opt.loss = opt.gain = no.sum #set starting work to all 0
		} 		
		#append all the information
		#first No dispersal
		tdata=as.matrix(indata) #get a copy of indata
		for (tname in outnames) { tdata[,tname] = tdata[,tname] * tdata[,'no.disp'] } #apply NO dispersal clip
		no.sum[,] = no.sum[,] + tdata[,outnames] #append the sum of the species to the sum
		for (tname in outnames) { if (tname!="current_0.5degrees") { tdata[,tname] = tdata[,tname] - tdata[,"current_0.5degrees"] } } #subtract all data from current
		tdata2 = tdata[,outnames]; tdata2[which(tdata2>0)] = 0; no.loss[,] = no.loss[,] + tdata2[,] #tally the losses
		
		#now for realistic dispersal
		tdata=as.matrix(indata) #get a copy of indata
		tdata[,"current_0.5degrees"] = tdata[,'current_0.5degrees'] * tdata[,'no.disp'] #define the current
		for (tname in outnames[grep('_2020_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2020.real'] } #apply dispersal clip
		for (tname in outnames[grep('_2050_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2050.real'] } #apply dispersal clip
		for (tname in outnames[grep('_2080_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2080.real'] } #apply dispersal clip
		real.sum[,] = real.sum[,] + tdata[,outnames] #append the sum of the species to the sum
		for (tname in outnames) { if (tname!="current_0.5degrees") { tdata[,tname] = tdata[,tname] - tdata[,"current_0.5degrees"] } } #subtract all data from current
		tdata2 = tdata[,outnames]; tdata2[which(tdata2>0)] = 0; real.loss[,] = real.loss[,] + tdata2[,] #tally the losses
		tdata2 = tdata[,outnames]; tdata2[which(tdata2<0)] = 0; real.gain[,] = real.gain[,] + tdata2[,] #tally the gains

		#now for optimistic dispersal
		tdata=as.matrix(indata) #get a copy of indata
		tdata[,"current_0.5degrees"] = tdata[,'current_0.5degrees'] * tdata[,'no.disp'] #define the current
		for (tname in outnames[grep('_2020_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2020.opt'] } #apply dispersal clip
		for (tname in outnames[grep('_2050_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2050.opt'] } #apply dispersal clip
		for (tname in outnames[grep('_2080_',outnames)]) { tdata[,tname] = tdata[,tname] * tdata[,'pot.2080.opt'] } #apply dispersal clip
		opt.sum[,] = opt.sum[,] + tdata[,outnames] #append the sum of the species to the sum
		for (tname in outnames) { if (tname!="current_0.5degrees") { tdata[,tname] = tdata[,tname] - tdata[,"current_0.5degrees"] } } #subtract all data from current
		tdata2 = tdata[,outnames]; tdata2[which(tdata2>0)] = 0; opt.loss[,] = opt.loss[,] + tdata2[,] #tally the losses
		tdata2 = tdata[,outnames]; tdata2[which(tdata2<0)] = 0; opt.gain[,] = opt.gain[,] + tdata2[,] #tally the gains
	}
}

#write the outputs
write.csv(no.sum,gzfile(paste(out.dir,group,'.no.disp.sum.csv.gz',sep='')),row.names=FALSE)
write.csv(no.loss,gzfile(paste(out.dir,group,'.no.disp.loss.csv.gz',sep='')),row.names=FALSE)
write.csv(real.sum,gzfile(paste(out.dir,group,'.real.sum.csv.gz',sep='')),row.names=FALSE)
write.csv(real.loss,gzfile(paste(out.dir,group,'.real.loss.csv.gz',sep='')),row.names=FALSE)
write.csv(real.gain,gzfile(paste(out.dir,group,'.real.gain.csv.gz',sep='')),row.names=FALSE)
write.csv(opt.sum,gzfile(paste(out.dir,group,'.opt.sum.csv.gz',sep='')),row.names=FALSE)
write.csv(opt.loss,gzfile(paste(out.dir,group,'.opt.loss.csv.gz',sep='')),row.names=FALSE)
write.csv(opt.gain,gzfile(paste(out.dir,group,'.opt.gain.csv.gz',sep='')),row.names=FALSE)
