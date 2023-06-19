---
title: "Monitoring a Jobs performance"
teaching: 10
exercises: 2
editor_options: 
  markdown: 
    wrap: 72
---

::: questions
-   Why should I learn to monitor performance of my Slurm jobs?
-   Which tools can I use to monitor my jobs' activity?
:::

::: objectives
-   Understand why jobs should be monitored carefully.
-   Show common tools to use to monitor jobs' activity and performance.
-   Demonstrate a general procedure to investigate why a job may not be performing as expected.
:::

## Calculating $\pi$

You're an honours student and your project is looking at ways of calculating $\pi$.
Your PI has recommended using an existing piece of software he saw someone talk
about at a conference recently. A useful feature is that it works in parallel,
and is consequently quite fast! You try running the program on your laptop, and
it takes about 1.2 seconds for each calculation of $\pi$. This is a little slow, so
you try running it on Milton

::: challenge

### Running the Program

In the example-programs.zip file, is the `pi-cpu` executable. This is the program
your supervisor has recommended. **Try running it with `srun` on Milton!** 
Does it perform each calculation of $\pi$ in less time than 1.2s?
:::::::::::::

::: solution
```bash
srun pi-cpu
```
```output
srun: job 11087600 queued and waiting for resources
srun: job 11087600 has been allocated resources
Result: 3.1414796637875 Error: -0.0001130772251 Time: 3.0970s
Result: 3.1417489401899 Error:  0.0001561991773 Time: 3.0912s
Result: 3.1415377569880 Error: -0.0000549840246 Time: 3.1001s
...
```
Each calculation of $\pi$ takes about 3 seconds - *slower* than your laptop!
This is something to remember about HPC: The main reason why HPC
is "faster" is because it has *many* CPU cores, but the cores working individually
are probably slower than your PC's CPU cores. HPC's usefulness comes from hundreds or thousands of CPU
cores working in parallel!
::::::::::::

You tell your supervisor that HPC isn't helping! But they assure you that it should be really fast - 
the presenter at the conference demonstrated times way less than 3 seconds!

Your job now is to figure out why `pi-cpu` isn't performing fast for you.

## Check 1: Is it really working in parallel?

So far, we've only *heard* that the software works by performing computations in
parallel with multiple CPUs. One way we can verify this is with the `htop` tool.

`htop` is an interactive "process" viewer that lets you monitor processes across
the entire node. It's very similar to Task Manager on Windows or Activity Monitor
on Macs, but it works from the command line!

### Interpreting `htop`'s output

Try running `htop` on the login node. You should get something similar to below:

![Screenshot of `htop` output](fig/htop-screenshot.png)

`htop` gives a lot of information, so here is a quick explainer on what is being
shown. 

At the top of the `htop` output, you'll see multiple bars and each bar tells you
the activity level of a single CPU core. If a bar is at 100%, then that means that
that CPU core is completely busy.

![CPU utilization bars from `htop`](fig/htop-screenshot-cpubars.png)

Below the bar, on the left side, is another bar which tells you how much of the
node's memory is occupied. Next to the bar is information about how much load
the node is under.

![Memory utilization bars and load from `htop`](fig/htop-screenshot-memload.png)

Everything below that is most important to monitoring your jobs. That table is a
dynamic list of "processes" running on the node. And each column tells you a bit
of different information about the process.

![Process list and fields from `htop`](fig/htop-screenshot-procs.png)

1. `RES` tells you the "resident" memory of the process, i.e., the memory (in bytes) being used by the process.
2. `CPU%` is the percentage of a CPU core the process is using.
3. `Command` is telling you the command the process is running. This can be used to help you figure out which processes are related to your job.

By default, `htop` will show you *everyone's* processes, which is not relevant
to us. To get only your processes, quit `htop` by pressing `q`, and run it again with

```bash
htop -u $USER
```

You should see a list of processes that belong to you only!

### Monitoring `pi-cpu` with `htop`

This time, we're going to submit the `pi-cpu` command as a job with `sbatch`. 
We're also going to add the `-r -1` flag and value, so that the program will run
indefinitely. We can do so by

```bash
sbatch --wrap="srun ./pi-cpu -r -1"
```

