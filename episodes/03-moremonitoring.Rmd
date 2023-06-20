---
title: "Memory and GPU utilization"
teaching: 10
exercises: 2
editor_options: 
  markdown: 
    wrap: 72
---

::: questions
-   How do I track how much memory my jobs are using?
-   How do I select an appropriate memory value for my Slurm job?
-   How can I monitor performance of jobs that use GPUs?
:::

::: objectives
-   Learn how to use `htop`, `seff`, and `sacct` to view memory usage
-   Learn how to use `nvidia-smi`, `nvtop`, and `dcgmstats` to query GPU activity
:::

## Investigating other implementations of the $\pi$ algorithm

Some time after your initial investigation, your supervisor shares that the
authors of the previous `pi-cpu` program has now released the `pi-cpu2` program,
as well as the `pi-gpu` program - both implementing the same algorithm for
calculating $\pi$. `pi-gpu` ports the $\pi$ calculation algorithm to the GPU, and
`pi-cpu2` changes the algorithm to improve speed at the cost of memory usage.

## Investigating memory usage of `pi-cpu2`

In the example programs, there should be the `pi-cpu2` executable. Lets verify
the authors claims that it should be faster using `srun`. Make sure to add the
`--constraint` option to ensure your times are consistent!

```bash
srun --constraint=Icelake pi-cpu2
```
```error
srun: job 12064697 queued and waiting for resources
srun: job 12064697 has been allocated resources
slurmstepd: error: Detected 1 oom_kill event in StepId=12064697.0. Some of the step tasks have been OOM Killed.
srun: error: il-n01: task 0: Out Of Memory
```

Ok, that wasn't what we expected! The error message says that our job was `OOM Killed`
and that `task 0: Out Of Memory`. Here, `OOM` is an abbreviation for Out Of Memory.
The overall error message is indicating that your job exceeded the memory allocation
of your job, which caused Slurm to cancel it. If we use `seff` on that job:

```bash
seff 12064697
```
```output
Job ID: 12064697
Cluster: milton
User/Group: yang.e/allstaff
State: OUT_OF_MEMORY (exit code 0)
Nodes: 1
Cores per node: 2
CPU Utilized: 00:00:00
CPU Efficiency: 0.00% of 00:00:00 core-walltime
Job Wall-clock time: 00:00:00
Memory Utilized: 0.00 MB (estimated maximum)
Memory Efficiency: 0.00% of 20.00 MB (10.00 MB/core)
```

You will find that it produces only the requested resources and the `OUT_OF_MEMORY`
state and no utilization information is found. Similarly, if we execute `sacct`, 
we should see `OUT_OF_ME+` and `0:125` under the `STATE` and `ExitCode` columns,
respectively:

```bash
sacct
```
```output
JobID           JobName  Partition    Account  AllocCPUS      State ExitCode 
------------ ---------- ---------- ---------- ---------- ---------- --------
... skipped output...
12064697        pi-cpu2    regular       wehi          2 OUT_OF_ME+    0:125 
12064697.ex+     extern                  wehi          2 OUT_OF_ME+    0:125 
12064697.0      pi-cpu2                  wehi          2 OUT_OF_ME+    0:125
```

::: discussion

This job failed because it started and then ran out of memory almost immediately.
Some jobs may only request large amounts of memory after the program has been
running awhile. In those cases, `seff` and `sacct` may still produce meaningful output.

::::::::::::::

Unfortunately, Slurm hasn't given you a lot of information about how much memory
you *should* request. When you're first testing out a program, a good test is to
run the program on your laptop or on the login node (for a short amount of time)
and monitor the process using `htop`.

::: challenge

### Revising `htop`

You learnt how to use `htop` in the previous lesson, but for when your job is
running on a compute node. So you can find out how much memory to request from
Slurm, try run `pi-cpu2` on one of the login nodes to see how much memory it
needs. Remember: you're interested in the `RES` column!

:::::::::::::

::: solution

On one of the login nodes, execute the `pi-cpu2` program. You will want to ensure
it runs indefinitely, so you have time to run `htop`:

```bash
./pi-cpu2 -r -1
```
```output
Result: 3.1418780541911 Error:  0.0002853131785 Time: 6.2856s
Result: 3.1416545913891 Error:  0.0000618503765 Time: 4.6628s
Result: 3.1414653105873 Error: -0.0001274304252 Time: 4.1556s
... It will continue on...
```

