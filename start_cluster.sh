#!/bin/bash -l

#SBATCH --partition=workq
#SBATCH --ntasks=7
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4000M
#SBATCH --nodes=1
##SBATCH --mem=60G
#SBATCH --time=01:00:00
#SBATCH --account=pawsey0106
#SBATCH --export=NONE
#SBATCH -J cluster   # name
#SBATCH -o cluster-%J.out

module load shifter
container=pangeo/pangeo-notebook:latest

JNHOST=$(hostname)

# Pull the container with the next line before submitting
#sg $PAWSEY_PROJECT -c 'shifter pull $container'

srun --export=ALL -n 1 -c $SLURM_CPUS_PER_TASK shifter --volume=/home/$USER:/home/jovyan --writable-volatile=/run --image=$container \
       dask-scheduler --scheduler-file $MYSCRATCH/scheduler.json &

# Create trap to kill notebook when user is done
kill_server() {
    if [[ $JNPID != -1 ]]; then
        echo -en "\nKilling Jupyter Notebook Server with PID=$JNPID ... "
        kill $JNPID
        echo "done"
        exit 0
    else
        exit 1
    fi
}

let DASK_PORT=8787
let LOCALHOST_PORT=8888

JNHOST=$(hostname)
JNIP=$(hostname -i)

LOGFILE=$MYSCRATCH/pangeo_jupyter_log.$(date +%Y%m%dT%H%M%S)


echo "Logging jupyter notebook session on $JNHOST to $LOGFILE"

srun --export=ALL -n 1 -c $SLURM_CPUS_PER_TASK shifter --volume=/home/$USER:/home/jovyan --writable-volatile=/run --image=$container \
   jupyter lab --no-browser --ip=$JNHOST >& $LOGFILE &

JNPID=$!

echo -en "\nStarting jupyter notebook server, please wait ... "

ELAPSED=0
ADDRESS=

while [[ $ADDRESS != *"${JNHOST}"* ]]; do
    sleep 1
    ELAPSED=$(($ELAPSED+1))
    ADDRESS=$(grep -e '^\[.*\]\s*http://.*:.*/\?token=.*' $LOGFILE | head -n 1 | awk -F'//' '{print $NF}')
    if [[ $ELAPSED -gt 360 ]]; then
        echo -e "something went wrong\n---"
        cat $LOGFILE
        echo "---"
        kill_server
    fi
done

echo -e "done\n---\n"

HOST=$(echo $ADDRESS | awk -F':' ' { print $1 } ')
PORT=$(echo $ADDRESS | awk -F':' ' { print $2 } ' | awk -F'/' ' { print $1 } ')
TOKEN=$(echo $ADDRESS | awk -F'=' ' { print $NF } ')

cat << EOF
Run the following command on your desktop or laptop:
    ssh -N -l $USER -L ${LOCALHOST_PORT}:${JNHOST}:$PORT zeus.pawsey.org.au
Log in with your Username/Password or SSH keys.
Then open a browser and go to http://localhost:${LOCALHOST_PORT}. The Jupyter web
interface will ask you for a token. Use the following:
    $TOKEN
Note that anyone to whom you give the token can access (and modify/delete)
files in your PAWSEY spaces, regardless of the file permissions you
have set. SHARE TOKENS RARELY AND WISELY!
To stop the server, press Ctrl-C.
EOF

mempcpu=$SLURM_MEM_PER_CPU
mempcpu=2500
memlim=$(echo $SLURM_CPUS_PER_TASK*$mempcpu*0.95 | bc)
numworkers=$((SLURM_NTASKS-2))

echo Worker memory limit is $memlim
echo Starting $numworkers workers

srun --export=ALL -n $numworkers -c $SLURM_CPUS_PER_TASK \
    shifter --volume=/home/$USER:/home/jovyan --writable-volatile=/run --image=$container \
    dask-worker --scheduler-file $MYSCRATCH/scheduler.json \
                --nthreads $SLURM_CPUS_PER_TASK \
                --memory-limit ${memlim}M &



# Wait for user kill command
sleep inf



