# Lecture 12 Exercises -- Machine Learning

Use the starter scripts in `code/R/lecture_12_machine_learning.R`,
`code/python/lecture_12_machine_learning.py`, and
`code/julia/lecture_12_machine_learning.jl` as your starting point. All
three load `data/dune_species.csv` and `data/dune_env.csv`, join on site,
and fit a random forest and a boosted-tree model classifying `Management`
(4 classes: BF, HF, NM, SF) from the 30 plant species abundance columns.
Work in whichever language(s) you are practicing this week.

Reminder: with only 20 sites, every accuracy number in this lecture is
noisy. The point of these exercises is to build intuition for *how* the
tuning parameters and validation procedures behave, not to squeeze out a
"final" model you would trust operationally.

## Exercise 1 -- Tuning `ntree`/`n_estimators` and `mtry`/`max_features`

Refit the random forest across a small grid of tuning parameters:

- Number of trees (R: `ntree`; Python: `n_estimators`; Julia: `n_trees`):
  try at least 100, 500, and 1500.
- Number of variables tried at each split (R: `mtry`; Python:
  `max_features`; Julia: `n_subfeatures`): try at least 2, 5, 10, and the
  default `sqrt(30) ~= 5`.

For each combination, record the OOB error (R/Python) or 5-fold CV
accuracy (Julia, which has no direct OOB score). Plot error against the
number of trees, with one line per `mtry`/`max_features` value.

- At what number of trees does the error stop changing appreciably? Is
  500 trees (the value used in the lecture script) already past that
  point, or would more help?
- Does increasing `mtry` help, hurt, or barely matter here? Relate your
  answer to the bias-variance tradeoff of decorrelating trees via random
  feature subsets -- what happens to that decorrelation as `mtry`
  approaches the total number of species (30)?

## Exercise 2 -- Random Forest vs. GBM via 5-fold CV

Using the SAME 5-fold split (reuse the fold assignment object from the
lecture script -- `folds` in R, the `cv`/`KFold` object in Python, or a
fixed `Random.seed!()` immediately before each `nfoldCV_*` call in Julia)
compute out-of-sample accuracy for both the random forest and the
gradient-boosted-trees model.

- Report mean accuracy and its spread (SD across folds, or per-fold
  values) for each model.
- Given how few sites are in each test fold (~4), is the difference
  between the two models' accuracy large enough to trust, or is it well
  within the noise you would expect from resampling alone? Justify your
  answer using the per-fold numbers, not just the means.
- Repeat the comparison with a different random seed for the fold
  assignment. Does the "better" model change?

## Exercise 3 -- Interpreting the top-5 species by importance

Using the variable importance output from the random forest (and,
optionally, the boosted-tree model) in your language of choice:

- List the top 5 species and their importance scores.
- Look up (or infer from the `dune_env` variables `Moisture`, `A1`,
  `Manure`, and `Use`) what habitat conditions each of these top species
  is typically associated with (nutrient-rich vs. nutrient-poor soils,
  wet vs. dry conditions, grazing/mowing tolerance, etc.).
- Does the ranking make ecological sense given what `Management` is
  actually capturing (biological farming vs. hobby farming vs. nature
  conservation vs. standard farming)? Where the ranking is surprising,
  propose a plausible confound (e.g. small sample size, correlated
  species, or a species that tracks `Moisture` or `A1` rather than
  `Management` directly) rather than assuming importance implies a causal
  management effect.

## Exercise 4 -- A regression task on the BCI dataset

Switch from classification to regression using `data/BCI_species.csv` and
`data/BCI_env.csv`. Predict a continuous BCI environmental variable (for
example, an elevation, soil, or precipitation-related column, depending
on what is available in `BCI_env.csv`) from the tree species count
matrix, using a regression random forest (R: `randomForest()` with a
numeric response; Python: `RandomForestRegressor`; Julia:
`build_forest`/`nfoldCV_forest` in regression mode).

- Estimate out-of-sample R-squared via 5-fold cross-validation.
- Fit a plain multiple linear regression of the same response on the
  first few principal components of the species matrix (or a small,
  hand-picked subset of common species) and compare its CV R-squared to
  the random forest's.
- In 2-3 sentences, argue for which approach you would use for this
  specific prediction task, and connect your answer to the lecture's
  discussion of when ML is preferable to a classical model versus when
  the classical model's interpretability is worth the potential accuracy
  cost.
