---
title: "Job Arrays"
teaching: 10
exercises: 2
editor_options: 
  markdown: 
    wrap: 72
---

::: questions
-   How can I run a lot of similar jobs?
-   How can I use job arrays in conjunction with a CSV file?
:::

::: objectives
-   Understand the job array syntax
-   Understand how to make use of array indices
-   Know how to use `sed` and `read` to parse 
:::

## Processing Samples

Now that you feel pretty comfortable with the `pi-cpu` program, your supervisor
wants you to investigate how the error value of the tool changes with the number
of iterations. This is controlled with the `-n` flag.

He's noted that the tool uses 123,456,789 iterations (approx. 1.2E8), but he would like to know
what the accuracy is like for lower number of iterations. He would like you to
see how the error value behaves for 1E2, 1E3, 1E4, ..., up to 1E8 iterations.

You know that running 7 tests manually is not a big deal, but you decide that
you might want to make this easier to use in case the number of tests increase
in the future.

You've heard about Slurm job arrays which is good at breaking up these "parameter
scans", so you decide to give them a go.

### Job Array Syntax

A Slurm script is turned into a job array with the `--array=<range>` sbatch
option. On Milton, `<range>` can be any integer from 0 up to 1000. To specify a
sequential range of values, you can use the `min-max` syntax, where `min` and
`max` are the minimum and maximum values of the range.

For example, your Slurm script may look like

```bash
#!/bin/bash

#SBATCH --job-name=myjob
#SBATCH --array=1-3

echo "hello world"
sleep 3600
```

This script will execute 10 jobs which request the default CPUs and memory. The job
will print "hello world" to the job's output file, and then wait for an hour.
When you submit this job, and your job waits in the queue, this array job will 
look similar to:

```bash
sbatch myjob.sh
```
```output
Submitted batch job 11784178
```
```bash
squeue -u $USER
```
```output
          JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
11784178_[1-3]   regular    myjob   yang.e PD       0:00      1 (None)
```

where the `[1-3]` correspond to the indices passed to `--array`. Once they 
start running, the output from `squeue` will look similar to:

```bash
squeue -u $USER
```
```output
      JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
 11784178_1   regular    myjob   yang.e  R       0:00      1 sml-n02
 11784178_2   regular    myjob   yang.e  R       0:00      1 sml-n02
 11784178_3   regular    myjob   yang.e  R       0:00      1 sml-n02
```

Each job is referred to as a "task" of a single job, each associated with their
own index. In the above example, each array task will have a task ID of 1-10.

The `--array` option can also accept lists of integers and ranges, seperated by
commas. For example, `--array=1-3,7` is accepetable too! This is useful for
testing or rerunning only specific indices.

Each array task will have its own output file. The default naming is 
`slurm-<jobID>-<taskID>.out`. For example, the above job submission produced:

```bash
ls slurm-11784178*.out
```
```output
slurm-11784178_1.out  slurm-11784178_2.out  slurm-11784178_3.out
```

::: discussion

### Cancelling array jobs

When cancelling jobs, you can reference individual array tasks, a range, or a list
similar to specifying the jobs to run. For example,

```bash
scancel 1174178_[1-3,7]
```

will cancel only array tasks 1, 2, and 3. If you want to cancel all the job tasks at once,
you can pass only the job ID.

```bash
scancel 1174178
```

This will cancel any unfinished or pending array tasks in the queue.

Note that this only works for `scancel`! No other Slurm command will accept this format.

:::::::::::

### Environment Variables in Slurm Jobs

Before you learn more about making use of job arrays, it's important to know about
Slurm job environment variables!

Every time Slurm runs a job for you, Slurm makes a number of environment variables
available to you. These environment variables contain information about the job,
like the job ID, the job name, or the job's resources.

A full list of the available environment variables in a job can be found with
`man sbatch` and scrolling down to `OUTPUT ENVIRONMENT VARIABLES`. You can jump
to this section by typing `/output environment variables` after you've opened
the manual page.

::: challenge

Try crafting a Slurm script that requests 4 CPUs and 4GB of memory that says
hello, and then prints the node it's running on, the number of CPUs requested,
and then the memory requested. An example output would be:

```output
Hello. I am running on sml-n01
These are the resources I requested:
CPUs: 4
Memory: 4096MB
```
:::::::::::::

::: solution

The Slurm environment variables needed here are `SLURM_CPUS_PER_TASK`, `SLURM_JOB_NODELIST`, and
`SLURM_MEM_PER_NODE`.

To produce the output in the challenge, your script needs to look similar to:
```bash
#!/bin/bash
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G

echo "Hello. I am running on ${SLURM_JOB_NODELIST}"
echo "These are the resources I requested:"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Memory: ${SLURM_MEM_PER_NODE}MB"
```

These parameters can be useful when you would like to automatically pass the Slurm
resource request to a command in your script. For example, I can make `pi-cpu`
use however many CPUs I've requested automatically by using the `SLURM_CPUS_PER_TASK environment variable inside a job script:

```bash
#!/bin/bash
#SBATCH --cpus-per-task=4
srun pi-cpu -p ${SLURM_CPUS_PER_TASK}
```

::::::::::::

::: instructor

