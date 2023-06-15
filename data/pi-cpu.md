# Pi calculator

Welcome!

Pi calculator is a program that calculates $\pi$ using a monte-carlo approach.

CPU versions are written in Fortran. GPU version is written in C (with CUDA).

## Algorithm

<img src="https://felixdmr.com/post-assets/2020-09-20-pi-from-monte-carlo/banner.png">

$\pi$ is calculated by generating 2D coordinates with random real values between
0 and 1. The number of points within the circle of radius 1 is divided by the
total number of points generated. This number is multiplied by 4 to obtain an
estimate of $\pi$.

## Usage

`pi-cpu` is a pre-compiled binary for multi-threaded calculations of $\pi$.

`pi-cpu-mpi` uses MPI to enable calculations that use CPUs across node boundaries.

`pi-gpu` makes use of NVIDIA GPUs to calculate $\pi$. Can use as many GPUs as
there are detected on the system.

### General options

`-r, --reps`: The number of times to estimate $\pi$. Pass `-1` to
calculate $\pi$ indefinitely.

`-n, --trials`: Number of points to use to estimate $\pi$.

### Multi-threading

Make use of multiple threads by running `pi-cpu` with `-p` or `--parallel` and
pass the number of threads you wish to use e.g.

```bash
./pi-cpu -p 2
```

will execute `pi-cpu` with two threads. The number of trials used will be
divided amongst the threads.

### Multi-node + multi-threading

Calculate $\pi$ across multiple nodes using `mpiexec`, or `srun` (for Slurm systems):

```bash
# execute pi-cpu-mpi with 2 MPI processes and 1 thread per process
mpiexec -n 2 ./pi-cpu-mpi
# OR
# execute pi-cpu-mpi with 2 MPI processes (across 2 nodes) and 32 threads per process
srun -N 2 -c 32 ./pi-cpu-mpi -p 32
```

### GPU

By default, `pi-gpu` will make use of GPU 0. Use the `-p` option to make use of
more GPUs

```bash
./pi-gpu -p 3
```

asks `pi-gpu` to try to make use of 3 GPUs if they are available on the system.
