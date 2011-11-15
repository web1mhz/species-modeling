#drafted by Jeremy VanDerWal ( jjvanderwal@gmail.com ... www.jjvanderwal.com )
#GNU General Public License .. feel free to use / distribute ... no warranties

################################################################################
################################################################################

# this is code to convert climgen ascii to csv or esri ascii grid files

################################################################################
################################################################################
library(SDMTools) #load the necessary libraries

wd = '~/tmp/conversion/'; setwd(wd) #define and set the working directory
foi = 'out/main/pre_patCMIP3cccma_cgcm31___A2A1B_____dtUSERSEL__20342063ann_monthly_reglandboxes_______.climgen' #define the file of interest
#foi = 'tmx_obscru_ts_3_00______________________________19012005ann_monthly_reglandboxes_______.climgen' #define the file of interest

## get header information
header = readLines(foi, n=25)	#read in the header info for the file of interest
clim.var = substr(header[6],2,4)	#get the climate variable of interest
lon = seq(-179.75,179.75,length=720); lat = seq(-89.75,89.75,length=360)	#define the lats and lons
tstr = gsub(' ','',header[9]); tstr = strsplit(tstr,'\\]\\[')	#start processing the tstr
num.pnts = as.numeric(gsub('\\[Regis=','',tstr[[1]][1]))	#get the number of spatial points to be processed
num.times = as.numeric(gsub('Periods=','',tstr[[1]][2]))	#get the number of time points to be processed

##read in teh data
tdata = readLines(foi)[-c(1:25)] #read in the data
out = matrix(NA,nr=num.pnts,nc=2+num.times*12) #define the output dataset
out[,1] = as.numeric(substr(tdata[seq(1,by=num.times+1,length=num.pnts)],33,40)) #output the lats
out[,2] = as.numeric(substr(tdata[seq(1,by=num.times+1,length=num.pnts)],41,48)) #output the lons
t.times = NULL	#define a variable to hold the years associated with the times
for (ii in 1:num.times) { cat(ii,'...\n')	#cycle through each of the time and extract the data
	t.times = c(t.times,round(mean(c(as.numeric(substr(tdata[1+ii],1,5)),as.numeric(substr(tdata[1+ii],6,10))))))	#get the year that we are working with 
	for (jj in 1:12) { out[,(2+jj)+12*(ii-1)] = as.numeric(substr(tdata[seq(1+ii,by=num.times+1,length=num.pnts)],11+6*(jj-1),16+6*(jj-1))) }	# cycle through each of the months to extact that data
}
tnames = c('lat','lon')	#start adding column names
for (ii in 1:num.times) { tnames = c(tnames,paste(clim.var,t.times[ii],sprintf('%02i',1:12),sep='')) }	# get the remainder of the column names
colnames(out) = tnames 	#set the column names to the database

##write out the data
write.csv(out,'full.data.with.lat.lon.csv',row.names=FALSE)	#writewrite the csv... although I am writing out the full dataset, this can be subsetted
dataframe2asc(out,gz=TRUE) #write out the individual columns as esri ascii grid files
