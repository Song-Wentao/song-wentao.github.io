# Lecture 3 Exercises — Basic Statistical Analysis

Work in whichever language (R, Python, or Julia) you are most comfortable with,
but try to reproduce at least one exercise in a second language for practice.
Assume your working directory is the repository root (the folder containing
`data/`, `code/`, `figures/`, `exercises/`), and read files from `data/`.

## Exercise 1 — Two-sample t-test

Using `data/mite_env.csv`, compare `SubsDens` (substrate density) between two
`Substrate` groups of your choice (for example `"Litter"` vs. `"Barepeat"`).

1. Compute the mean and standard deviation of `SubsDens` in each group.
2. Run a two-sample t-test (Welch's, unequal variances) and report the
   t-statistic, degrees of freedom, and p-value.
3. In 2-3 sentences, state whether the difference is statistically significant
   at alpha = 0.05, and whether you think it is ecologically meaningful given
   the size of the difference.

## Exercise 2 — One-way ANOVA and Tukey HSD

Using `data/mite_env.csv`, run a one-way ANOVA of `SubsDens ~ Substrate`
across all seven Substrate categories.

1. Report the F-statistic, degrees of freedom, and p-value.
2. Compute eta-squared (or R^2) for the model and interpret the proportion of
   variance explained.
3. Run a Tukey HSD post-hoc test. Which pairs of Substrate categories differ
   significantly (p < 0.05)? List them.

## Exercise 3 — Correlation: Humdepth and pH

Using `data/varechem.csv`:

1. Compute the Pearson correlation coefficient between `Humdepth` (humus
   depth) and `pH`, along with its p-value.
2. Compute the Spearman rank correlation between the same two variables.
3. Do the Pearson and Spearman coefficients agree in sign and approximate
   magnitude? If they disagree noticeably, what does that suggest about the
   relationship (e.g. non-linearity, outliers)? Make a scatterplot of
   `Humdepth` vs. `pH` to check your reasoning.

## Exercise 4 — Chi-square test of independence

Using `data/mite_env.csv`, build a contingency table of `Shrub` (None/Few/Many)
by `Substrate` (the seven substrate categories).

1. Print the contingency table of observed counts.
2. Run a chi-square test of independence and report the chi-square statistic,
   degrees of freedom, and p-value.
3. Interpret the result: does shrub cover appear to be distributed
   independently of substrate type at this site, or are certain
   Shrub/Substrate combinations over- or under-represented? Note any cells
   with low expected counts and what that implies for the reliability of the
   test.
