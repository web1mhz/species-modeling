require(raster)

#1. Load species data
#2. Extract climate data (4 variables for <=40 occurrences species, and 8 variables for all the others)
#3. Select background area
#4. Train the maxent model
#5. Getting the metrics of the species into a single file
#   5.1  Total number of samples
#   5.2  Training samples
#   5.3  Test samples
#   5.4  Training AUC
#   5.5  Test AUC
#   5.6  Rsquare (test and background)
#   5.7  Logistic deviation on test data
#   5.8  Root mean square difference on test data
#   5.9 Thresholds (7 different taken from Liu et al. 2005)
#6. Project maxent model into current
#7. Project maxent model into all future scenarios
#8. Create the buffer area (500km)
#9. Buffer the distributions
#10. Threshold the distributions
#11. Calculate and write presence/absence surfaces

#Initial stuff

inputDir <- "C://CIAT_work//GBIF_project//clampingTest"
backgroundDir <- "C://CIAT_work//GBIF_project//backgroundFiles"
inTrainClimDir <- paste(inputDir, "//5min_wcl_asciis", sep="") #"F://Clim_30s//5min_wcl_asciis"
inProjClimDir <- "C://CIAT_work//FAO_top50//climatic_DATA"
maxentApp <- "C://CIAT_work//GBIF_project//maxent332//maxent.jar"

###############################################################################################
###############################################################################################
#The buffer function
###############################################################################################
###############################################################################################

source("bufferSpecies.R")

###############################################################################################
###############################################################################################
# The extract environmental data function
###############################################################################################
###############################################################################################

source("extractClimate.R")

###############################################################################################
###############################################################################################
# The select background area function
###############################################################################################
###############################################################################################

source("selectBackgroundArea.R")

###############################################################################################
###############################################################################################
# The select background area function
###############################################################################################
###############################################################################################

source("getMetrics.R")

###############################################################################################
###############################################################################################
#Creating the big function
###############################################################################################
###############################################################################################

