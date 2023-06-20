---
title: "R and Python Slurm scripts"
teaching: 10
exercises: 2
editor_options: 
  markdown: 
    wrap: 72
---

::: questions
-   How do I write Slurm scripts in languages other than Bash?
-   How can I combine Slurm with other languages?
:::

::: objectives
-   How to use different interpreters to write Slurm scripts
-   How to write job arrays using other languages
:::

## Motivation

The chances are, when you first started using Slurm, you probably wasn't all
that familiar with Bash. But you begrudgingly learnt it so you can make use of
the computational capabilities of HPC. If you're a Python or R user, you probably
wrote a script which performed a part of your analysis, and you might use this
script on HPC with a wrapper submission script that looks like:

```bash
#!/bin/bash
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G

Rscript myRscript.R <arguments>
```

And that's all it really does. But did you know you can bypass this wrapper script
by submitting the R/python script directly?

## A Python script

Let's consider a Python script `pi.py` that calculates $\pi$:

```python
# pi.py
import sys, random

# function to calculate pi
def calc_pi(numtrials):

    n = 0
    for i in range(numtrials):
        r1 = random.random()
        r2 = random.random()
        if (r1*r1 + r2*r2 < 1.):
            n += 1
        
    return 4.*n/numtrials

if __name__ == "__main__":

    # get number of trials from first command line argument
    # produce error if it doesn't work.
    try:
        numtrials = int(sys.argv[1])
    except:
        sys.exit("There was a problem parsing the command-line arguments\nDid you remember to pass an integer?")

    # calculate pi and error
    pi = calc_pi(numtrials)
    err = 3.141592653589793 - pi

    # print to terminal
    print(f"Result: {pi}, Error: {err}")
```

Which you can run by

```bash
python3 pi.py 123456789
```
which calculates $\pi$ with 123,456,789 trials. The output should look similar
to
```output
Result: 3.1416309393888415, Error: -3.8285799048409785e-05
```

::: challenge

### Submitting this script to Slurm

Instead of following the common pattern of writing a wrapper submissions script,
try submitting this Python script directly to Slurm!

You will need to follow the Slurm error messages to convert this into a working
Slurm script.

Hint: you can use the system interpreter located in `/usr/bin/python3`.

Once you have it working as a Slurm script, try adding `#SBATCH` options like
you would in a "normal" Slurm script.

:::::::::::::

::: solution

When submitting this script as-is with `sbatch pi.py`, you'll get the error:

```error
sbatch: error: This does not look like a batch script.  The first
sbatch: error: line must start with #! followed by the path to an interpreter.
sbatch: error: For instance: #!/bin/sh
```

This is a reminder that your script needs to have a hash-bang statement which
specifies which the interpreter to use!

In this lesson, we've used `/bin/bash` all throughout, although `/bin/sh` is
also common to see "out in the wild". But in this case, we need to use a Python
interpreter instead. We can add to the top of the script: `#!/usr/bin/python3`
which is installed on Milton. Once we do that, our script should work!

```bash
sbatch pi.py 123456789
```
```output
Submitted batch job 12261934
```

After about 40 seconds of the job running the corresponding `slurm-12261934.out`
file should be ready:

```
Result: 3.1417136565895944, Error: -0.000121002999801334
```

Which shows that it now works as a Slurm script!

This particular program doesn't need much resources, but we can still check that
`#SBATCH` options still work with `squeue`, `sacct`, or `seff`. If you add
`#SBATCH --cpus-per-task=4` below the hash-bang statement and submit the script,
you should see through your preferred query command that the job is now requesting
4 CPUs.

::::::::::::

## Which interpreter?

In the above challenge, we used the system Python interpreter. However, you often
use Python from a virtual or conda environment; and R from a module. Consequently,
choosing the correct interpreter is important so that your packages are picked up
properly!

### The reproducible way (but less portable)

The *safest* way to ensure your preferred interpreter is used is to hard-code the
path into the hash-bang statement at the top of the script.

For example, if you have an environment located at 
`/vast/scratch/users/<userid>/mycondaenv`, the corresponding interpreter is located in
`/vast/scratch/users/<userid>/mycondaenv/bin/python`, which you can use in the
hash-bang statement. Similarly, with `Rscript`, you can find where your preferred
`Rscript` interepreter is by:

