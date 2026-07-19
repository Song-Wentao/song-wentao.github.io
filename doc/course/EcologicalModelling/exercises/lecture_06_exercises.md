# Lecture 6 Exercises -- Generalized Linear Models

Use the starter scripts in `code/R/lecture_06_glm.R`,
`code/python/lecture_06_glm.py`, and `code/julia/lecture_06_glm.jl` as your
starting point. Work in whichever language(s) you are practicing this week
-- all three scripts load the same `data/grouseticks.csv` data and produce
the same outputs, so you can compare answers across languages if you like.

## Exercise 1 -- HEIGHT instead of cHEIGHT

Refit the Poisson GLM from lecture using raw `HEIGHT` in place of
`cHEIGHT`: `TICKS ~ YEAR + HEIGHT`.

- Report the coefficient for `HEIGHT` and compare it numerically to the
  coefficient for `cHEIGHT` in the lecture model. Are they the same, or
  different -- and why?
- Compare the interpretation of the intercept in the two models. What
  altitude does "cHEIGHT = 0" correspond to, and what does "HEIGHT = 0"
  correspond to? Which intercept is more meaningful to report to a
  non-technical audience?
- Do the predicted tick counts from the two models differ at a given chick's
  actual altitude? Check this for one or two rows of the data.

## Exercise 2 -- Negative binomial vs. Poisson: AIC and dispersion

Using the negative-binomial model already fit in the lecture script
(`TICKS ~ YEAR + cHEIGHT`), compare it formally to the Poisson model.

- Report the AIC of both models and the difference between them.
- Report the estimated dispersion parameter (theta in R/Julia, or the
  profiled alpha in the Python script) and explain in your own words what
  it means for the negative-binomial variance function relative to Poisson's
  variance = mean.
- The lecture computed a Poisson dispersion ratio (residual deviance /
  residual df) of roughly 8-9. Explain why this number, on its own, already
  told us the negative-binomial model was needed before we ever compared
  AICs.

## Exercise 3 -- Binomial GLM for tick presence/absence

Using the presence/absence recoding from the lecture (`present = TICKS >
0`), fit a binomial GLM `present ~ cHEIGHT` (already done in the lecture
script) and extend it.

- Report the odds ratio for `cHEIGHT` (`exp(coef)`) and interpret it in
  plain language: for a 10-unit increase in `cHEIGHT`, how do the odds of
  tick presence change?
- Add `YEAR` to the model (`present ~ YEAR + cHEIGHT`). Does accounting for
  year change the `cHEIGHT` coefficient much? What does that tell you about
  whether altitude effects are consistent across years?
- Using your `YEAR + cHEIGHT` model, compute predicted probabilities of
  tick presence for a chick at `cHEIGHT = 0` in each of the three years.
  Which year had the highest predicted probability of tick presence at
  average altitude?

## Exercise 4 -- Comparing rate ratios across models

Using the Poisson and negative-binomial models from the lecture (both
`TICKS ~ YEAR + cHEIGHT`), compute the exponentiated coefficients (rate
ratios) for `YEAR96` and `YEAR97` from each model.

- Are the rate ratios similar between the Poisson and negative-binomial
  fits? Should they be similar, given that both models use the same log
  link and linear predictor -- what does the negative-binomial model change
  relative to Poisson, and what does it leave the same?
- Which model's standard errors on the `YEAR` coefficients are larger, and
  why does that make ecological sense given what you know about
  overdispersion?
- In 2-3 sentences, explain to a lab-mate who has not seen this lecture why
  reporting p-values from the Poisson model here would be misleading.