In another terminal, you can ssh to the same login node you ran `pi-cpu2` on and then run `htop`:

```bash
ssh slurm-login01
htop -u $USER
```

![`htop` screenshot with `pi-cpu2` running](fig/htop-screenshot-pi2.png)

The RES column should show a *peak* usage of roughly 1900MB, but that number
will fluctuate while the program runs.

:::::::::::

You now know that requesting 2GB of memory from Slurm should be sufficient. The default memory on
Milton is 10MB per CPU, and that definitely wouldn't be enough! Try running `pi-cpu2`
with the appropriate amount of memory:

```bash
srun --mem=2G --constraint=Icelake pi-cpu2
```
```output
srun: job 12066042 queued and waiting for resources
srun: job 12066042 has been allocated resources
Result: 3.1416610065891 Error:  0.0000682655765 Time: 2.9627s
Result: 3.1416797985893 Error:  0.0000870575767 Time: 2.9501s
Result: 3.1418230713906 Error:  0.0002303303780 Time: 2.9519s
```

And it's now running successfully! We can also see that the program is indeed
faster, as the old version took roughly 3.6s for each calculation of $\pi$ on one
core.

::: discussion

Determining how much memory to request from Slurm is not straightforward. 
Sometimes, the documentation may provide some indication of how much resources
the software will use. However if this isn't the case, testing the program on 
your laptop or the login node can be used to give an indication.

If your program uses too much memory, see if you can find smaller test cases, and study how the memory usage changes with the size or types
of these inputs. You can use this to infer how much memory your program might use
with your real inputs.

But if neither of those options are available, the easiest way to go about it is to over-allocate and
to use the tools discussed so far to refine your future jobs' resource request.

:::::::::::

## Comparing `htop` and `seff` memory values

You might be wondering how `htop` and `seff` may be used differently, since they
both provide information about your job. Mainly, `htop` gives a more detailed view
into your job, whereas `seff` provides only a single summary stat. Furthermore, 
`seff` results are only available at the end of the job. Another important
distinction between `htop` and `seff`, is the accuracy of the statistics.

We now know that the maximum memory used by the `pi-cpu2` program is approximately
1900MB. We can check this by trying to run the program in Slurm, but requesting
only 1800MB.

```bash
srun --mem=1800M --constraint=Icelake pi-cpu2
```
```error
srun: job 12066092 queued and waiting for resources
srun: job 12066092 has been allocated resources
slurmstepd: error: Detected 1 oom_kill event in StepId=12066092.0. Some of the step tasks have been OOM Killed.
srun: error: il-n02: task 0: Out Of Memory
```

This confirms our job's maximum memory is somewhere between 1800MB and 2GB (based on our
runs so far). Now try running running `pi-cpu2` on Slurm again with the right amount
of memory. Make the `pi-cpu2` program calculate $\pi$ 15 times with `-r 15`, so it runs for long
enough for memory usage stats to be collected by Slurm.

```bash
srun --mem=2G --constraint=Icelake pi-cpu2 -r 15
```
```output
srun: job 12066094 queued and waiting for resources
srun: job 12066094 has been allocated resources
Result: 3.1415999649886 Error:  0.0000072239760 Time: 2.9642s
... skipped output...
```

And now let's execute `seff` on the job and look at the `Memory Utilized` field:

```bash
seff 12066094
```
```output
... skipped output...
Memory Utilized: 377.43 MB
Memory Efficiency: 18.43% of 2.00 GB
```

We know that `pi-cpu2` will need at least 1800MB of memory to even calculate
$\pi$ once, but the value shown by `seff` will be *far lower* than that! 

::: discussion

### Slurm job resource utilization accuracy

Slurm collects job information by occasionally asking the system how much
resources the job is using. This is not a problem for jobs whose memory usage
stays steady throughout the lifetime of the job. However, this is insufficient
for jobs whose memory usage changes suddenly or frequently.

::::::::::::::

## Monitoring GPU activity

You're consumed by the need-for-speed, and you're ready to try the `pi-gpu` program
published by the same authors! When running the program, you will need:

* 1GB memory
* 1 GPU (of any kind)
* the `cuda/11.7.1` and `gcc/11.2.0` modules loaded

