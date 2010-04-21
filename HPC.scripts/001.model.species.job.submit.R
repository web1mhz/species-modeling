#define the size of the nodes
nspp = 500 #nspp / cpu

#define & set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs/'; setwd(work.dir)

#define the model directory
model.dir = '/homes/31/jc165798/working/Wallace.Initiative/models/'; model.list = NULL
for (tdir in list.files(model.dir)) model.list = c(model.list,list.files(paste(model.dir,tdir,sep=''),full.names=T))
model.list = paste(model.list,'/occur.csv',sep='')

#save out the list of files
save(model.list,file='model.list.Rdata')

#define the number of bins for running the sh scripts
bins = seq(1,length(model.list),nspp)

#cycle through and submit the jobs
for (ii in 1:length(bins)) {
	#define the subset of lines for this shell script
	if (!ii == length(bins)) { nmin = bins[ii];nmax = bins[ii+1] } else { nmin = bins[ii];nmax = length(model.list) }
	#create the shell script
	zz = file(paste('prep',sprintf('%05i',nmin),'.sh',sep=''),'w')
		cat("R CMD BATCH '",'--args lines.of.interest=',nmin,":",nmax,"'",' /homes/31/jc165798/working/Wallace.Initiative/scripts/HPC.scripts/001.model.species.R ',work.dir,'prep',sprintf('%05i',nmin),'.Rout --no-save \n',sep="",file=zz)
  
	#close the file
	close(zz)
	#submit the job
	system(paste('qsub -l nodes=1:ppn=1 -z prep',sprintf('%05i',nmin),'.sh',sep=''))
	system('sleep 0.2')
}
