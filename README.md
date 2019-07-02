# pangeo-hpc-shifter
Scripts to run dask and jupyter lab on Shifter using the pangeo-notebook image

The container is based on the pangeo-notebook image that is curated at https://github.com/pangeo-data/pangeo-stacks. 

Pawsey have recently written up some doco about using containers https://support.pawsey.org.au/documentation/display/US/Containers

Shifter (as opposed to Singularity) works directly on docker images and at Pawsey the mapping of the filesystesm is taken care of for you, which makes using shifter very convenient and works without modifying the image. (unlike when using singularity - see https://github.com/pbranson/pangeo-hpc-singularity). And you dont need to build the image, just pull it from docker.

This makes the syntax to start the container simpler, and doesnt require sudo at any point in the process, which is good when working on HPC. In addition it deals with the volatile files directly rather than having to bind a writable folder as in singularity. In addition you can mount a writeable "per-node-cache" into the container which is a single large file on the Lustre filesystem which can be used by dask-workers as a location to spill data when worker memory limits are exceeded. Because the lustre file system sees this as a single file, it doesnt adversely effect the filesystem. 

## Pull the container

Before running you need to pull the image from docker and register the Shifter container

```
sg $PAWSEY_PROJECT -c 'shifter pull pangeo/pangeo-notebook:latest'
```

## Running the containers
Two convenience scripts are provided for starting jupyter lab and dask.

### Start Jupyter and Dask Scheduler

`jobid=$(sbatch start_jupyter.sh | grep -o [0-9]*) && tail -F jupyter-$jobid.out`

`start_jupyter.sh` does three things:
 1. Starts an instance of the container running a dask-scheduler
 2. Starts an instance of the container running jupyter lab
 3. Parses the log files to print out a helpful string for tunneling to the port jupyter exposed on the compute node

### Start Dask Workers

`jobid=$(sbatch start_worker.sh | grep -o [0-9]*) && tail -F dask-worker-$jobid.out`

`start_worker.sh` uses the container to start dask workers, using the Slurm environment variables to determine the worker specs and memory. This is important to do otherwise dask starts workers that are based on the node specs rather than the job request. Run `sbatch start_worker.sh` a few times to get more workers or alter the slurm parameters.

## Connecting to Jupyter

Assuming you tunneled the port with a command like
`ssh -N -l $USERNAME -L 8888:z106:8888 zeus.pawsey.org.au`

Open the browser to http://localhost:8888/

Connect the dask scheduler with:
```
from dask.distributed import Client
client=Client(address='localhost:8786')
client
```
... and view the dask dashboard at http://localhost:8888/proxy/8787/status