```bash
module load cuda/11.7.1 gcc/11.2.0
srun --gres=gpu:1 --mem=1G --partition=gpuq pi-gpu
```
```output
srun: job 12066158 queued and waiting for resources
srun: job 12066158 has been allocated resources
Result: 3.1415535681881 Error: -0.0000390854017 Time: 0.2894s
Result: 3.1416463617890 Error:  0.0000537081992 Time: 0.2065s
Result: 3.1415584281882 Error: -0.0000342254016 Time: 0.2060s
...
```

The job ran on a P100 GPU and it it's about `3.0/0.2 = 15` times faster than `pi-cpu2`!
You find out from the `--help` option, that `pi-gpu` also has a `-p` option which
can help you with running the program on more GPUs on the same node. Try it out
with `-p 2` and see if you get a 2x speedup.

```bash
srun --gres=gpu:2 --mem=1G --partition=gpuq pi-gpu -p 2
```
```output
srun: job 12066179 queued and waiting for resources
srun: job 12066179 has been allocated resources
Result: 3.1415107353877 Error: -0.0000819182020 Time: 0.4006s
Result: 3.1417724625901 Error:  0.0001798090003 Time: 0.1990s
Result: 3.1413390477862 Error: -0.0002536058036 Time: 0.1988s
...
```

The speedup seems to be minimal!

### Introducing `nvtop`

Let's investigate the program's behavior on the GPUs. We'll do this inside a
`salloc` session instead of via `srun` like we have so far:

```bash
salloc --partition=gpuq --gres=gpu:2 --mem=1G
```
```output
salloc: Pending job allocation 12066180
salloc: job 12066180 queued and waiting for resources
salloc: job 12066180 has been allocated resources
salloc: Granted job allocation 12066180
salloc: Waiting for resource configuration
salloc: Nodes gpu-p100-n02 are ready for job
```

Now on a seperate terminal, ssh to the node you've been allocated and execute
the `nvtop` command:

```bash
ssh gpu-p100-n02
nvtop
```

A terminal user interface should open that looks similar to:

![screenshot of `nvtop` output](fig/nvtop-screenshot-empty.png)
Your output may differ if other people's jobs are running on the same node. 
The interface will be reminiscent of `htop` but with differences:

* The top section doesn't show the CPU utilization bars. Instead, they show information about the device (we won't be covering this section).
* The middle section shows a time-series chart of each GPU's compute (cyan) and memory (olive) utilization percentage over time.
* The bottom section shows process information in a format similar to `htop`:
  * `PID`: process ID, which will correspond to a process on `htop`
  * `USER`: The user the process is owned by
  * `DEV`: the GPU ID the process is running on
  * `GPU`: the "compute" utilization of the GPU (in percentage)
  * `GPU MEM`: the memory utilization of the GPU (in MB)
  * `CPU`: the CPU utilization of the process
  * `HOST MEM`: the CPU memory utilization of the process
  * `Command`: the command that the GPU is running

`nvtop` is a useful tool in evaluating utilization of the GPU while your job is
running. This tool can be used as a way to check that

a) the GPUs you requested are actually being used, and
b) that they are being fully utilized

Back in your `salloc` session, try running `pi-gpu -p 2 -r -1` again. The 
`-r -1` option is added to ensure it continues running. Once it's running, 
return to your `nvtop` window.

```bash
srun pi-gpu -p 2 -r -1
```
```output
Result: 3.1415107353877 Error: -0.0000819182020 Time: 0.4045s
Result: 3.1417724625901 Error:  0.0001798090003 Time: 0.1996s
Result: 3.1413390477862 Error: -0.0002536058036 Time: 0.1987s
...
```

![`nvtop` interface with `pi-gpu -p 2 -r -1` running](fig/nvtop-screenshot-m1.png)

Two new processes would've popped up in the process list with your `pi-gpu` command.
You will also see that utilization charts will start to move.

In the process list, you will see two entries corresponding to the two GPUs that
`pi-gpu` is using. Under `DEV` you will see the device IDs which `pi-gpu` is using.
In the example screenshot above, they are GPU 0 and GPU 1. But, `nvtop` shows
the information for all the GPUs on the node by default. To see the GPUs assigned
to `pi-gpu`, quit `nvtop` by pressing `q` on your keyboard, and then execute
`nvtop` again, but with the `--gpu-select <GPUs>` where `<GPUs` is a colon (`:`)
seperated list of GPU IDs. As per the example above, the command would be:

```bash
nvtop --gpu-select 0:1
```

