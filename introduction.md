---
title: "Introduction"
teaching: 10
exercises: 2
editor_options: 
  markdown: 
    wrap: 72
---

::: questions
-   Why should I learn to monitor performance of my Slurm jobs?
-   What other features of Slurm can I use to help with my workflows?
:::

::: objectives
-   Understand why jobs should be monitored carefully.
-   Understand how Slurm's additional features can alleviate pain
    points.
:::

## A Common Story

Imagine you're a researcher who has spent a good chunk of their time in
research in the lab, or you're a researcher who *does* do a fair amount
of computational research, but you've only been using laptop so far. And
one day, you join a new project that suddenly has a HUGE amount of data
to process - an amount that would take your laptop *years* to get
through!

Your PI has suggested that you give WEHI's Milton HPC facility a go.
Milton has thousands of CPU cores, petabytes of storage, and terrabytes
of RAM to use! That would make processing this huge dataset a breeze!

Since that suggestion, you've attended some introductory courses and
maybe you've found other researchers who know a bit about using Milton,
and you've managed to get started with using the Slurm scheduler and
submitting jobs.

But up until now, you've just been doing things in ways that *works*,
but you might be wondering whether yours jobs are setup to run
optimally. Maybe you've received emails from grumpy sysadmins about
inappropriately using resources. Or maybe you want to know how to make
it easier to more easily submit many similar jobs or jobs that depend on
each other.

::: challenge
## How would you do it?

Let's imagine you have hundreds of files that you need to run the same
command on. You know that Slurm can process that all in parallel, so how
would you go about submitting those jobs at first?
:::

::: solution
If you're new to Linux, you might've thought about submitting these jobs
manually! If you've done a bit of scripting, you might've thought to use
script arguments and a for loop to submit all the jobs. This *works*,
but Slurm also has **job arrays**! As we'll see in a later episode, job
arrays are a Slurm feature that can help you submit many similar jobs in
one go!
:::

::: challenge
## How would you do it?

What about workflows that happen in steps and where these steps have
different resource requirements? Like for example, one step is
multi-threaded, so the job should request many CPUs; but the next step
is single-threaded only?
:::

::: solution
If the second step is short, you might put the two steps into a single
Slurm job. But what if the second step takes a large amount of time?
Putting these two steps in the same job, could unfairly occupy resources
others could use!

You might also do this manually i.e., wait for the first step to finish,
and then submit the second job afterward.

Slurm also has job dependency features that you can take advantage of to
help with pipelines. We'll cover this in a future episode!
:::

::: instructor
The challenges can be done together with the researchers input.
:::

::: keypoints
-   Slurm, together with Linux system tools, can help you ensure jobs
    are utilizing resources effectively.
-   Slurm job arrays is a neater solution to submitting many similar
    jobs.
-   Slurm job dependencies can help you organise pipelines.
:::
