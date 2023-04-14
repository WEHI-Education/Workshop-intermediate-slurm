---
site: sandpaper::sandpaper_site
---

Welcome to Intermediate Slurm! Delivered by WEHI's Research Computing Platform.

This lesson is targeted to learners who are researchers who have started using Slurm on Milton, and now have
a sense of how to submit Slurm jobs and request resources through `sbatch`.

It aims to improve learner's jobs' resource utilization and performance. But each researcher's
software is different! So this lesson will show learners the *tools* and teach basic concepts
that the learners can use to evaluate the performance of their jobs and the software they're using
in those jobs.

The lesson also shows the learner a few Slurm features that can be used to help them organise
their jobs in ways that can simplify submission of many similar jobs, or help organise jobs
that depend on each other.

Finally, the lesson will show how learners can submit R or python scripts as Slurm jobs
instead of the common Shell or Bash script. It will also show some of R and Python's powerful
file parsing functionality and how that can make Slurm job arrays even more robust!

## Learning Objectives

After completing this lesson, learners are expected to know:

- Which tools to use to evaluate performance of their *CPU-only* Slurm jobs
- Which tools to use to evaluate performance of their *GPU* Slurm jobs
- How to customize Slurm information-collecting commands
- How to make use of Slurm array jobs to parallelise job submission
- How to use job dependencies to create simple Slurm job pipelines
- How to write Python and R Slurm scripts

::::::::::::::::::::::::::::::::::::::::::  prereq

## Skills
It's expected that you've submitted Slurm jobs before, and that you've used
`sbatch` and `squeue` before. Some beginner-level command-line experience is
necessary too. It's assumed that you know how to do the things delivered in
[this introductory command-line course](https://monashdatafluency.github.io/shell-novice/)


::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::  prereq

## Setup
The entirety of this lesson is delivered on Milton! To follow along, you will
need command-line access to Milton via SSH (Secure SHell). If you don't, please
send an email to support@wehi.edu.au.

SSH access to any cluster using the Slurm scheduler will also work, although the
setup may differ slightly from what is shown in the lesson.

::::::::::::::::::::::::::::::::::::::::::::::::::
