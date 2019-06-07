#!/bin/bash -l

#SBATCH --partition=workq
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8G
#SBATCH --time=01:00:00
#SBATCH --account=pawsey0106
#SBATCH --export=NONE
#SBATCH -J dask-worker   # name
#SBATCH -o dask-worker-%J.out

module load shifter

# calculate task memory limit
mempcpu=$SLURM_MEM_PER_CPU
memlim=$(echo $SLURM_CPUS_PER_TASK*$mempcpu*0.95 | bc)

echo Memory limit is $memlim

srun --export=ALL -n $SLURM_NTASKS -c $SLURM_CPUS_PER_TASK \ 
    shifter run --writable-volatile=/run \
    pangeo/pangeo-notebook \   
    dask-worker --scheduler-file $MYSCRATCH/scheduler.json \
                --nthreads $SLURM_CPUS_PER_TASK \
                --memory-limit ${memlim}M
                   
  

