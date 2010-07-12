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
species = list.files(,pattern='\\.csv')
#define the output
out = cois = NULL #setup the output and columns of interest
#cycle through the species
for (spp in species) { cat(spp,'\n')
	tdata = as.matrix(read.csv(spp,as.is=TRUE)) #read in the data
	threshold = tdata[1,dim(tdata)[2]] #get the threshold
	tnames = colnames(tdata) #get the column names
	if (is.null(cois)) { cois = c(grep("_2020_",tnames),grep("_2050_",tnames),grep("_2080_",tnames),grep("current",tnames)); cois = cois[order(cois)] } #get the columns of interest
	tdata = tdata[,cois]; tdata[which(tdata<threshold)] = 0; tdata[which(tdata>0)] = 1 #only keep columns needed, convert to binary
	tout = colSums(tdata); tout = as.data.frame(tout); tout = data.frame(spp=gsub('\\.csv','',spp),scenario=rownames(tout),num.cells=tout$tout)
	out = rbind(out,tout) #add the info to the output dataset			
}
#write the output
write.csv(out,paste(out.dir,group,'.area.csv',sep=''))
