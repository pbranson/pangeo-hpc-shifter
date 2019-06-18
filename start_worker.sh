#!/bin/bash -l

#SBATCH --partition=workq
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4G
#SBATCH --time=02:00:00
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

for i in `seq 1 $SLURM_NTASKS`;
do 
    echo starting worker $i
    srun --export=all -n $SLURM_NTASKS -N 1 -c $SLURM_CPUS_PER_TASK \ 
        shifter run --writable-volatile=/run --mount=type=per-node-cache,destination=/tmp,size=40G,bs=1 $container \
        dask-worker --scheduler-file $MYSCRATCH/scheduler.json \
                    --nthreads $SLURM_CPUS_PER_TASK \
                    --local-directory /tmp \
                    --memory-limit ${memlim}M &
    sleep 1
done

sleep inf
#                    --memory-spill-fraction False \
#                    --memory-target-fraction False &

                   
  

