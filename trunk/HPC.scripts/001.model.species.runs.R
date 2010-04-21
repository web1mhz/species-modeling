#define the size of the nodes
nspp = 100 #nspp / cpu
n8cpu = 25 # number of 8 cpu nodes to use

#define & set the working directory
work.dir = '/homes/31/jc165798/working/Wallace.Initiative/tmp.pbs/'; setwd(work.dir)

#define the model directory
model.dir = '/homes/31/jc165798/working/Wallace.Initiative/models/'; model.list = NULL
for (tdir in list.files(model.dir)) model.list = c(model.list,list.files(paste(model.dir,tdir,sep=''),full.names=T))
model.list = paste(model.list,'/00.model.species.sh',sep='')

#cycle through and submit the 8 cpu jobs
cnt = 1 #model list number being worked on
for (ii in 1:n8cpu) {
	tfile = paste('run',sprintf('%05i',cnt),'.sh',sep='')
	zz = file(tfile,'w')
		for (jj in 1:(nspp*8)) {
			cat('bash -x ',model.list[cnt],' & \n',sep="",file=zz)
			cnt = cnt + 1
			if ((cnt-1) %% 8 == 0) cat('wait \n\n',sep="",file=zz) #add a wait after each 8 commands
		}
	#close the file
	close(zz)
	#submit the job
	system(paste('qsub -l nodes=1:ppn=8 -z ',tfile,' ',sep=''))
}

#now cycle through and submit the 2 cpu jobs
num.jobs.to.submit = ceiling((length(model.list)-cnt) / (2*nspp))
for (ii in 1:num.jobs.to.submit) {
	tfile = paste('run',sprintf('%05i',cnt),'.sh',sep='')
	zz = file(tfile,'w')
		for (jj in 1:(nspp*2)) {
			if (cnt>length(model.list)) { break }
			cat('bash -x ',model.list[cnt],' & \n',sep="",file=zz)
			cnt = cnt + 1
			if ((cnt-1) %% 2 == 0) cat('wait \n\n',sep="",file=zz) #add a wait after each 8 commands
		}
	#close the file
	close(zz)
	#submit the job
	system(paste('qsub -l nodes=1:ppn=2 -z ',tfile,' ',sep=''))
}