::: instructor

You might get questions as to why `srun` should be used. In many cases it's not
important, but `srun` helps Slurm collect CPU efficiency, memory usage, and IO
data about the command it's being used to run. Which is important for this
purpose!

The most beneficial aspect of using `srun` inside `sbatch` is that if the job
fails or is cancelled, the CPU efficiency, memory usage, and IO data is saved,
which makes `seff` and `sacct` still useful. If `srun` is not used, performance
data from `seff` and `sacct` are useless if the job ends prematurely.

::::::::::::::

::: discussion

### `sbatch --wrap`

the `--wrap` option lets us pass a singular command to `sbatch` without having to write
an entire script! This is useful for debugging and when you run `sbatch` inside scripts.
:::::::::::

Once you've confirmed the job has started with `squeue`, and determined which
node it's running on, `ssh` to that node and run `htop -u $USER`. 

```bash
sbatch --wrap="srun ./pi-cpu -r -1"
```
```output
Submitted batch job 11088927
```
```bash
squeue -u $USER
```
```output
     JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
  11088927   regular     wrap   yang.e  R       0:12      1 sml-n15
```
```bash   
ssh sml-n15
```
```output
yang.e@sml-n15s password: # enter your password
Last login: Fri Apr 14 14:40:38 2023 from slurm-login.hpc.wehi.edu.au
```
```bash
htop -u $USER
```
![processes associated with `pi-cpu`](fig/htop-picpu-1.png)


From the `Command` column, you can find the relevant data for your job. 

Hint: You can click on `CPU%` to sort processes by their CPU usage.

::: instructor

You may wish to explain how to distinguish processes of interest from system
processes. Usually, the process of interest will be identifiable by the command
that is being run.

::::::::::::::

If we look at the `CPU%` column, we can see that the `pi-cpu` process is using
100%! That might sound good, but the percentage is the percentage of a CPU *core*
being used, i.e., 100% means that 100% of a single CPU core is being used, or 200% means
100% of two CPU core are being used. So, the `pi-cpu` process is only using 1 CPU core i.e.,
not parallel! This is not what your PI promised!

But maybe it's because we didn't request more CPUs? We didn't ask for any
specific number of CPUs in our command after all. Let's try request 4 CPUs
instead. But first, let's cancel the already running job.

```bash
scancel 11088927
```

And then we can try again, but with more CPUs:
```bash
sbatch --cpus-per-task=4 --wrap="srun ./pi-cpu -r -1"
```
```output
Submitted batch job 11089020
```
```bash
squeue -u $USER
```
```output
   JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
11089020   regular     wrap   yang.e  R       0:12      1 sml-n15
```
```bash
ssh sml-n15
```
```output
yang.e@sml-n15s password: # enter your password
Last login: Fri Apr 14 14:40:38 2023 from slurm-login.hpc.wehi.edu.au
```
```bash
htop -u $USER
```

![processes associated with `pi-cpu` after requesting more CPUs from Slurm](fig/htop-picpu-2.png)

Unfortunately, the `pi-cpu` program is still only using 100% - requesting more CPUs from Slurm didn't help your job work in parallel.

Now, this job runs forever, so we should cancel it and move on.
```bash
scancel 11089020
```

::: challenge

### Job summary with `seff`

Now that the job is over, try verifying the efficiency of the job with `seff`.
What is the CPU Efficiency (%) that the `pi-cpu` program achieved?

:::::::::::::

::: solution

```bash
seff 11089020
```
```output
Job ID: 11089020
Cluster: milton
User/Group: yang.e/allstaff
State: CANCELLED (exit code 0)
Nodes: 1
Cores per node: 4
CPU Utilized: 00:02:11
CPU Efficiency: 25.00% of 00:08:44 core-walltime
Job Wall-clock time: 00:02:11
Memory Utilized: 4.44 MB
Memory Efficiency: 11.10% of 40.00 MB
```

In this scenario, you're interested in the `CPU Efficiency` field, which gives
a rough indication of the total CPU cores requested being used. This is different from
`htop`, where the percentage represents the utilization of a single CPU core.
  
