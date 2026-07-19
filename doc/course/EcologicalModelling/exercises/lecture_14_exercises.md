# Lecture 14 Exercises -- Population Modeling

Use the starter scripts in `code/R/lecture_14_population_modeling.R`,
`code/python/lecture_14_population_modeling.py`, and
`code/julia/lecture_14_population_modeling.jl` as your starting point. All
three scripts hard-code the same 5-stage Lefkovitch loggerhead sea turtle
projection matrix `A` (representative of Crouse, Crowder & Caswell 1987 in
stage structure and qualitative conclusions, but not the exact published
values -- see the provenance note at the top of each script), compute
lambda and the stable stage distribution via `eigen()` / `numpy.linalg.eig`
/ `LinearAlgebra.eigen`, project the population 30 years forward, and
compute elasticities by finite-difference perturbation of each nonzero
matrix entry. Work in whichever language(s) you are practicing this week.

## Exercise 1 -- Simulating Turtle Excluder Device (TED) adoption

Shrimp-trawl bycatch was historically the dominant source of mortality for
juvenile and subadult loggerheads. Turtle Excluder Devices (TEDs) reduce
that bycatch mortality substantially.

- Increase the small- and large-juvenile survival entries (the stasis terms
  `A[2,2]`/`A[3,3]` in R and Julia, `A[1,1]`/`A[2,2]` in Python, plus the
  corresponding growth terms `A[3,2]`/`A[4,3]` in R/Julia, `A[2,1]`/`A[3,2]`
  in Python) by 10%, keeping every other entry fixed. Recompute lambda.
- Separately, restore the original survival values and instead increase
  adult fecundity (the top-row entry feeding hatchlings from adults) by
  10%. Recompute lambda for this scenario too.
- Compare the two resulting lambdas to the original lambda ~0.95. Which
  intervention -- improving juvenile/subadult survival (TEDs) or increasing
  fecundity (e.g. nest protection) -- moves the population closer to
  lambda = 1, and by how much? Does this match what the elasticity analysis
  in the lecture predicted it would?

## Exercise 2 -- Stable stage distribution vs. an observed distribution

- Using the matrix as given, report the stable stage distribution (the
  normalized dominant right eigenvector) the starter script already
  computes.
- Suppose a hypothetical beach and in-water survey instead found the
  population distributed roughly as
  `[0.10, 0.55, 0.20, 0.10, 0.05]` across
  Eggs/Hatchlings, Small Juveniles, Large Juveniles, Subadults, and Adults.
  Compute the absolute difference between this observed distribution and
  the stable stage distribution, stage by stage.
- Is the hypothetical observed population closer to or farther from its
  stable structure than a population that starts exactly proportional to
  the stable stage distribution? When a population's current structure
  differs from its stable structure, short-term ("transient") growth can
  temporarily run faster or slower than lambda predicts -- based on where
  this hypothetical population is over- or under-represented relative to
  the stable distribution, would you expect transient growth to run above
  or below the asymptotic lambda in the next few years?

## Exercise 3 -- Identifying the highest-elasticity entry

- From the ranked elasticity table the starter script prints, identify the
  single nonzero matrix entry with the highest elasticity.
- Classify it: is it a fecundity term (top row), a stasis term
  (survival-in-place, on the diagonal), or a growth term (transition to the
  next stage, on the subdiagonal)?
- In 2-3 sentences, explain in your own words why a small proportional
  change to that one entry produces a disproportionately large proportional
  change in lambda, and connect this back to why Crouse, Crowder & Caswell
  (1987)'s elasticity analysis reoriented sea turtle conservation policy
  toward reducing bycatch mortality rather than only protecting nests.

## Exercise 4 -- Starting structure and transient dynamics

- Re-run the 30-year population projection starting from a stage vector
  weighted almost entirely toward adults, e.g.
  `c(100, 100, 100, 100, 5000)` (R) / `[100, 100, 100, 100, 5000]`
  (Python/Julia), instead of the juvenile-heavy starting vector used in the
  lecture script.
- Plot both trajectories (juvenile-heavy start vs. adult-heavy start) on
  the same log-scale axes, total population size vs. year.
- Do both trajectories converge to the same long-run growth rate lambda?
  Describe what differs between the two trajectories in the first several
  years (transient dynamics driven by the mismatch between each starting
  vector and the stable stage distribution) versus what happens once both
  populations have settled into their stable stage structure.
