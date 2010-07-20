urlfiles = c('ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/InputOccurrenceData/amphibia.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/InputOccurrenceData/aves.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/InputOccurrenceData/mammalia.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/InputOccurrenceData/plantae.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/InputOccurrenceData/reptilia.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/ClimateData/20C3M.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/ClimateData/A1B_A16r2h.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/ClimateData/A1B_A16r4l.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/ClimateData/A1B_A16r5l.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/ClimateData/A1B_A30r2h.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/ClimateData/A1B_A30r5l.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/ClimateData/SRES_A1B.zip',
	'ftp://gisweb.ciat.cgiar.org/Agroecosystems/jramirez/WallaceInitiative/ClimateData/WorldClim_BioClim_5min.zip')

localfiles = c('amphibia.zip','aves.zip','mammalia.zip','plantae.zip','reptilia.zip','20C3M.zip','A1B_A16r2h.zip','A1B_A16r4l.zip','A1B_A16r5l.zip','A1B_A30r2h.zip','A1B_A30r5l.zip','SRES_A1B.zip','WorldClim_BioClim_5min.zip')

#set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/raw.files.20100417/'; setwd(work.dir)

#cycle through the dates
for (ii in 1:length(localfiles)) { try(download.file(url=urlfiles[ii], destfile=localfiles[ii], method='auto')) }

