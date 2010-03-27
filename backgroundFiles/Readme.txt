These files contain the random background on each of the continents. The .csv files contain the longitude and latitude (x,y) values of each of the continents, whilst the .zip files contain ascii raster files each corresponding to one continent as follows:

Z1 North America incl. Greenland
Z2 Latin America
Z3 Europe incl. Russia
Z4 Asia
Z5 Africa
Z6 Australia and New Zealand

The backselection.zip file is global and contains values for each pixel according to the zone (from 1 to 6 corresponding to the zones above). The sampling was done in geographic coordinates, so, northern zones (i.e. close to the poles) have the same proportion of random points than areas in the tropics.

To check out the files just paste this into the R console (an example to zone 1):

require(raster)
setwd("./species-modeling/trunk/backgroundFiles") #Change this according to your system files
unzip("z1_nam.zip", files="z1_nam.asc", exdir=".")
rs <- raster("z1_nam.asc")
data <- read.csv("backsamples_z1.csv")

plot(rs)
points(data$x, data$y, pch=20, col='blue')