But as well as CPUs, jobs need to select an amount of memory to request. `seff`
can help tune this value with the `Memory Utilized` field, which will tell you
the maximum memory used of your job. The `Memoy Efficiency` percentage is also
useful to help you choose an appropriate memory to request.

`pi-cpu` turns out to be very lightweight, so doesn't use much memory at all!
When we run it inside a Slurm job without any options, it comfortably fits
within the default memory (for Milton, this is 10MB).

::::::::::::

## Looking through help and documentation

::: challenge

Try  running `pi-cpu` with the `--help` option. Do you find any clues? See if 
you can run the `pi-cpu` in parallel with 4 cores on Slurm!

:::::::::::::

::: solution

Both the documentation and `--help` output would've shown that the `-p <N>` option
is needed to execute the code with `N` number of cores.

So, to execute `pi-cpu` with 4 cores on Slurm, we can issue the command
```bash
srun --cpus-per-task=4 pi-cpu -p 4 
```
```output
srun: job 11250525 queued and waiting for resources
srun: job 11250525 has been allocated resources
Result: 3.1418360637907 Error:  0.0002433227781 Time: 1.4548s
Result: 3.1416882225894 Error:  0.0000954815768 Time: 1.4527s
Result: 3.1415296893879 Error: -0.0000630516247 Time: 1.4512s
...
```
which will send the output straight to the terminal. You will notice that the
reported times to calculate `pi-cpu` has more than halved! We can confirm the
utilization of the 4 CPUs we requested with `seff`:
```bash
seff 11250525
```
```output
Job ID: 11250525
Cluster: milton
User/Group: yang.e/allstaff
State: CANCELLED (exit code 0)
Nodes: 2
Cores per node: 2
CPU Utilized: 00:02:47
CPU Efficiency: 97.09% of 00:02:52 core-walltime
Job Wall-clock time: 00:00:43
Memory Utilized: 9.56 MB (estimated maximum)
Memory Efficiency: 23.91% of 40.00 MB (10.00 MB/core)
```

The CPU Efficiency is now pretty close to 100%!

Many programs behave like this: they will have parallel capability built in,
but will need to be switched on perhaps with a flag/option like with `pi-cpu`.
Sometimes it can also be switched on via an environment variable.

Parallel programs are generally designed to run in this way so that the parallel
program doesn't unintentionally use up all the resources on the machine you're
running on.

::::::::::::

::: instructor

The output from the last challenge may suggest to learners that using 4 CPUs
only results in a 2 times speedup, but this result is due to hyperthreading
being enabled on Milton, and when you request 2 CPUs from Slurm, you get
2 hyperthreads which are both assigned to the same physical CPU core.

::::::::::::::

::: challenge

### Using more CPU cores

You're really determined to get the run-time down on this calculation of $\pi$!
So, try request different number of CPUs and see what happens with the time it
takes to calculate $\pi$!

Hint: try 4, 8, and then 16 CPUs.
Hint 2: You may wish to run with `--constraint=Icelake` to ensure results are consistent!

:::::::::::::

::: solution

```bash
srun --cpus-per-task=4 --constraint=Icelake pi-cpu -p 4
```
```output
srun: job 11250526 queued and waiting for resources
srun: job 11250526 has been allocated resources
Result: 3.1414069905868 Error: -0.0001857504258 Time: 1.1907s
Result: 3.1416068013886 Error:  0.0000140603760 Time: 1.1880s
Result: 3.1415671113883 Error: -0.0000256296243 Time: 1.1880s
...
```
```bash
srun --cpus-per-task=8 --constraint=Icelake pi-cpu -p 8
```
```output
srun: job 11250527 queued and waiting for resources
srun: job 11250527 has been allocated resources
Result: 3.1416164241887 Error:  0.0000236831761 Time: 0.5980s
Result: 3.1414225749869 Error: -0.0001701660256 Time: 0.5975s
Result: 3.1417783593902 Error:  0.0001856183776 Time: 0.5978s   
...
```
```bash
srun --cpus-per-task=16 --constraint=Icelake pi-cpu -p 16
```
```output
srun: job 11250528 queued and waiting for resources
srun: job 11250528 has been allocated resources
Result: 3.1419777489920 Error:  0.0003850079794 Time: 0.3507s
Result: 3.1415083701877 Error: -0.0000843708248 Time: 0.3018s
Result: 3.1418214513906 Error:  0.0002287103780 Time: 0.3016s 
...
```

