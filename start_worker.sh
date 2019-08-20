#!/bin/bash -l

#SBATCH --partition=workq
#SBATCH --ntasks=10
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=6G
#SBATCH --time=2:00:00
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

echo starting $SLURM_NTASKS workers with $SLURM_CPUS_PER_TASK CPUs each

srun --export=ALL -n $SLURM_NTASKS -c $SLURM_CPUS_PER_TASK \
shifter run --writable-volatile=/run --mount=type=per-node-cache,destination=/tmp_file,size=4G,bs=1 $container \
dask-worker --scheduler-file $MYSCRATCH/scheduler.json --nthreads $SLURM_CPUS_PER_TASK --memory-limit ${memlim}M --local-directory=/tmp_file
    
