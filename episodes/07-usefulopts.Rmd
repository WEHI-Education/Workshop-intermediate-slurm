---
title: "Job Arrays"
teaching: 10
exercises: 2
editor_options: 
  markdown: 
    wrap: 72
---

::: questions
-   What `sbatch` lesser-known, but useful Slurm options are there?
:::

::: objectives
-   Understand how to use the `sbatch` options:
  - `--requeue`
  - `--constraint` and `--prefer`
  -  
:::

::: keypoints

-   Slurm job arrays are a great way to parallelise similar jobs!
-   The `SLURM_ARRAY_TASK_ID` environment variable is used to control individual array tasks' work
-   A file with all the parameters can be used to control array task parameters
-   `readarray` and `read` are useful tools to help you parse files. But it can also be done many other ways!

:::