Change the ID's based on the GPUs you see `pi-gpu` running on. You should now
see information only for the GPUs you specified:

![`nvtop` with only our job's GPUs](fig/nvtop-screenshot-myjob.png)

### Interpreting `nvtop` output

A good place to start when determining if your program is using the GPU well is
looking at the utilization. Many programs have parameters which can affect this
utilization - especially programs that process data.

Many programs process data on the GPU in chunks as the GPU memory is typically
too small to handle the entire data set at once. These are often controlled
through chunk size or number of chunks parameters (you might also see the word
"block" being used instead). Typically, you want to tune the parameters such that
utilization is high.

In our case, the GPU utilization of each GPU that `pi-gpu` is using, is approximately
78%. Which is not necessarily ideal.

::: challenge

### Seeing chunk-size in action!

`pi-gpu` doesn't process data, but it does have a parameter which is similar to
a data set chunk: the number of trials parameter! In your `salloc` session, try
changing the number of trials `pi-gpu` uses using the `-n` flag e.g.

```bash
srun pi-gpu -p 2 -r -1 -n <numtrials>
```

Note that the default is 123,456,789

:::::::::::::

::: solution

Trying 12,345,678 (about 10x fewer trials than default):

```bash
srun pi-gpu -p 2 -r -1 -n 12345678
```

![`nvtop` shows `pi-gpu` GPU utilization at around 57% when number of trials is 10x less than default](fig/nvtop-screenshot-1e7.png)

Trying 1,234,567 (about 100x fewer trials than default):

```bash
srun pi-gpu -p 2 -r -1 -n 1234567
```

![`nvtop` shows `pi-gpu` GPU utilization at around 40% when number of trials is 100x less than default](fig/nvtop-screenshot-1e6.png)

Trying 500,000,000 (about 4x as many trials than default):

```bash
srun pi-gpu -p 2 -r -1 -n 500000000
```

![`nvtop` shows `pi-gpu` "spiky" GPU utilization when number of trials is 4x more than default](fig/nvtop-screenshot-5e8.png)

Importantly, you should've seen that the utilization of the GPU grows as you increase
the number of trials for `pi-gpu` to use to estimate $\pi$! And the opposite
should also be observed when you lower the number of trials.

In this case, increasing the number of trials can be roughly interpreted as giving
the GPUs enough work to keep them busy, whereas if too few trials are being used,
then there may not be enough work to keep the GPU's "compute units" busy.

When tuning your GPU programs, it's important to keep the GPU utilized. Note that
if you are *writing* a program that uses the GPU, utilization is not the only
consideration!

::::::::::::

::: instructor

`pi-gpu`'s numtrials parameter is not a direct analogy to chunk-size parameters
in data processing programs, so you may need to explain further.

::::::::::::::

So far, we've highlighted GPU utilization as a key indicator of performance, but
we can see that on two P100 GPUs, `pi-gpu` the utilization of both GPUs is at
about 78% - not quite fully utilized.

If you look at the output of `pi-gpu --help`, you'll see that the "mode" flag
is available, which can be used to enable an experimental, higher-performance,
algorithm. Trying that "experimental mode" with the default number of trials:

```bash
srun pi-gpu -p -2 -r -1 -m 2
```

```output
Result: 3.1416099117887 Error:  0.0000172581989 Time: 0.2929s
Result: 3.1415823393884 Error: -0.0000103142014 Time: 0.0546s
Result: 3.1418233305906 Error:  0.0002306770008 Time: 0.0567s
...
```

You should be able to see that the time to calculate $\pi$ is almost 4 times faster
than the default algorithm. If you look at the output of `nvtop`, you should
be able to see the difference in utilization:

![`nvtop` with the experimental algorithm enabled showing higher utilization](fig/nvtop-screenshot-m2.png)

In this case, the utilization has shot up to about 98%! GPU memory utilization
has also increased, which is a reflection of the algorithm used in this new mode.

::: keypoints
-   Choosing the right memory for you Slurm jobs takes a bit of trial and error, but it helps to know a bit about how your program behaves!
-   `htop` should be used to observe memory usage when memory usage varies frequently throughout the lifespan of the program. `sacct` and `seff` are good for programs that maintain steady memory usage.
-   `nvtop` is a `htop`-like tool for monitoring GPU activity
-   When optimizing GPU programs' parameters, try to aim for full utilization!
:::
