################################################################################
#this is a script to batch process species distribution models on the hpc setup

#must run interactively on HPC

#script was written by Jeremy VanDerWal (jjvanderwal@gmail.com)

################################################################################
#set some constants

#set the working dir and output dir
work.dir = "/homes/31/jc165798/working/wallace/"; setwd(work.dir)
output.dir = paste(work.dir,'models/',sep='')
projection.dir = '/home1/31/jc165798/working/wallace/future/'

################################################################################
#do something
#get a list of the projection folders
project.list = list.files(projection.dir)

#get a list of all the species
species = list.files(output.dir)

#cycle through each of the species
for (spp in species) {
  #if a lambdas file exists, project it on the current projection file
  if (file.exists(paste(output.dir,spp,'/output/',spp,'.lambdas',sep=""))) {
    #id the species folder
    spp.folder = paste(output.dir,spp,"/",sep="")
    #create a pbs script
    z = file(paste(spp.folder,"02.projection_script.pbs",sep=""),"w")
      cat('#!/bin/bash\n',file=z)
      cat('#PBS -c s\n',file=z)
      cat('#PBS -j oe\n',file=z)
      cat('#PBS -m ae\n',file=z)
      cat('#PBS -N ',spp,'\n',sep="",file=z)
      cat('#PBS -M jc165798@jcu.edu.au\n',file=z)
      cat('#PBS -l walltime=9999:00:00\n',file=z)
      cat('#PBS -l nodes=1:ppn=2 \n',file=z)
      cat('echo "------------------------------------------------------"\n',file=z)
      cat('echo " This job is allocated 1 cpu on "\n',file=z)
      cat('cat $PBS_NODEFILE\n',file=z)
      cat('echo "------------------------------------------------------"\n',file=z)
      cat('echo "PBS: Submitted to $PBS_QUEUE@$PBS_O_HOST"\n',file=z)
      cat('echo "PBS: Working directory is $PBS_O_WORKDIR"\n',file=z)
      cat('echo "PBS: Job identifier is $PBS_JOBID"\n',file=z)
      cat('echo "PBS: Job name is $PBS_JOBNAME"\n',file=z)
      cat('echo "------------------------------------------------------"\n',file=z)
      cat('cd $PBS_O_WORKDIR\n',file=z)
      cat('\n',file=z)
      cat('#set the source for loading Java later\n',file=z)
      cat('source /etc/profile.d/modules.sh\n',file=z)
      cat('\n',file=z)
      cat('#load the java module\n',file=z)
      cat('module load java-sun\n',file=z)
      cat('\n',file=z)
      cat('#make a directory on the local drive for the work\n',file=z)
      cat('mkdir -p /tmp/',spp,'\n',sep = "",file=z)
      cat('\n',file=z)
      cat('#copy over the necessary files\n',file=z)
      cat('cp -af ',spp.folder,'output/',spp,'.lambdas /tmp/',spp,'/\n',sep = "",file=z)
      cat('cp -af ',work.dir,'maxent.jar /tmp/',spp,'/\n',sep = "",file=z)
      cat('\n',file=z)
      cat('#move to the local directory\n',file=z)
      cat('cd /tmp/',spp,'\n',sep="",file=z)
      cat('\n',file=z)
      cat('#project the models\n',file=z)
      #cycle through each of the projection files
      for (i in 1:length(project.list)) {
        cat('cp -af ',projection.dir,project.list[i],'/ /tmp/',spp,'/\n',sep = "",file=z)
        cat('java -cp maxent.jar density.Project /tmp/',spp,'/',spp,'.lambdas /tmp/',spp,'/',project.list[i],' /tmp/',spp,'/',project.list[i],'.asc fadebyclamping\n',sep="",file=z)
        cat('rm -rf ',project.list[i],'\n',sep="",file=z)
        cat('gzip -9 ',project.list[i],'_clamping.asc\n',sep="",file=z)
        cat('cp -af ',project.list[i],'_clamping.asc.gz ',spp.folder,'output/\n',sep = "",file=z)
        cat('rm -rf ',project.list[i],'_clamping.asc.gz\n',sep = "",file=z)
        cat('gzip -9 ',project.list[i],'.asc\n',sep="",file=z)
        cat('cp -af ',project.list[i],'.asc.gz ',spp.folder,'output/\n',sep = "",file=z)
        cat('rm -rf ',project.list[i],'.asc.gz\n',sep = "",file=z)
      }
      cat('\n',file=z)
      cat('#delete the local data\n',file=z)
      cat('cd .. ; rm -rf ',spp,'\n',sep="",file=z)
    close(z)

    #change the working directory and submit the pbs script
    setwd(spp.folder)
    system("qsub 02.projection_script.pbs")
    #reset the working directory
    setwd(work.dir)

  }
}  