```bash
module show R/<preferred version>
```
```output
/stornext/System/data/apps/R/R-<version>/lib64/R/bin
```
and you can add `Rscript` to the end of the path and place it in the hash-bang
statement e.g., `#!/stornext/System/data/apps/R/R-4.2.1/lib64/R/bin/Rscript`.
This way ensures the same interpreter are used every time 

### The portable way (but less reproducible)

A common approach is to infer which interpreter to use based on your environment.
To do this, you can add the `/usr/bin/env <interpreter>` command (note the
space between `/usr/bin/env` and `<interpreter>`). For example, adding
`#!/usr/bin/env python` as your hash-bang statement will pickup whichever python
interpreter is in your environment.

This is more portable and often more convenient, but can be less reproducible as
you may forget which environment it was supposed to run with, or which version
of the interpreter was used.

## Slurm Environment Variables

Both R and Python have their own ways of accessing environment variables. For example,
in Bash, saving the `SLURM_CPUS_PER_TASK` environment variable is done by

```bash
cpus=${SLURM_CPUS_PER_TASK}
```

Whereas, for Python and R, respectively:

```python
import os
cpus = os.getenv("SLURM_CPUS_PER_TASK")
```

```r
cpus = Sys.getenv("SLURM_CPUS_PER_TASK")
```

## Setting Up Job Arrays

But a major advantage Python and R have over Bash is their ability to parse text
either natively or through installable packages

For example, let's take our `iter-cpu.txt` file that we created back in episode
4 (job arrays):

```
iters cpus
100 2
100 4
1000 2
1000 4
10000 2
10000 4
```

To read this file in Python, we can use the pandas module:

```python
import pandas as pd
data = pd.read_csv('iter-cpu.txt', delimiter=' ')
print(data)
```
```output
   iters  cpus
0    100     2
1    100     4
2   1000     2
3   1000     4
4  10000     2
5  10000     4
```

For R, it's even easier:
```r
data = read.csv('iter-cpu.txt', sep=' ')
str(data)
```
```output
'data.frame':   6 obs. of  2 variables:
 $ iters: int  100 100 1000 1000 10000 10000
 $ cpus : int  2 4 2 4 2 4
```

::: challenge

Now that you know how to turn a Python or R script into a Slurm script. Try to
create a Slurm array script in Python or R where:

* each array task reads the `iter-cpu.txt` file and
* each array task prints a statement like: `CPUs: <n>, Iterations: <n>`, 
where `<n>` is the corresponding column and row of `iter-cpu.txt`.

For example, array task 0 should print out:
```output
CPUs: 2, Iterations: 100
```

HINT: you can make use of the `#!/usr/bin/env python3 (or Rscript)` hash-bang
statement for convenience.

:::::::::::::

::: solution

```python
#!/usr/bin/env python3
#SBATCH --array=0-5
#SBATCH --mem=1G

import os, pandas as pd
data = pd.read_csv('iter-cpu.txt', delimiter=' ')

taskid = int(os.getenv("SLURM_ARRAY_TASK_ID"))

niter = data['iters'].iloc[taskid]
ncpus = data['cpus'].iloc[taskid]

print(f'CPUs: {ncpus}, Iterations: {niter}')
```

```r
#!/usr/bin/env Rscript
#SBATCH --array=1-6
#SBATCH --mem=1G

data = read.csv('iter-cpu.txt', sep=' ')

taskid = as.integer(Sys.getenv("SLURM_ARRAY_TASK_ID"))

ncpus = data[["cpus"]][taskid]
niter = data[["iters"]][taskid]

paste0("CPUs: ", ncpus,', Iterations: ', niter)
```

When using Slurm array jobs, remember to make use of appropriate exception
handling! With Python, you can make use of `try`, `except`, and for R, you can
check whether `Sys.getenv("SLURM_ARRAY_TASK_ID")` returns `NA`.

::::::::::::

::: keypoints

-   Besides the code itself, the only *real* difference between a bash Slurm script and a Python or R Slurm script, is the hash-bang statement!
-   You can change the hash-bang statement to the `python` or `Rscript` interpreter you wish to use, or you can make use of `/usr/bin/env python` to determine which interpreter to use from your environment.
-   When using Slurm environment variables in a Python or R script, the same environment variables are available to you, but you must access them in the Python/R way.
-   Using Python or R Slurm scripts means you can
    a.  program in a language more familiar to you
    b.  make use of their broad functionality and packages
    c.  remove the need to have a wrapper Slurm script around your Python/R scripts.

:::
