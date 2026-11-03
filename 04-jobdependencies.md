---
title: "Organising Dependent Slurm Jobs"
teaching: 10
exercises: 2
editor_options: 
  markdown: 
    wrap: 72
---

::: questions
-   How can I organise jobs that depend on each other?
:::

::: objectives
-   Know how to use the `--dependency` `sbatch` option
:::

## A pipeline to visualize `pi-cpu` results

Inside the example-programs, there is the folder `job-depends` which contains
files used in this episode.

In the previous episode, you learnt how to create job arrays to investigate
how the accuracy of `pi-cpu` changes with the number of trials used. You now
want to present these results to your supervisor graphically, but you still
need to aggregate and process the results further to create something presentable.
You decide that you want to show a bar chart where the X-axis corresponds to the
number of trials, and the Y-axis is the average absolute error calculated
determined from multiple calculations of $\pi$.

You want to test 7 different number of trials: 1E2 (100), 1E3 (1,000), ... , up to 1E8 (100,000,000).
These values are in `pi-process-input.txt`. These values are used inside `pi-submit.sh`,
which is a script in `example-programs` that is a Slurm job array script like in
the job array episode. 

You know that you need to write a bit more code to complete the pipeline:

1. For each number of trials, the results from `pi-cpu` need to be averaged.
2. The individual averaged results need to be aggregated into a single file.

A diagram of the process looks like:

```
n = 1E2    1E3    ...     1E7     1E8
     |      |              |       |
     |      |              |       |
  pi-cpu  pi-cpu         pi-cpu  pi-cpu
     |      |              |       |
     |      |              |       |
    avg    avg            avg     avg
     |      |              |       |
     |______|___combine____|_______|
                results
                   |
                   |
                 final
                results
```

You decide that you want to do this with Slurm jobs because each step requires
different amounts of resources. But to set this up, you need to make use of:

## Slurm job dependencies

To setup Slurm jobs that are dependent on each other, you can make use of the
Slurm `--dependency`, or `-d` option. The syntax of the option is:

```bash
#SBATCH --dependency=condition:jobid   # or
#SBATCH -d condition:jobid
```

This will ask Slurm to ensure that the job that you're submitting doesn't start
until `condition` is satisfied for job `jobid`. For example, 

```bash
#SBATCH --dependency=afterok:1234
```

is requesting for the job you're submitting to start, only if job `1234` completes
successfully. This allows you to chain a series of jobs together, perhaps with
different resource requirements, without needing to monitor progress.

Other conditions include:

* `after`: start this job after the specified job **starts**
* `afternotok`: start this job only if the specified job **fails**
* `afterany`: start this job after the specified job **fails, succeeds, or is cancelled**
* `singleton`: Start this job if there are **no other running jobs with the same name.**
* `aftercorr`: Start this **array task** when the **corresponding array task in the specified job completes successfully**.

In your $\pi$ calculation scenario, submitting the second lot of array jobs (i.e., the `avg` jobs)
can be submitted using `--dependency=afterok:<jobid>`. However, this will mean that
*none* of the `avg` job array tasks will start until *all* of the `pi-cpu` jobs finish.
This results in lower job throughput as tasks wait around. 

We can achieve better job throughput by making use of the `aftercorr` condition
(short for "after corresponding"), which tells Slurm that each task in the second job
can start once the same task in the first job completes successfully.

## Setting up the `avg` array job

Each `pi-cpu` job output will have multiple attempts to calculate $\pi$. So, the
goal of each `avg` job array task is to calculate the average error. `pi-avg.py`
in the `example-programs/job-depends` directory, is a script made specifically 
for this purpose. For example, if you execute `pi-cpu` and redirect the output
to a file:

```bash
./pi-cpu > pis.txt
```

and then run

```bash
python3 pi-avg.py pis.txt
```
You should get output similar to:
```output
Average Absolute Error: 0.00016350984148000002
```
This program can be placed into a Slurm script like so:
```bash
#!/bin/bash
# pi-avg.sh

#SBATCH --job-name=pi-avg
#SBATCH --array=0-6
#SBATCH --output=%x-%a.out
#SBATCH --cpus-per-task=1

id=$SLURM_ARRAY_TASK_ID

python3 pi-avg.py pi-submit-${id}.out
```

### The `pi-avg.sh` script line-by-line

```bash
#!/bin/bash
```
is the hash-bang statement. Required by Slurm, but good practice to include in 
any script.
```bash
# pi-avg.sh
```
is a comment with the name of the script.
```bash
#SBATCH --job-name=pi-avg
```
is a Slurm option specifying the job name. In this case, it is `pi-avg`.
```bash
#SBATCH --array=0-6
```
is telling Slurm that this job is a job array with task IDs 0 to 6 (inclusive).
```bash
#SBATCH --output=%x-%a.out
```
is telling Slurm where to write the output of the script to. `%x` is a placeholder for the job name, and `%a` is a placeholder for the job task array. For example, the job task with ID = 0, will have the output file: `pi-avg-0.out`.
```bash
#SBATCH --cpus-per-task=1
```
is specifying the number of CPUs each job array task needs.
```bash
id=$SLURM_ARRAY_TASK_ID
```
sets the `id` variable to the value stored in the `SLURM_ARRAY_TASK_ID`
environment variable.