theEntireProcess <- function(spID) {
  
  cat("Taxon ", spID, "\n")
  
  #1. Load species data
  
  occFile <- paste(inputDir, "//occurrences//species_", spID, ".csv", sep="")
  
  if (file.exists(occFile)) {
    
    #1.1 Check the number of occurrences and define the list of layers accordingly
    
   inData <- read.csv(occFile)
   nOcc <- nrow(inData)
   
   if (nOcc <= 40) {
    layList <- c(1,4,12,15)
   } else {
    layList <- c(1,4,5,6,12,15,18,19)
   }
    
    #2. Extract environmental data for the species
    
    cat("Extracting climates for sample file \n")
    
    outFileName <- paste(inputDir, "//samples_with_data//species_", spID, "_swd.csv", sep="")
    outExtracted <- extractClimates(occFile, outFileName, inTrainClimDir, layers=layList)
    
    #3. Select background area
    
    backFile <- paste(inputDir, "//background//background_", spID, ".csv", sep="")
    backGround <- selectBack(occFile, backFile, backgroundDir)
    
    #3.1 Extracting environmental data for the background
    
    cat("Extracting climates for background file \n")
    
    backFileSwd <- paste(inputDir, "//background//background_", spID, "_swd.csv", sep="")
    outExtracted <- extractClimates(backFile, backFileSwd, inTrainClimDir, layers=layList)
    
    #4. Train the maxent model
    
    outFolder <- paste(inputDir, "//mxe_outputs", sep="")
    if (!file.exists(outFolder)) {
      dir.create(outFolder)
    }
    
    outName <- paste(outFolder, "//species_", spID, sep="")
    if (!file.exists(outName)) {
      dir.create(outName)
      dir.create(paste(outName, "//model", sep=""))
      dir.create(paste(outName, "//crossval", sep=""))
      dir.create(paste(outName, "//projections", sep=""))
      dir.create(paste(outName, "//metrics", sep=""))
    }
    
    cat("Fitting the model...\n")
    
    system(paste("java", "-mx512m", "-jar", maxentApp, "-s", outFileName, "-e", backFileSwd, "-o", paste(outName, "//model", sep=""), "-P", "-X", "0", "nowarnings", "-z"), wait=TRUE)
    
    cat("Crossvalidating the model...\n")
    
    system(paste("java", "-mx512m", "-jar", maxentApp, "-s", outFileName, "-e", backFileSwd, "-o", paste(outName, "//crossval", sep=""), "-P", "replicates=10", "replicatetype=crossvalidate", "nowarnings", "-z"), wait=TRUE)
    
    if (file.exists(paste(outName, "//model//species_", spID,".lambdas", sep=""))) {
      cat("Model done successfully!", "\n")
    } else {
      cat("Error in computing \n")
    }
    
    #5. Getting the metrics
    
    out <- getMetrics(paste(outName, "//crossval", sep=""), paste("species_", spID, sep=""), 10, paste(outName, "//model", sep=""), paste(outName, "//metrics", sep=""))
    
    #9. Create the buffer area
    
    bufferOutGrid <- paste(outName, "//projections//sp_", spID, "_buffer.asc", sep="")
    bfo <- createBuffers(occFile, bufferOutGrid, 500000, 0.5)
    bufferRaster <- raster(bufferOutGrid)
    
    #6. Projecting the model into worldclim
    
    outGrid <- paste(outName, "//projections//sp_", spID, "_5kmwcl", sep="")
    clampGrid <- paste(outName, "//projections//sp_", spID, "_5k_clampingmwcl", sep="")
    lambdaFile <- paste(outName, "//model//species_", spID, ".lambdas", sep="")
    
    system(paste("java", "-mx512m", "-cp", maxentApp, "density.Project", lambdaFile, inTrainClimDir, outGrid, "nowarnings", "fadebyclamping", "-r", "-a", "-z"), wait=TRUE)
    
    threshFile <- paste(outName, "//metrics//thresholds.csv", sep="")
    threshData <- read.csv(threshFile)
    
    system(paste("7za", "a", "-tzip", outGrid, paste(outGrid, ".asc", sep="")))
    system(paste("7za", "a", "-tzip", clampGrid, paste(clampGrid, ".asc", sep="")))
    file.remove(paste(outGrid, ".asc", sep=""))
    file.remove(paste(clampGrid, ".asc", sep=""))
    
    #7. Projecting the model into the 21 future scenarios
    
    projectionList <- c("baseline//1980s", "future//2020s//cccma_cgcm31", "future//2050s//cccma_cgcm31", "future//2080s//cccma_cgcm31", "future//2020s//csiro_mk30", "future//2050s//csiro_mk30", "future//2080s//csiro_mk30", "future//2020s//ipsl_cm4", "future//2050s//ipsl_cm4", "future//2080s//ipsl_cm4", "future//2020s//mpi_echam5", "future//2050s//mpi_echam5", "future//2080s//mpi_echam5", "future//2020s//ncar_ccsm30", "future//2050s//ncar_ccsm30", "future//2080s//ncar_ccsm30", "future//2020s//ukmo_hadcm3", "future//2050s//ukmo_hadcm3", "future//2080s//ukmo_hadcm3", "future//2020s//ukmo_hadgem1", "future//2050s//ukmo_hadgem1", "future//2080s//ukmo_hadgem1")
    
    cat("Projecting the model...", "\n")
    
    prjCount <- 1
    
    for (prj in projectionList) {
      
      cat("Performing ", prj, "\n")
      
      projLayers <- paste(inProjClimDir, "//", prj, sep="")
      
      suffix <- gsub("//", "_", prj)
      outGrid <- paste(outName, "//projections//sp_", spID, "_", suffix, sep="")
      
      lambdaFile <- paste(outName, "//model//species_", spID, ".lambdas", sep="")
      
      system(paste("java", "-mx512m", "-cp", maxentApp, "density.Project", lambdaFile, projLayers, outGrid, "nowarnings", "fadebyclamping", "-r", "-a", "-z"), wait=TRUE)
       
      thslds <- c("TenPercentile_1", "Prevalence_3", "FixedValue_5", "MaxTrainSensSpec_6", "EqualTrainSensSpec_8", "BalanceTrainOmission_10", "UpperLeftROC_12")
      
      prjRaster <- raster(paste(outName, "//projections//sp_", spID, "_", suffix, ".asc", sep=""))
      
      cat("Thresholding and buffering... \n")
      
      procThr <- 1
      for(thr in thslds) {
        
        theName <- strsplit(thr, "_")[[1]][1]
        thePos <- as.numeric(strsplit(thr, "_")[[1]][2])
          
        theVal <- threshData[1,thePos]
        
        #Multi threshold PA surfaces for baseline
        if (prjCount == 1) {
          cat("...", theName, "\n")
          
          theRaster <- prjRaster
          theRaster <- theRaster * bufferRaster
          
          theRaster[which(theRaster[] < theVal)] <- 0
    		  theRaster[which(theRaster[] != 0)] <- 1
    		  
    		  outRsName <- paste(outName, "//projections//sp_", spID, "_", suffix, "_", theName, ".asc", sep="")
    		  theRaster <- writeRaster(theRaster, outRsName, overwrite=T, format='ascii')
    		  rm(theRaster)
          
        } else {
        #Multi threshold PA surfaces for future scenarios (two mig. scenarios)
          
          #Null adaptation
          
          cat("...", theName, "\n")
          
          theRaster <- prjRaster
          theRaster <- theRaster * bufferRaster
          
          theRaster[which(theRaster[] < theVal)] <- 0
    		  theRaster[which(theRaster[] != 0)] <- 1
    		  
    		  outRsName <- paste(outName, "//projections//sp_", spID, "_", suffix, "_", theName, "_NullAdap.asc", sep="")
    		  theRaster <- writeRaster(theRaster, outRsName, overwrite=T, format='ascii')
    		  rm(theRaster)
    		  
    		  #Full adaptation
    		  
    		  theRaster <- prjRaster
    		  theRaster[which(theRaster[] < theVal)] <- 0
    		  theRaster[which(theRaster[] != 0)] <- 1
    		  
    		  outRsName <- paste(outName, "//projections//sp_", spID, "_", suffix, "_", theName, "_FullAdap.asc", sep="")
    		  theRaster <- writeRaster(theRaster, outRsName, overwrite=T, format='ascii')
    		  rm(theRaster)
        }
        procThr <- procThr + 1
      }
      
      if (file.exists(paste(outGrid, ".asc", sep=""))) {
        cat("Projection is OK!", "\n")
      } else {
        cat("Error in projecting", "\n")
      }
      
      rm(prjRaster)
      system(paste("7za", "a", "-tzip", paste(outName, "//projections//sp_", spID, "_", suffix, sep=""), paste(outName, "//projections//sp_", spID, "_", suffix, ".asc", sep="")))
      file.remove(paste(outName, "//projections//sp_", spID, "_", suffix, ".asc", sep=""))
      
      prjCount <- prjCount + 1
    }
    
    return("Done")
  } else {
    cat("The occurrence file does not exist! \n")
  }
}

for (sp in 40:41) {
  out <- theEntireProcess(sp)
}