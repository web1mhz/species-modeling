#Creates a buffer area around a set of sampling points (lat/lon). As it is from points, the areas are circular. You should define a buffer distance (bDist) in meters (do not worry whether your data is in lat/lon), the raster package will handle everything with transformations between these distances. 

#Resolution (resol) should be in degree. spFile is the input occurrences file (ID, Lon, Lat), and spOutFile is the name of your ASCIIGrid file (raster).

require(rgdal)
require(raster)

createBuffers <- function(spFile, spOutFile, bDist, resol) {
  
  nCol <- round(360 / resol)
  nRow <- round(180 / resol)
  
  rs <- raster(ncol=nCol, nrow=nRow)
  rs[] <- 1
  
	#bDist must be in meters
	#spFile <- paste(spDir, "//species_", spID, ".csv", sep="")
	
	if (file.exists(spFile)) {
		
		cat('Processing...', "\n")
		
		#spOutFile <- paste(outDir, "//buffer_", spID, ".asc", sep="")
		
		if (!file.exists(spOutFile)) {
			spData <- read.csv(spFile)
			
			xMax <- max(spData$Longitude) + (bDist/111190)*1.5
			xMin <- min(spData$Longitude) - (bDist/111190)*1.5
			yMax <- max(spData$Latitude) + (bDist/111190)*1.5
			yMin <- min(spData$Latitude) - (bDist/111190)*1.5
			
			bb <- extent(xMin, xMax, yMin, yMax)
      rs <- crop(rs, bb)
      
      rsd <- distanceFromPoints(rs, spData[,2:3])
			
			rsdf <- rsd
			rsdf[which(rsdf[] > bDist)] <- 0
			rsdf[which(rsdf[] != 0)] <- 1
			
			dataType(rsdf) <- 'INT1U'
			
			rsdf <- writeRaster(rsdf, spOutFile, format='ascii', datatype='INT1U', overwrite=T)
			#rm(rsdf)
			rm(rsd)
		} else {
      rsdf <- raster(spOutFile)
		}
	} else {
	 stop("The occurrence file does not exist")
	}
	return(rsdf)
}