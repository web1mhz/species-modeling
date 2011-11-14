#drafted by Jeremy VanDerWal ( jjvanderwal@gmail.com ... www.jjvanderwal.com )
#GNU General Public License .. feel free to use / distribute ... no warranties

################################################################################
################################################################################
# this is a request from Miranda Jones to convert climgen netcdf outputs into a 
# csv file resembling...
# Longitude,Latitude,SST
# -179.75,89.75,-1.79
# -179.25,89.75,-1.79
# -178.75,89.75,-1.79
# -178.25,89.75,-1.79
# -177.75,89.75,-1.79
# -177.25,89.75,-1.79

################################################################################
################################################################################
library(ncdf); library(SDMTools) #load the necessary libraries

wd = '~/tmp/conversion/'; setwd(wd);	#define and set the working directory
nc = open.ncdf('climgen_output_monthly.nc')	#open a connection to the netcdf of interest
	dim.var = names(nc$dim) #get the dimension variables
	lon = get.var.ncdf(nc,'LONGITUDE')	#get a list of the longitudes
    lat = get.var.ncdf(nc,'LATITUDE')	#get a list of the latitudes
	if ('YEAR' %in% dim.var) {	#if year in dim variables... get the years
		time.var = get.var.ncdf(nc,'YEAR') 
	} else if ('MONTH' %in% dim.var) {	#if month in dim variables... get the months
		time.var = get.var.ncdf(nc,'MONTH')
	}
	out = expand.grid(latitude=lat,longitude=lon) #define the output
	vars = names(nc$var)	#get a list of the data in the netcdf file
	for (voi in vars) { cat(voi,'...\n') #cycle through each of hte variables
		tdata = get.var.ncdf(nc,voi) #read in the data array for the variable of intersest
		if (length(time.var)==1) {	#if only a single time variable, then this is not an array and so use the matrix
			out[,voi] = as.vector(tdata[,])
		} else {	#if more than a single time element, than append the different variables
			for(ii in 1:length(time.var)) { out[,paste(voi,'_',sprintf('%02i',ii),sep='')] = as.vector(tdata[ii,,]) } #append the data to out
		}
	}
close.ncdf(nc)	#close the netcdf file

write.csv(out,'full.data.with.lat.lon.csv',row.names=FALSE)	#writewrite the csv... although I am writing out the full dataset, this can be subsetted
dataframe2asc(out,gz=TRUE) #write out the individual columns as esri ascii grid files
	

