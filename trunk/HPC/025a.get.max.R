library(SDMTools)
tfile = list.files(,pattern='\\.asc')[1]; #cat(tfile)
tmax = max(as.vector(read.asc(tfile)),na.rm=TRUE); #cat(tmax)
cat(tmax,'\n',sep='',file=file('max.dat','w'))

