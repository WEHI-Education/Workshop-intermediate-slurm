# Intermediate Slurm on WEHI Milton

This lesson is created using [The Carpentries Workbench][workbench] and follows the workshop [Introduction to HPC and Slurm]([https://carpentries-incubator.github.io/hpc-intro/](https://wehi-researchcomputing.github.io/Workshop-IntroToHPC-Slurm/). It has been customised to work for users of WEHI Milton.

This lesson is targeted to learners who are researchers who have started using Slurm on Milton, and now have a sense of how to submit Slurm jobs and request resources through sbatch.

It aims to improve learner’s jobs’ resource utilization and performance. But each researcher’s software is different! So this lesson will show learners the tools and teach basic concepts that the learners can use to evaluate the performance of their jobs and the software they’re using in those jobs.

The lesson also shows the learner a few Slurm features that can be used to help them organise their jobs in ways that can simplify submission of many similar jobs, or help organise jobs that depend on each other.

Finally, the lesson will show how learners can submit R or python scripts as Slurm jobs instead of the common Shell or Bash script. It will also show some of R and Python’s powerful file parsing functionality and how that can make Slurm job arrays even more robust!

This course will be delivered mostly using live-coding demonstrations and exercises. The entire workshop is delivered in approximately 3 1-hour chunks with breaks in between. 

This course is maintained by [WEHI Research computing](mailto:research.computing@wehi.edu.au)
* [@jIskCoder](https://github.com/jIskCoder)
* [@edoyango](https://github.com/edoyango)
* [@multimeric](https://github.com/multimeric)
* [@adamtaranto](https://github.com/adamtaranto)

## Lesson Outlines

[User profiles](leaners/learner-profiles.md) of people approaching
high-performance computing from an academic and/or commercial background are
provided to help guide planning and decision-making guidence on how to make use of Milton.


1. [Introduction](episodes/01-introduction) (10 minutes)
2. [Monitoring a Jobs performance](episodes/02-cpumonitoring) (60 minutes)
3. [Job Arrays](episodes/03-jobarrays) (60 minutes)
4. [Organising dependent Slurm jobs](episodes/04-jobdependencies) (35 minutes)
5. [R and Python Slurm scripts](episodes/05-rpython) (15 minutes)

If you have any questions, contact [@edoyango](https://github.com/edoyango)

[workbench]: https://carpentries.github.io/sandpaper-docs/
