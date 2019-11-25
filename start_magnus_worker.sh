#!/bin/bash -l

#SBATCH --partition=workq
#SBATCH --ntasks=2
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=47G
#SBATCH --time=02:00:00
#SBATCH --account=pawsey0106
#SBATCH --export=NONE
#SBATCH -J dask-worker   # name
#SBATCH -o dask-worker-%J.out

module load shifter
container=pangeo/pangeo-notebook:latest

# calculate task memory limit
mempcpu=$((SLURM_MEM_PER_NODE/SLURM_JOB_CPUS_PER_NODE))
SLURM_CPUS_PER_TASK=12
memlim=23500
numworkers=$SLURM_NTASKS

echo Worker memory limit is $memlim
echo Starting $numworkers workers

srun --export=all -n $numworkers -c $SLURM_CPUS_PER_TASK \
shifter run --writable-volatile=/run --mount=type=per-node-cache,destination=/tmp_file,size=40G,bs=1 $container \
dask-worker --scheduler-file $MYSCRATCH/scheduler.json \
                --nthreads $SLURM_CPUS_PER_TASK \
                --local-directory /tmp_file \
                --memory-limit ${memlim}M