[Intro to Linux Command Line](https://monashdatafluency.github.io/shell-novice/)
is specified as a prerequisite, so learners should know how to work with.
But due to the infrequency of these workshops, this isn't guaranteed, so you might
want to remind people what environment variables are.

::::::::::::::

### The `SLURM_ARRAY_TASK_ID` Environment Variable

Now back to Slurm job arrays!

While skimming through the manual pages, you might've noticed that one of the
environment variables listed is `SLURM_ARRAY_TASK_ID`. This variable will store 
the ID of each task in a job array, which can be used to control what each task does.

As practice, we can take the Slurm script we wrote at the beginning and modify it a little:

```bash
#!/bin/bash

#SBATCH --job-name=myjob
#SBATCH --array=1-3

echo "hello world from task ${SLURM_ARRAY_TASK_ID}"
```

This script should now print `hello world from task <N>` where `N` is 1-3.

```bash
sbatch myjob-array.sh
```
```output
Submitted batch job 11784442
```
And once all the job tasks have completed, we should be able to check the output
of each task:

```bash
cat slurm-11784442-*.out
```
```output
hello world from task 1
hello world from task 2
hello world from task 3
```

Which is great! Now we just have to figure out how to make use of these task IDs.
Remember: our goal is to execute `pi-cpu -n <iter>` where `iter` is 1E2, 1E3, ..., 1E8.

One might think of using the IDs directly, for example, instead of `#SBATCH --array=1-3`, maybe we could try something like

```bash
#SBATCH --array=100,1000,10000,100000,1000000,10000000,1000000000
```

But if we add this to our example array script and try to submit it, we get the error:

```error
sbatch: error: Batch job submission failed: Invalid job array specification
```

And unfortunately this is because Slurm on Milton has been configured to accept a [max job array index of 1000](https://slurm.schedmd.com/job_array.html).

So, we have to figure out another way! A common alternative is to use a file to
store the values we want the job array to scan over. In our case, we can put together a
file with a line for each number of iterations we want the job array to scan over.
Let's call it `iterations.txt`, which contains:

```
100
1000
10000
100000
1000000
10000000
100000000
```

But how do we use the job array index to retrieve each of these lines? We can use
the `sed` Linux command line utility.

To take the nth line out of a text file, you can run:

```bash
sed "Nq;d" <file>
```

where `N` is the line number to retrieve. For example, `sed "1q;d" <file>` will
retrieve the first lin of the file `<file>`.

::: challenge

Try use run the above command with a few different values of `N`!

See what happens if you pass an `N` value greater than the number of lines in the file.

What if you don't pass a value at all (i.e., leave N empty)?

:::::::::::::

::: solution

Taking the 3rd line of `iterations.txt`:

```bash
sed "3q;d" iterations.txt
```
```output
10000
```

and the 7th:

```bash
sed "7q;d" iterations.txt
```
```output
100000000
```

There's only 7 lines in `iterations.txt`, so what if I pass `N=8`?

```bash
sed "8q;d" iterations.txt
```
```output

```

Nothing is returned! What if I don't pass a value?

```bash
sed "q;d" iterations.txt
```
```output
100
```

`sed` seems to take out just the first value. Keep these behaviours in mind when
using `sed`!

::::::::::::

::: discussion

### Comments on `sed`

`sed` is a Linux command line text-processsing tool that can be very powerful! But, it requires
time to learn as well as practice as the syntax is not very intuitive. The `sed` command that is shown here
is simple, but not necessarily easily understood to the uninitiated. As an alternative RCP has
developed a [Python package](https://github.com/wehi-ResearchComputing/slarray) that can be used as an alternative.

Additionally, R and Python users may prefer to do use Slurm job arrays in those languages.
How this can be done will be showed in later episodes.

::::::::::::::

Now that we've established that we can use `sed`, we need to implement it into
our script. 

::: callout
### Tests
It's generally good practice to *test* your array job before you run it for real. This
is especially true if you plan to run a large number of tasks! 
:::::::::::

Let's first test that we know how to properly combine the `SLURM_ARRAY_TASK_ID` environment variable together with `sed`.
Take your script and modify it:

```bash
#!/bin/bash

#SBATCH --job-name=myjob
#SBATCH --array=1-3

echo "hello world from task ${SLURM_ARRAY_TASK_ID}"
niterations=$(sed "${SLURM_ARRAY_TASK_ID}q;d" iterations.txt)
echo "I will run ${niterations}!"
```

::: discussion

### Command Substitution

```bash
niterations=$(sed "${SLURM_ARRAY_TASK_ID}q;d" iterations.txt)
```
This line is taking one line of test from `iteractions.txt` and saving it into
the `niterations` variable. This is done by executing the command 
```bash
sed "${SLURM_ARRAY_TASK_ID}q;d" iterations.txt
```
`${SLURM_ARRAY_TASK_ID}` is being used as the `N` parameter. 

This entire command is contained
within `$()`. This is known as "Command Substitution". This allows the output of the command
within the brackets to be used inside another command.

In this case, we've run the `sed` command and saved the output into the `niterations` variable.

::::::::::::::

Let's submit this script to confirm that we've used `sed` correctly.

```bash
sbatch myjob-array.sh
```
```output
Submitted batch job 11784737
```
Because we've only passed the range `1-3` to the `--array` option, we should expect
to only see outputs for the first 3 rows in `iterations.txt`:
```bash
cat slurm-11784737_*.out
```
```output
hello world from task 1
I will run 100!
hello world from task 2
I will run 1000!
hello world from task 3
I will run 10000!
```
Which demonstrates that we've taken the first 3 lines of `iterations.txt` correctly!

::: keypoints

-   Requesting more resources from Slurm doesn't mean your job knows how to use them!
    - Many programs don't work in parallel by default - either that functionality doesn't exist, or needs to be turned on!
    - Parallelism across nodes is differently parallelism within nodes. You usually need to run them a little differently than a normal program
-   The `htop` system tool is a great way to get live information about how effective your job is
-   `seff` and `sacct` can be used to get summary stats about jobs
-   More CPUs doesn't always mean an equivalent speedup!

:::