If you're running on Milton, you should see that 4 CPUs brings down the time
to 2 seconds, down from the original 6 seconds. Running with 8 CPUs brings the
time down to approx. 1 second (approx 2 times speedup, relative to 4 cores), and bringing it up to 16
speeds things up almost twice again!

However, this isn't always true of all programs. Often, adding twice the number of
cores doesn't add twice the speed.

In many cases, the program's documentation will offer some suggestions on how to choose the
right number of cores. You might even find some advice from others e.g., blog posts or in
forums. But if this isn't the case, you may need to perform some tests yourself!

For example, I run a program with two cores and I discover it's 1.8 times
faster than one core. I then run the same program but with 4 cores and find that
it's only 2.5 times as fast compared to one core. We could say that with two
cores, the program has a "scaling efficiency" of 1.8/2 = 90% efficient. But, the
four core case is 2.5/4 = 62.5% efficient. This would tell us that running with
two cores is *more efficient*, and running with four cores is *less efficient*, but *faster*.

::::::::::::

::: challenge

### Hyperthreading

Do a rough calculation of the speedup efficiency of `pi-cpu` from one core to two.

i.e.,

`srun --constraint=Icelake pi-cpu -p 1`

and then

`srun --cpus-per-task=2 --constraint=Icelake pi-cpu -p 2`

What do you get?

What happens if you run the two-core case again, but this time requesting 4 cores
from Slurm, but still using `-p 2`?

:::::::::::::

::: solution
  
Comparing 1 CPU with 2 CPUs:

```bash
srun --constraint=Icelake pi-cpu -p 1
```
```output
srun: job 11783722 queued and waiting for resources
srun: job 11783722 has been allocated resources
Result: 3.1419098061914 Error:  0.0003170651788 Time: 3.6352s
Result: 3.1415063289877 Error: -0.0000864120249 Time: 3.6363s
Result: 3.1416112401887 Error:  0.0000184991761 Time: 3.6349s
...
```
```bash
srun --cpus-per-task=2 --constraint=Icelake pi-cpu -p 2
```
```output
srun: job 11783726 queued and waiting for resources
srun: job 11783726 has been allocated resources
Result: 3.1416992061895 Error:  0.0001064651769 Time: 2.3672s
Result: 3.1415531793881 Error: -0.0000395616244 Time: 2.3669s
Result: 3.1416117585887 Error:  0.0000190175761 Time: 2.3668s
...
```

This is approximately 6/(4.28*2) = 70%. Unfortunately not as close to 100% as
one might hope!

Requesting 4 CPUs from Slurm, but running `pi-cpu -p 2`:

```bash
srun --cpus-per-task=4 --constraint=Icelake pi-cpu -p 2
```
```output
srun: job 11783729 queued and waiting for resources
srun: job 11783729 has been allocated resources
Result: 3.1413841485866 Error: -0.0002085924260 Time: 1.7224s
Result: 3.1414291845870 Error: -0.0001635564256 Time: 1.7210s
Result: 3.1414952805876 Error: -0.0000974604250 Time: 1.7257s 
...
```

Which is now roughly 2.05 times faster than the one-core case! But why the
difference? In both cases, we requested `pi-cpu` to run in parallel with 2 cores right (through the `-p 2` flag)?

This is because on Milton, hyperthreading is turned on, which is often the case
for modern CPUs. Milton's Slurm is configured such that when you request 1
CPU, you're actually getting a hyperthread. For every two hyperthreads, you get 
one physical CPU core.

So, when you execute `srun --cpus-per-task=2 pi-cpu -p 2`, `pi-cpu -p 2` is 
actually executed on a single physical core. But thanks to hyperthreading, you
manage to get some speedup almost for free! When you execute `srun --cpus-per-task=4 pi-cpu 2`,
`pi-cpu` is now running on two seperate physical cores, hence we see a speedup!

