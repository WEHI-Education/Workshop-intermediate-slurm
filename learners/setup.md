---
title: Setup
---

## Example Files

<!--
FIXME: place any data you want learners to use in `episodes/data` and then use
       a relative link ( [data zip file](data/lesson-data.zip) ) to provide a
       link to it, replacing the example.com link.
-->

We will complete this workshop on the WEHI HPC (Milton). You will need to connect via [OnDemand](https://ondemand.hpc.wehi.edu.au/) or ssh from you local terminal.

**Working Directory**

If you have VAST Scratch, dowload the workshop data there. Remember VAST Scratch has a 14-day no-access deletion policy. It is not backed up. 

In this case it is a good place to store data that we want automatically cleaned up.

Your home directory (`cd $HOME`) is ok too.

```
# Navigate to your Scratch directory
cd /vast/scratch/users/$USER
```

**Download Data**

Download the [demo programs](episodes/data/example-programs.tar.gz) and untar it on Milton. 

```
# Fetch the data bundle
wget https://raw.githubusercontent.com/WEHI-Education/Workshop-intermediate-slurm/main/episodes/data/example-programs.tar.gz

# Unzip the data
tar -xzvf example-programs.tar.gz

# Navigate into the data directory
cd example-programs
```

