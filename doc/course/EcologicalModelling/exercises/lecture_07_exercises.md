# Lecture 7 Exercises -- Mixed-Effects Models

Use the starter scripts in `code/R/lecture_07_mixed_models.R`,
`code/python/lecture_07_mixed_models.py`, and
`code/julia/lecture_07_mixed_models.jl` as your starting point. All three
scripts load `data/grouseticks.csv` (Elston et al. 2001), cast BROOD,
LOCATION, and YEAR as factors, and fit a Poisson GLMM of
`TICKS ~ YEAR + cHEIGHT` with random intercepts for LOCATION and BROOD
(BROOD nested within LOCATION). Work in whichever language(s) you are
practicing this week; R's `glmer()` fit is the authoritative reference if
your Python or Julia numbers disagree.

## Exercise 1 -- A random slope for altitude by LOCATION

Extend the nested Poisson GLMM so that the effect of `cHEIGHT` is allowed to
vary by LOCATION, rather than forcing every location to share exactly the
same altitude slope. In R this is:

```r
glmer(TICKS ~ YEAR + cHEIGHT + (1 + cHEIGHT | LOCATION) + (1 | BROOD),
      data = dat, family = poisson)
```

- Fit this random-slope model and compare its AIC to the random-intercept-
  only model from the lecture script (`fit_glmm_nested` /
  `fit_glmm_crossed`).
- Does allowing the altitude effect to vary by location meaningfully
  improve the fit? Report the estimated correlation between the random
  intercept and random slope, if the model converges cleanly.
- In your own words, what ecological question does a random slope answer
  that a random intercept alone cannot?

## Exercise 2 -- Computing and interpreting the ICC by hand

Using the variance components printed by your fitted nested Poisson GLMM
(`VarCorr()` in R, or the variance-component output from your Julia/Python
fit):

- Compute the intraclass correlation (share of random-effect variance) at
  the LOCATION level and at the BROOD level, following the approach shown
  in the lecture script's Section 5.
- Which level -- LOCATION or BROOD -- accounts for more of the
  unexplained, group-level variation in tick counts? State your answer as
  a percentage.
- Explain in 2-3 sentences what this tells you biologically: are ticks
  more strongly clustered by broad geography (LOCATION) or by the
  individual brood's circumstances (nest microhabitat, parental care,
  hatch timing)?

## Exercise 3 -- Dropping BROOD: LOCATION-only random effects

Refit the Poisson GLMM using only LOCATION as a random effect, i.e.

```r
glmer(TICKS ~ YEAR + cHEIGHT + (1 | LOCATION), data = dat, family = poisson)
```

- Compare AIC and BIC of this LOCATION-only model to the full nested model
  (LOCATION + BROOD).
- Compare the fixed-effect standard errors (YEAR, cHEIGHT) between the two
  models. Do they get noticeably larger or smaller when BROOD is dropped?
- Explain why dropping a real source of non-independence (BROOD) from the
  random-effect structure, even though LOCATION is still accounted for,
  can still leave you exposed to a milder form of pseudoreplication.

## Exercise 4 -- Shrinkage and partial pooling

Extract the brood-level random effects (BLUPs) from your fitted nested
Poisson GLMM (`ranef()` in R, `lmm_result.random_effects` in the Python
fallback script, or `ranef()` in Julia's MixedModels.jl) and the number of
chicks observed in each brood.

- Make a scatterplot of each brood's estimated random effect (y-axis)
  against the number of chicks in that brood (x-axis).
- Confirm the shrinkage pattern: broods with only 1-2 chicks should have
  random-effect estimates pulled closer to zero (the population average)
  than broods with many chicks, even if their raw sample mean TICKS is
  extreme.
- In 2-3 sentences, connect this shrinkage behavior to Lecture 9's
  Bayesian hierarchical models: what is "partial pooling," and why is a
  mixed model already doing a simplified, frequentist version of it?
