require(rgdal)
require(raster)

#baseDir <- "C://CIAT_work//GBIF_project//AmysVisit"
#baseOutDir <- "C://CIAT_work//GBIF_project//AmysVisit"

#outDir <- paste(baseOutDir, "//500km_buffers", sep="")

#if (!file.exists(outDir)) {
#	dir.create(outDir)
#}

#spDir <- paste(baseDir, "//per_sp_csv", sep="")

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