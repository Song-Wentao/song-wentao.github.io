# Lecture 5 Exercises -- Linear Models

Use the starter scripts in `code/R/lecture_05_linear_models.R`,
`code/python/lecture_05_linear_models.py`, and
`code/julia/lecture_05_linear_models.jl` as your starting point. All three
scripts load `data/mite_species.csv` and `data/mite_env.csv`, join them on
`site`, and compute `richness` (the number of species present at each site)
as the response variable. Work in whichever language(s) you are practicing
this week.

## Exercise 1 -- SubsDens alone vs. WatrCont alone

Fit a simple linear model of `richness ~ SubsDens` (substrate density as the
only predictor, no water content).

- Report the slope, its standard error, and its p-value.
- Report R2 and adjusted R2 for this model.
- Compare these to the `richness ~ WatrCont` simple model from the lecture
  script. Which single predictor -- WatrCont or SubsDens -- explains more
  variation in richness? Does the sign of each slope make ecological sense
  (wetter / denser substrate vs. mite richness)?

## Exercise 2 -- Adding a Substrate main effect

Fit `richness ~ Substrate` with Substrate as the only predictor (a one-way
ANOVA-style model), then compare it to the full model
`richness ~ WatrCont + SubsDens + Substrate` from the lecture script.

- Interpret two or three of the Substrate coefficients: what does each one
  represent relative to the reference (baseline) level?
- Using an F-test / ANOVA comparison of nested models (`anova()` in R,
  `sm.stats.anova_lm()` with two fitted models in Python, or `ftest()` in
  Julia), does adding WatrCont and SubsDens to the Substrate-only model
  significantly improve the fit?
- In 2-3 sentences, explain why comparing R2 alone (without adjusting for
  the number of predictors) can be misleading when judging whether the
  extra terms are "worth it."

## Exercise 3 -- An interaction between WatrCont and Substrate

Fit `richness ~ WatrCont * Substrate` (water content, Substrate, and their
interaction) using the same data.

- Is the interaction term statistically significant? Compare this model to
  the additive model `richness ~ WatrCont + Substrate` with a nested-model
  F-test.
- In plain language, what would a significant WatrCont x Substrate
  interaction mean ecologically? (Hint: does the relationship between water
  content and richness have to be the same slope on every substrate type?)
- Would you keep the interaction term in your final model for this dataset?
  Justify your answer using both the test result and parsimony
  (Occam's-razor) reasoning.

## Exercise 4 -- Diagnosing an assumption violation

Fit `richness ~ WatrCont` using only the subset of sites with
`SubsDens > 60` (an extreme, small subset of the full data -- filter the
joined data frame before fitting).

- Produce the four diagnostic plots (residuals vs. fitted, Q-Q, scale-
  location, residuals vs. leverage) for this restricted-data model.
- Which of the four classic assumptions (linearity, independence,
  homoscedasticity, normality of residuals) looks most violated in this
  subset, and which diagnostic plot revealed it?
- Suggest one concrete fix (e.g. a transformation of the response, a
  different error distribution, more data) and briefly explain, in
  anticipation of Lecture 6, why species richness -- a count that cannot go
  below zero -- is not naturally suited to the Gaussian errors that
  `lm()` assumes.
