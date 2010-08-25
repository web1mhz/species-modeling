require(sp)

convexHullBuffer <- function(occFile, buffDist, outFile) {
  
  #Here I need to separate populations from different continents
  
  #Load continent file
  #Extract values by points (xyValues)
  #Get unique values
  #Loop the below code between them (take care of those being NA, you will need to assign those to the nearest point using pointDistance, probably)
  #Merge all the small buffers into one (probably the expand() command, and then sum everything)
  
  occData <- read.csv(occFile)
  
  chullPts <- chull(occData[,2:3])
  chullPointMatrix <- occData[chullPts,]
  chullPointMatrix <- rbind(chullPointMatrix, chullPointMatrix[1,])
  
  mtx <- matrix(ncol=2, nrow=nrow(chullPointMatrix))
  mtx[,1] <- chullPointMatrix[,2]
  mtx[,2] <- chullPointMatrix[,3]
  
  polys <- SpatialPolygons(list(Polygons(list(Polygon(mtx)), 1)))
  
  ymax <- max(mtx[,2]) + (buffDist/111190)*2
  ymin <- min(mtx[,2]) - (buffDist/111190)*2
  xmax <- max(mtx[,1]) + (buffDist/111190)*2
  xmin <- min(mtx[,1]) - (buffDist/111190)*2
  
  nRow <- round((180) / (0.5))
  nCol <- round((360) / (0.5))
  
  bb <- extent(xmin, xmax, ymin, ymax)
  rs <- raster(ncol=nCol, nrow=nRow)
  rs <- crop(rs, bb)
  rs[] <- 0
  
  rs <- polygonsToRaster(polys, rs)
  dr <- distance(rs)
  dr[which(dr[] <= buffDist)] <- 1
  dr[which(dr[] > buffDist)] <- NA
  
  dr <- writeRaster(dr, outFile, overwrite=T, format='ascii')
  plot(dr)
  plot(polys, add=T)
  points(mtx, pch=20, col='red')
  points(occData[,2:3])
  
}