```bash
python3 pi-avg.py pi-submit-${id}.out
```
is running the `pi-avg.py` program on the file `pi-submit-${id}.out`, which would
be the output from the `pi-submit.sh` job tasks.

Notably, this script doesn't have the `--dependency` option set, but this will
be discussed later.

### Submitting the jobs

Before we submit `pi-submit.sh`, we need to make sure that `pi-cpu` is in the
correct place. `pi-submit.sh` assumes that `pi-cpu` is in the working directory.
So, if you're in the `job-depends` directory, you must first `cp ../pi-cpu .`,
which makes a copy of `pi-cpu` in the `job-depends` directory.

Now that we have `pi-submit.sh` and `pi-avg.sh` we can try submitting them such
that `pi-avg.sh` job tasks depend on `pi-submit.sh` job tasks. We can start this
process by

```bash
sbatch pi-submit.sh
```
```output
Submitted batch job 12271504
```
And then submit the next job using the `--dependency=aftercorr:<jobid>` flag:
```bash
sbatch -d aftercorr:12271504
```
```output
Submitted batch job 12271511
```
Reminder: `-d` is the short-form of `--dependency`! Depending on how fast you
were with submitting the jobs and setting up the dependency, when you run
`squeue -u $USER`, you might see output similar to:

```output
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
        12271511_6   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12271511_5   regular   pi-avg   yang.e PD       0:00      1 (None)
        12271511_4   regular   pi-avg   yang.e PD       0:00      1 (None)
        12271511_3   regular   pi-avg   yang.e PD       0:00      1 (None)
        12271511_2   regular   pi-avg   yang.e PD       0:00      1 (None)
        12271511_1   regular   pi-avg   yang.e PD       0:00      1 (None)
        12271511_0   regular   pi-avg   yang.e PD       0:00      1 (None)
        12271504_6   regular pi-submi   yang.e  R       0:12      1 sml-n02
```
The `pi-submit` job (job ID of 12271504) only has task ID 6 running and all the
`pi-avg` jobs are waiting. To confirm that the other `pi-submit` tasks have
completed, you can use the command `sacct -Xj <pi-submit jobid>` e.g.:

```bash
sacct -Xj 12271504
```
```output
JobID           JobName  Partition    Account  AllocCPUS      State ExitCode 
------------ ---------- ---------- ---------- ---------- ---------- -------- 
12271504_0    pi-submit    regular       wehi          2  COMPLETED      0:0 
12271504_1    pi-submit    regular       wehi          2  COMPLETED      0:0 
12271504_2    pi-submit    regular       wehi          2  COMPLETED      0:0 
12271504_3    pi-submit    regular       wehi          2  COMPLETED      0:0 
12271504_4    pi-submit    regular       wehi          2  COMPLETED      0:0 
12271504_5    pi-submit    regular       wehi          2  COMPLETED      0:0 
12271504_6    pi-submit    regular       wehi          2    RUNNING      0:0
```

After a bit of time, you should see the `pi-avg` job tasks begin to go through
(should be quite quickly as the job is quite short)

```bash
squeue -u $USER
```
```output
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
        12271511_3   regular   pi-avg   yang.e CG       0:00      1 sml-n02
        12271511_4   regular   pi-avg   yang.e CG       0:00      1 sml-n02
        12271511_5   regular   pi-avg   yang.e CG       0:00      1 sml-n02
```

Depending on how fast you were submitting the jobs, you likely weren't able to
see all the jobs wait in the queue. However, later we'll develop a "driver"
script which will automate setting up the dependencies.

::: instructor

As these jobs are quite small, it is quite hard to capture the full effect of
using the `aftercorr` condition. This is because Slurm on Milton only processes
the queue every 30s or so, and the `pi-cpu` program is expected to last only
approximately 20s at most.

If you have time and wish to show the learners the full effect, the following
scripts should work:

```bash
#!/bin/bash
# this job is submitted first. It sleeps for ID * 60s
# e.g., ID 2: sleeps for 120s.
# it then prints the date.

#SBATCH --job-name=1st
#SBATCH --output=%x-%a.out
#SBATCH --array=1-5

let "t = 60 * ${SLURM_ARRAY_TASK_ID}"
sleep $t
date
```

```bash
#!/bin/bash
# this job is submitted second and just prints the date.

#SBATCH --job-name=2nd
#SBATCH --output=%x-%a.out
#SBATCH --array=1-5

date
```

::::::::::::::

::: challenge

## Setting up the final `combine` job

Now that you've learnt about how to use the `--dependency/-d` option, try and
setup the final job that combines the results from `pi-avg.sh`! Call it
`pi-combine.sh`

Reminder: this job should be a single job, that takes the results of all the
`pi-avg.sh` and organises the results into a single file.

Your output should look something like

```output
100 Average Absolute Error: 0.18431854820252003
1000 Average Absolute Error: 0.034800000000000005
10000 Average Absolute Error: 0.014562903594960003
100000 Average Absolute Error: 0.00271745179748
1000000 Average Absolute Error: 0.0009526517974799999
10000000 Average Absolute Error: 0.00037933179748
100000000 Average Absolute Error: 0.00014778020251999998
```

