#define the directories
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/summaries/avoid.ms/'; setwd(work.dir)


tdata = read.csv('amphibia.area.csv',as.is=TRUE); tdata = tdata[-1] #read in teh data & remove the row numbers
tdata$spp = as.numeric(tdata$spp)
#append the data and restructure it
tdata$scenario = gsub('A1B_','',tdata$scenario) #get rid of emmission scenario
tdata$scenario[grep('current',tdata$scenario)] = 'current' #redefine the cuurent name
tdata$year = tdata$GCM = tdata$ES = tdata$scenario #set new columns to tdata$scenario
tdata$year = gsub('_cccma_cgcm31','',tdata$year)
tdata$year = gsub('_csiro_mk30','',tdata$year)
tdata$year = gsub('_ipsl_cm4','',tdata$year)
tdata$year = gsub('_mpi_echam5','',tdata$year)
tdata$year = gsub('_ncar_ccsm30','',tdata$year)
tdata$year = gsub('_ukmo_hadcm3','',tdata$year)
tdata$year = gsub('_ukmo_hadgem1','',tdata$year)
tdata$ES = tdata$year; tdata$ES = gsub('_2020','',tdata$ES); tdata$ES = gsub('_2050','',tdata$ES); tdata$ES = gsub('_2080','',tdata$ES); 
for (ii in unique(tdata$ES)) { tdata$year = gsub(paste(ii,'_',sep=''),'',tdata$year) } ; tdata$year[which(tdata$year=='current')] = 2000 ; tdata$year = as.numeric(tdata$year)
for (ii in unique(tdata$ES)) { for (jj in unique(tdata$year)) { tdata$GCM = gsub(paste(ii,'_',jj,'_',sep=''),'',tdata$GCM) } } 

#cycle through each of the species and get the proportion data
tdata$prop = 0
for (spp in unique(tdata$spp)){ cat(spp,'\n')
	current = tdata$num.cells[which(tdata$ES == 'current' & tdata$spp==spp)[1]] #get the current value for the spp
	rois = which(tdata$spp==spp) #get the rows of interst for the species
	tdata$prop[rois] = tdata$num.cells[rois]/current #get the proportions
}

aggregate(tdata$prop,list(ES=tdata$ES,GCM=tdata$GCM,year=tdata$year),mean)
