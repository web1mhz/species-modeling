#Select the background file based on where the species occur

require(rgdal)
require(raster)

inputDir <- "C://CIAT_work//GBIF_project//clampingTest"
occFile <- paste(inputDir, "//occurrences//species_1.csv", sep="")

if (!file.exists(paste(inputDir, "//background", sep=""))) {
  dir.create(paste(inputDir, "//background", sep=""))
}

spData <- read.csv(occFile)

backFilesDir <- "C://CIAT_work//GBIF_project//backgroundFiles"
globZonesFile <- paste(backFilesDir, "//backselection.asc", sep="")
globZones <- raster(globZonesFile)

occZones <- xyValues(globZones, spData[,2:3])
uniqueOccZones <- unique(occZones)

if (length(uniqueOccZones == 1)) {
  zone <- uniqueOccZones
  backFile <- paste(backFilesDir, "//backsamples_z", zone, ".csv", sep="")
  
  backPts <- read.csv(backFile)
  outBackName <- paste(inputDir, "//background//BackgroundSamplePoints_1.csv", sep="")
  out <- write.csv(backPts, outBackName, quote=F)
  
  rm(uniqueOccZones)
  rm(occZones)
  rm(globZones)
  rm(spData)
  rm(backPts)
} else {
  
  zCounter <- 1
  
  for (zone in uniqueOccZones) {
    backFile <- paste(backFilesDir, "//backsamples_z", zone, ".csv", sep="")
    backPts <- read.csv(backFile)
    
    if (zCounter == 1) {
      backPoints <- backPts
      rm(backPts)
    } else {
      backPoints <- rbind(backPoints, backPts)
      rm(backPts)
    }
    
    selPts <- sample(1:nrow(backPoints), 10000)
    finalBackPts <- backPoints[selPts,]
    
    outBackName <- paste(inputDir, "//background//BackgroundSamplePoints_1.csv", sep="")
    out <- write.csv(backPoints, outBackName, quote=F)
    
  }
}

