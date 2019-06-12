#!/bin/bash -l

#SBATCH --partition=workq
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4G
#SBATCH --time=08:00:00
#SBATCH --account=pawsey0106
#SBATCH --export=NONE
#SBATCH -J dask-worker   # name
#SBATCH -o dask-worker-%J.out

module load shifter

# calculate task memory limit
mempcpu=$SLURM_MEM_PER_CPU
memlim=$(echo $SLURM_CPUS_PER_TASK*$mempcpu*0.95 | bc)
container=pangeo/pangeo-notebook:latest

echo Memory limit is $memlim

for i in 0 .. $SLURM_NTASKS
do
    echo starting worker $i
    srun --export=ALL -n 1 -c $SLURM_CPUS_PER_TASK \ 
        shifter --volume=/home/$USER:/home/jovyan --writable-volatile=/run --image=$container \
        dask-worker --scheduler-file $MYSCRATCH/scheduler.json \
                    --nthreads $SLURM_CPUS_PER_TASK \
                    --memory-limit ${memlim}M &
#                    --memory-spill-fraction False \
#                    --memory-target-fraction False &
    sleep 10
done

echo started workers

sleep inf
                   
  