HINT1: use `pi-process-input.txt` to get the data for the first column.

HINT2: you will probably need to use: `readarray`, a `for` loop, and `cat`.

:::::::::::::

::: solution

Script could look like:

```bash
#!/bin/bash
# pi-combine.sh

#SBATCH --job-name=pi-combine
#SBATCH --output=%x.out

# read ntrial data into niterations bash array
readarray -t niterations < pi-process-input.txt

for i in {0..6}
do

    # get label from niterations array
    label=${niterations[$i]}
    
    # get average error from pi-avg-${i}.out
    data=$(cat pi-avg-${i}.out)
    
    # print label with data
    echo "$label $data"
done
```

::::::::::::

You should now have `pi-submit.sh`, `pi-avg.sh`, and `pi-combine.sh` Slurm
scripts which you can now combine into a pipeline! We'll do this with one more
script, which will be referred to as the "driver" script as it is "driving" the
pipeline. This driver script will submit all the jobs and set the dependencies.

This script could look like:

```bash
#!/bin/bash
# pi-driver.sh

# submit the first pi-submit job
# saves the job ID into the jobid1 variable
jobid1=$(sbatch --parsable pi-submit.sh)

# submit the second pi-avg job.
# due to aftercorr condition, each task 
# depends on the same task from pi-submit.sh.
# saves the job ID into the jobid2 variable
jobid2=$(sbatch --parsable --dependency=aftercorr:$jobid1 pi-avg.sh)

# submit the last pi-combine job
# this job waits for all tasks from jobid2
# to complete successfully (afterok).
# job ID is not saved as it is not needed.
sbatch --dependency=afterok:$jobid2 pi-combine.sh
```

The driver script makes use of the `--parsable` option that can be used with
`sbatch`. This makes `sbatch` return the job ID *only*, instead of the statement
`Submitted batch job <job ID>`. This enables "parsing" the job ID. In this case,
the job IDs are saved into `jobidN` bash variables.

The driver script does not need to be submitted, it can be run as a normal script:

```bash
chmod +x pi-driver.sh
./pi-driver.sh
```
```output
Submitted batch job 12271538
```

When exeucting the driver script, you should only see one `Submitted batch job`
statement printed to the terminal, as the first two jobs are submitted with the
`--parsable` option and their Job IDs being saved to variables, instead of being
printed to the terminal.

If you run `squeue -u $USER` *immediately* after the completion of the script,
you should see your jobs pending in the queue, similar to:

```output
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
          12272749   regular pi-combi   yang.e PD       0:00      1 (Dependency)
    12272748_[0-6]   regular   pi-avg   yang.e PD       0:00      1 (None)
    12272747_[0-6]   regular pi-submi   yang.e PD       0:00      1 (None)
```

and as you continue checking the queue, you should be able to see Slurm processing
your jobs:

```output
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
        12272748_6   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272748_5   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272748_4   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272748_3   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272748_2   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272748_1   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
          12272749   regular pi-combi   yang.e PD       0:00      1 (Dependency)
        12272748_0   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
    12272747_[0-6]   regular pi-submi   yang.e PD       0:00      1 (None)
```

This shows Slurm "unrolling" the `pi-avg` job tasks, and

```
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
        12272748_6   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272748_5   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272748_4   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272748_3   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272748_2   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272748_1   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
          12272749   regular pi-combi   yang.e PD       0:00      1 (Dependency)
        12272748_0   regular   pi-avg   yang.e PD       0:00      1 (Dependency)
        12272747_0   regular pi-submi   yang.e  R       0:01      1 sml-n10
        12272747_1   regular pi-submi   yang.e  R       0:01      1 sml-n10
        12272747_2   regular pi-submi   yang.e  R       0:01      1 sml-n10
        12272747_3   regular pi-submi   yang.e  R       0:01      1 sml-n10
        12272747_4   regular pi-submi   yang.e  R       0:01      1 sml-n10
        12272747_5   regular pi-submi   yang.e  R       0:01      1 sml-n07
        12272747_6   regular pi-submi   yang.e  R       0:01      1 sml-n07
```

shows the `pi-submit` jobs running and the `pi-avg` jobs waiting.

If all goes well, you should have a `pi-combine.out` (or similar) file with your outputs!

```bash
cat pi-combine.out
```
```
100 Average Absolute Error: 0.156
1000 Average Absolute Error: 0.05336290359496
10000 Average Absolute Error: 0.00736
100000 Average Absolute Error: 0.00457345179748
1000000 Average Absolute Error: 0.00152585179748
10000000 Average Absolute Error: 0.00048161179748
100000000 Average Absolute Error: 0.00013798799999999997
```

You can then plot this in Excel or whichever tool you prefer!

::: keypoints

-   Make a job depend on another with the `--dependency` or `-d` flag for `sbatch`
    - dependency conditions can be used to control when the dependant job starts
    - the full list of conditions can be better understood from `man sbatch`.
-   job dependencies can be combined with job arrays to create pipelines!

:::
