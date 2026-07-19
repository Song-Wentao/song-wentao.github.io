# Lecture 15 Exercises -- Community Ecology Models

Use the starter scripts in `code/R/lecture_15_community_models.R`,
`code/python/lecture_15_community_models.py`, and
`code/julia/lecture_15_community_models.jl` as your starting point. Work in
whichever language(s) you are practicing this week -- all three scripts use
the same logic (pairwise correlation, null-model C-score, co-occurrence
network, simplified JSDM), so you can compare answers across languages if
you like.

## Exercise 1 -- Scaling up to BCI: co-occurrence at 225 species

`data/BCI_species.csv` has 50 plots x 225 tree species from Barro Colorado
Island -- too many species to demo live, but a good exercise in scaling up.

- Subset to the ~30 most abundant species (by total abundance summed across
  plots) to keep runtime reasonable.
- Rerun the pairwise Spearman correlation test, the null-model C-score test,
  and the co-occurrence network construction (Steps 1-3 of the lecture
  script) on this subset.
- Report the BCI network's density and mean degree, and compare them to the
  dune network's density (0.11) and mean degree (~3.1) from the lecture. Is
  the BCI tree community more or less tightly co-structured than the dune
  plant community? Suggest one ecological reason for the difference (e.g.
  spatial scale, life form, dispersal mode).

## Exercise 2 -- Identifying and interpreting hub species

Using the dune co-occurrence network from the lecture script, identify the
top-3 hub species by degree (the lecture script already prints these).

- For each hub species, look up or reason about its likely functional traits
  or life history (e.g. is it a widespread generalist, a species associated
  with a particular moisture or management regime, a clonal/creeping grass
  vs. a forb?).
- Propose a specific ecological mechanism that could explain why a
  generalist species accumulates many significant positive co-occurrence
  edges, even in the absence of any direct biotic interaction with its
  "partners."
- Contrast this with a species that has degree 0 (fully isolated in the
  network). What does zero significant positive associations tell you --
  and, importantly, what does it NOT tell you -- about that species'
  ecology?

## Exercise 3 -- Refitting the simplified JSDM with a different covariate

The lecture's simplified JSDM (Step 4) used `A1` (soil organic matter
horizon depth) as the shared environmental covariate.

- Refit the same per-species Poisson GLM approach using `Moisture` from
  `data/dune_env.csv` instead of `A1`.
- Report the mean |residual correlation| after controlling for Moisture and
  compare it to both the mean |raw correlation| and the mean |residual
  correlation| after controlling for A1 (from the lecture).
- Which covariate -- A1 or Moisture -- absorbs more of the raw co-occurrence
  signal? What would you conclude about which environmental axis is doing
  more of the work in structuring this plant community?

## Exercise 4 -- Null-model sensitivity to the randomization algorithm

The lecture used a "fixed-fixed" null model (row AND column sums preserved
exactly -- `method = "quasiswap"` in R's `oecosimu`, or the checkerboard-swap
algorithm in the Python/Julia versions).

- Rerun the null-model C-score test using a different constraint: shuffle
  each species' (column's) presences randomly among sites, preserving only
  column totals (species occurrence frequency) but NOT row totals (site
  richness). In R this is `oecosimu(pa, nestedchecker, method = "r0")` or
  similar; in Python/Julia, permute each column of the presence-absence
  matrix independently.
- Report the new SES and p-value and compare them to the fixed-fixed result
  from the lecture.
- In 2-3 sentences, explain why preserving row sums (site richness) matters
  for a fair null-model test, and what could go wrong -- in terms of false
  positives or false negatives -- if you ignore it.
