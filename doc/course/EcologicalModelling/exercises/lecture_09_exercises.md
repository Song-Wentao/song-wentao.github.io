# Lecture 9 Exercises -- Bayesian Hierarchical Models

Use the starter scripts in `code/R/lecture_09_bayesian_hierarchical.R`,
`code/python/lecture_09_bayesian_hierarchical.py`, and
`code/julia/lecture_09_bayesian_hierarchical.jl` as your starting point. All
three scripts load `data/grouseticks.csv` (Elston et al. 2001) and fit the
same Bayesian nested Poisson hierarchical model as Lecture 7's frequentist
GLMM: `TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD)`, with weakly informative
priors and an MCMC sampler (rstanarm/Stan in R, PyMC/NUTS in Python,
Turing.jl/NUTS in Julia). Work in whichever language(s) you are practicing
this week; keep chains and iterations modest so runs finish in a reasonable
time, and always check the convergence diagnostics before trusting a fit.

## Exercise 1 -- Changing the prior on the LOCATION variance component

The lecture script places a weakly informative prior on the LOCATION-level
random-effect standard deviation (an rstanarm default `decov()` prior in R,
`HalfCauchy(beta=2)` in Python, `Exponential(1)` in Julia).

- Refit the model with a noticeably *tighter* prior on the LOCATION SD (one
  that puts most of its mass on small values, e.g. `HalfCauchy(beta=0.3)` in
  PyMC or `Exponential(3)` in Turing.jl) and again with a noticeably
  *looser* prior (e.g. `HalfCauchy(beta=10)` or `Exponential(0.1)`).
- Compare the posterior mean and 95% credible interval for the LOCATION SD
  across the three priors (tight / original / loose).
- With only 63 locations and a Poisson response, how much does the prior
  choice actually move the posterior? What does this tell you about how
  much information the data alone provide about this variance component?

## Exercise 2 -- Checking convergence diagnostics carefully

Using your fitted model:

- Report the R-hat and effective sample size (ESS) for every fixed effect
  (Intercept, YEAR96, YEAR97, cHEIGHT) and for both variance components
  (sigma_LOCATION, sigma_BROOD).
- Identify which parameter(s), if any, have the worst R-hat and/or lowest
  ESS. Variance components in models with modest sampling budgets (few
  chains, few iterations) are often the slowest-mixing parameters --
  confirm whether that pattern holds here.
- Produce a trace plot for at least one fixed effect and one variance
  component (`plot(fit_bayes)` in R, `az.plot_trace()` in Python,
  `plot(chain)` in Julia). Do the chains look like they are exploring the
  same region ("fuzzy caterpillars" overlapping), or do they show drift,
  stickiness, or divergent behavior?
- If you increase the number of post-warmup iterations (e.g. double them),
  does R-hat improve? By how much?

## Exercise 3 -- Adding a random slope for altitude

Extend the hierarchical model so the effect of `cHEIGHT` is allowed to vary
by LOCATION, mirroring Lecture 7's Exercise 1 but in the Bayesian framework:

- Add a second, non-centered random effect for `cHEIGHT` by LOCATION (a new
  `sigma_cheight_LOCATION` variance component and a corresponding vector of
  per-location slope deviations), refit, and inspect the posterior for the
  new variance component.
- Compare this random-slope model to the random-intercept-only model using
  leave-one-out cross-validation (`loo()` in R/rstanarm, `az.compare()` with
  PSIS-LOO in Python).
- Does the data support letting the altitude effect vary by location, or
  does the added variance component's posterior sit close to zero with a
  credible interval that comfortably includes zero?

## Exercise 4 -- Credible interval vs. confidence interval, concretely

Using the posterior draws for the YEAR97 effect from your fitted model:

- Exponentiate every posterior draw of the YEAR97 coefficient to put it on
  the rate-ratio scale, then compute the 95% credible interval of the
  exponentiated draws.
- Compare this credible interval, in both width and interpretation, to the
  95% confidence interval Lecture 7's `glmer()` fit produced for the same
  coefficient (exponentiate `confint()` on the YEAR97 fixed effect).
- Write 3-4 sentences, in your own words, explaining the difference between
  "there is a 95% probability the true rate ratio lies in this interval"
  (the Bayesian credible-interval interpretation) and "if we repeated this
  study many times, 95% of the confidence intervals so constructed would
  contain the true rate ratio" (the frequentist confidence-interval
  interpretation). Which statement matches what most people actually want
  to say when they report an interval?
