# Lecture 13 Exercises -- Species Distribution / Niche Models

Use the starter scripts in
`code/R/lecture_13_species_distribution_models.R`,
`code/python/lecture_13_species_distribution_models.py`, and
`code/julia/lecture_13_species_distribution_models.jl` as your starting
point. All three load `data/bei_points.csv` (3604 mapped Beilschmiedia
pendula trees) and `data/bei_covariates_grid.csv` (elevation and slope
gradient across the Barro Colorado Island 50-ha plot), extract elev/grad
at each tree by nearest-neighbour lookup, generate background points,
and fit a logistic regression SDM and a Random Forest SDM. Work in
whichever language(s) you are practicing this week.

Reminder: this is a presence-background model built from tree locations,
not a designed presence/absence survey. Every number below should be
read with that data-structure caveat in mind, not treated as ground
truth about Beilschmiedia's realized niche.

## Exercise 1 -- Background point count and GLM sensitivity

Refit the logistic regression with `n_background` set to 2x, and then
4x, the number of presence points (the lecture script already uses 2x --
try increasing to 4x and, for comparison, drop down to 1x).

- Record the estimated elev and grad coefficients (and their standard
  errors, in R/Julia) for each background sample size.
- Do the coefficient point estimates change substantially? Do the
  standard errors shrink as you add more background points, and does
  that make sense given what background points do statistically (they
  approximate the availability of environmental conditions across the
  study area, not real absences)?
- Refit with a different random seed at each background sample size (2x
  background points, three seeds) to separate "effect of more background
  points" from ordinary sampling noise in the random background draw.

## Exercise 2 -- An elevation optimum

The GLM in the lecture script only includes a linear `elev` term, which
forces suitability to increase or decrease monotonically with elevation
-- it cannot represent an interior optimum (a preferred elevation band
with lower suitability on both sides).

- Add a quadratic elevation term (R: `poly(elev, 2, raw = TRUE)` or
  `I(elev^2)`; Python: an `elev**2` column; Julia: `elev + elev^2` in the
  `@formula`) to the logistic regression.
- Compare AIC (R/Julia) or held-out log-loss/AUC (Python) between the
  linear and quadratic models. Does the data support an interior
  optimum?
- Re-plot the partial dependence curve on elevation (grad held at its
  median) for the quadratic model and identify the elevation at which
  predicted suitability peaks. Compare this to the peak found by the
  Random Forest's partial dependence in the lecture script -- are they
  close?

## Exercise 3 -- RF vs. GLM AUC across train/test splits

Using the SAME modeling pipeline as the lecture script, compare Random
Forest and logistic regression AUC on a held-out test split.

- Refit both models across at least 5 different random seeds for the
  train/test split (keep the 75/25 split proportion fixed).
- Report the mean and range of AUC for each model across seeds.
- Is the Random Forest's AUC advantage over the GLM (seen in the lecture
  script's single split) consistent across seeds, or does it sometimes
  reverse? What does that tell you about how much you should trust a
  single train/test split's AUC difference as "the" answer?

## Exercise 4 -- A spatially honest train/test split

The train/test split used in the lecture script is a simple random split
of presence + background points. Because nearby points on BCI's plot are
ecologically similar (spatial autocorrelation), a random split lets
information "leak" between training and test sets -- test points can sit
right next to training points, inflating apparent accuracy.

- Build a spatial block split instead: assign all points with `x < 500`
  to training and all points with `x >= 500` to testing (a left-half /
  right-half split of the plot).
- Refit the GLM and Random Forest on the spatial training block and
  evaluate AUC on the spatial test block.
- Compare this spatially blocked AUC to the randomly split AUC from the
  lecture script for both models. Which model's apparent performance
  drops more when you remove the spatial leakage, and why might a
  high-flexibility model like Random Forest be more prone to this kind
  of inflation than a two-coefficient GLM? (This is exactly the issue
  Lecture 16's treatment of spatial autocorrelation and spatial
  cross-validation will formalize.)