This is important to remember because if you forget about how Slurm CPUs are
equivalent to hyperthreads, rather than physical CPU cores, programs that run
in parallel might appear less efficient (like in the case of `pi-cpu`!).

NOTE: this configuration is unique to Milton. Most other HPC facilities equate
Slurm CPUs to physical CPU cores, not hypertheads.

:::::::::::::

::: challenge

### Using multiple nodes

You may already be aware of the fact that you can request *multiple nodes* from Slurm.
Maybe we can use multiple nodes to speed up the calculation of $\pi$ more! Let's try
and run `pi-cpu` on 2 nodes, with 2 CPUs per node, which gives our
job a total request of 4 CPUs. Remember to add the constraint so we can compare
the times to the previous tests!

We will submit this job using `srun`:
```bash
srun --nodes=2 --cpus-per-task=2 --constraint=Icelake pi-cpu -p 4 
```
```output
srun: job 11250605 queued and waiting for resources
srun: job 11250605 has been allocated resources
Result: 3.1414471989872 Error: -0.0001455420254 Time: 2.3712s
Result: 3.1417839645902 Error:  0.0001912235777 Time: 2.3745s
Result: 3.1416039501886 Error:  0.0000112091760 Time: 2.3709s
Result: 3.1415633529882 Error: -0.0000293880243 Time: 2.3729s
Result: 3.1415167617878 Error: -0.0000759792248 Time: 2.3712s
Result: 3.1415245053879 Error: -0.0000682356247 Time: 2.3709s
...
```
So our job has started, but wait... The run times are *slower* than our previous
tests with 4 cores! You might also notice that two lines with identical results
are printed together every iteration.

Try and have a look in the [documentation](https://github.com/WEHI-ResearchComputing/Workshop-intermediate-slurm/blob/main/episodes/data/pi-cpu.md) again and see why
that might be!

:::::::::::::

::: solution

in the [multi-node](https://github.com/WEHI-ResearchComputing/Workshop-intermediate-slurm/blob/main/episodes/data/pi-cpu.md#multi-node--multi-threading) 
section, you will find that to run the program across nodes, you will

1. need to use the `pi-cpu-mpi` program
2. use `srun` or `mpiexec` to execute the program
3. ensure the value passed to the `-p` flag is the number of CPUs per node.

We've been using `srun` so far, so we only need to change the program. We also
need to change the number after `-p`:
```bash
srun --nodes=2 --cpus-per-task=2 --constraint=Icelake pi-cpu-mpi -p 2 
```
```output
srun: job 11250610 queued and waiting for resources
srun: job 11250610 has been allocated resources
Result: 3.1414385805871 Error: -0.0001541604255 Time: 1.2036s
Result: 3.1417610577900 Error:  0.0001683167775 Time: 1.2036s
Result: 3.1415069445877 Error: -0.0000857964249 Time: 1.2029s 
...
```
And we can see that the program is now calculating $\pi$ in approximately the same
time as the single-node 4-core example before. 

This is because *programs are generally unable to work across nodes by default*.
They typically require some other framework, with special instructions on how
to run the software. This will often be explained in the documentation.

Message Passing Interface (MPI) is common in scientific computing - particularly
when it comes to simulation like for Molecular Dynamics and *distributed* machine
learning (e.g., PyTorch), but other distributed computing frameworks exist, like Spark + Hadoop.

::::::::::::

::: instructor

With regard to the last exercise, you may wish to highlight what happens when
you try to run a program inside `sbatch`, requesting multiple nodes, but executing
the program without `srun`.

The result is that one node will do all the work, and any other nodes requested
will be idle. Whereas with `srun`, multiple copies of the program will be started.

::::::::::::::

::: keypoints

-   Requesting more resources from Slurm doesn't mean your job knows how to use them!
    - Many programs don't work in parallel by default - either that functionality doesn't exist, or needs to be turned on!
    - Parallelism across nodes is differently parallelism within nodes. You usually need to run them a little differently than a normal program
-   The `htop` system tool is a great way to get live information about how effective your job is
-   `seff` and `sacct` can be used to get summary stats about jobs
-   More CPUs doesn't always mean an equivalent speedup!

:::
