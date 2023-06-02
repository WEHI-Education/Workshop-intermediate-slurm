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

::: keypoints

-   Slurm job arrays are a great way to parallelise similar jobs!
-   The `SLURM_ARRAY_TASK_ID` environment variable is used to control individual array tasks' work
-   A file with all the parameters can be used to control array task parameters
-   `readarray` and `read` are useful tools to help you parse files. But it can also be done many other ways!

:::
