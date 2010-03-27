this is where all scripts will be hosted to be run on the HPC

Psuedo-code:

1. create backgrounds specific for different continents
2. convert future scenarios from climgen ascii or netcdf files to inputs for maxent
3. cycle through each species...
	a. creating cross-validated models
	b. summarizing models ... extracting thresholds / model stats / etc.
	c. projecting onto all future scenarios
	d. create buffer for clipping based on buffereing convex hull around points within each continent
4. summarize individual model outputs creating
	a. summary tables
	b. pdfs of future predictions
5. create summary species richness information


Deadlines:
- for 1,2 & 3, April 15
- for 4 & 5, April 30

Needed:
- cleaned occurrences from Julian
- continent shapefile
- awk file for converting climgen scenarios