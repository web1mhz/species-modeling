#define the size of the nodes
nspp = 50 #nspp / cpu

#define & set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs/'; setwd(work.dir)

#list the species for which we have occurrences
occur.dir = '/homes/31/jc165798/working/Wallace.Initiative/training.data/individual.spp.00.script/'
species = list.files(occur.dir,pattern='\\.sh')

#now cycle through and submit the 2 cpu jobs
num.jobs.to.submit = ceiling(length(species) / (2*nspp))
cnt = 1 #model list number being worked on
for (ii in 1:num.jobs.to.submit) {
	cat(cnt,'\n')
	tfile = paste('run',sprintf('%05i',cnt),'.sh',sep='')
	zz = file(tfile,'w')
		cat('mkdir /tmp/proj/ \n',sep="",file=zz)
		cat('cp -af /homes/31/jc165798/working/Wallace.Initiative/projecting.data/* /tmp/proj/ \n',sep="",file=zz)
		cat(' \n',sep="",file=zz)
		
		for (jj in 1:(nspp*2)) {
			if (cnt>length(species)) { break }
			cat('bash -x ',occur.dir,species[cnt],' & \n',sep="",file=zz)
			cnt = cnt + 1
			if ((cnt-1) %% 2 == 0) cat('wait \n\n',sep="",file=zz) #add a wait after each 8 commands
		}
	#close the file
	close(zz)
	#submit the job
	system(paste('qsub -l nodes=1:ppn=2 ',tfile,' ',sep=''))
	system('sleep 0.5')
}
