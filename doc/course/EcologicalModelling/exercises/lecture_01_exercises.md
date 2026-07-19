# Lecture 1 Exercises — Introduction

Dataset: `data/mite_species.csv` and `data/mite_env.csv` (Oribatid mite
community, Lac Cromwell; Borcard & Legendre 1994, *Ecology* 75(4)).

Adapt the "hello data" code from `code/R/lecture_01_introduction.R`,
`code/python/lecture_01_introduction.py`, or
`code/julia/lecture_01_introduction.jl`. Work in whichever language(s) you
plan to use for the course — you are encouraged to try the same exercise in
more than one language to compare the workflows.

Remember the project convention: run your script with the working directory
at the repository root, read from `data/<file>.csv`, and save any new figure
to `figures/lecture_01_<slug>.png` with a descriptive slug.

## Exercise 1 — Substrate density instead of water content

Repeat the summary-statistics and plotting steps, but use `SubsDens`
(substrate density) from `mite_env.csv` in place of `WatrCont`. Report the
mean, standard deviation, and correlation with total abundance. Is the
relationship stronger or weaker than for water content? Save your plot as
`figures/lecture_01_abundance_vs_subsdens.png`.

## Exercise 2 — Abundance by shrub cover

`mite_env.csv` includes a `Shrub` column (categorical: None / Few / Many).
Compute the mean and standard deviation of total mite abundance separately
for each `Shrub` level. Which level has the highest average abundance?
Present your result as a small table.

## Exercise 3 — The most abundant species

Using only `mite_species.csv`, find the single species (column) with the
largest total count summed across all 70 sites. Report its name and total
count, then make a scatter plot of that species' abundance (not total
abundance) against `WatrCont`, joining to `mite_env.csv` as in the lecture
code.

## Exercise 4 (optional, cross-language) — Reproduce in a second language

If you completed Exercises 1–3 in one language, repeat Exercise 1 in a
second language of your choice. Confirm that the mean, standard deviation,
and correlation values match to at least two decimal places. This is a
useful habit for the rest of the course: cross-checking a result in a second
language is one of the fastest ways to catch a coding mistake.
