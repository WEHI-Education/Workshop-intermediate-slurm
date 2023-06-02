---
title: "Organising dependent Slurm jobs"
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



::: keypoints

-   Slurm job arrays are a great way to parallelise similar jobs!
-   The `SLURM_ARRAY_TASK_ID` environment variable is used to control individual array tasks' work
-   A file with all the parameters can be used to control array task parameters
-   `readarray` and `read` are useful tools to help you parse files. But it can also be done many other ways!

:::
