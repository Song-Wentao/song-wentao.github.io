# Lecture 4 Exercises -- Multivariate and Ordination Methods

Use the starter scripts in `code/R/lecture_04_multivariate_ordination.R`,
`code/python/lecture_04_multivariate_ordination.py`, and
`code/julia/lecture_04_multivariate_ordination.jl` as your starting point.
Work in whichever language(s) you are practicing this week -- all three
scripts load the same data and produce the same outputs, so you can compare
answers across languages if you like.

## Exercise 1 -- PCA on a subset of soil chemistry variables

Using `data/varechem.csv`, run a PCA on **only** the variables `N`, `P`, `K`,
`Ca`, `Mg`, and `pH` (drop the rest), standardizing first as in the lecture
example.

- Report the percentage of variance explained by PC1 and PC2.
- Report the PC1 loadings for each of the six variables.
- Compare this reduced-variable PC1 to the PC1 from the full 14-variable PCA
  in the lecture script. Which variables dominate PC1 in each case, and does
  the interpretation of "what PC1 represents ecologically" change?

## Exercise 2 -- PERMANOVA on Moisture instead of Management

Using `data/dune_species.csv` and `data/dune_env.csv`, compute the
Bray-Curtis dissimilarity matrix for the dune sites (as in the lecture) and
run a PERMANOVA testing whether **Moisture** level (not Management) explains
community composition.

- Report the pseudo-F statistic, R2, and p-value.
- Compare these to the Management PERMANOVA from the lecture script. Which
  variable -- Management or Moisture -- explains more of the variation in
  community composition?
- In 2-3 sentences, explain why testing both variables separately does not
  tell you whether they are independent effects or confounded with each
  other.

## Exercise 3 -- NMDS dimensionality and stress

Using the same dune Bray-Curtis dissimilarity matrix, re-run NMDS with
**three** dimensions (k = 3) instead of two.

- Report the stress value for k = 2 (from the lecture script) and k = 3.
- Using the stress rules of thumb from lecture (< 0.10 excellent, < 0.20
  usable, > 0.20 risky), is a 2-D ordination adequate for this dataset, or is
  the extra dimension needed?
- What is the practical cost of using k = 3 instead of k = 2 when you want to
  show the ordination to a non-specialist audience?

## Exercise 4 -- Hierarchical clustering vs. management groups

Using the dune Bray-Curtis dissimilarity matrix and average-linkage
clustering (as in the lecture), cut the dendrogram into 4 clusters.

- Cross-tabulate the 4 cluster assignments against the 4 `Management`
  categories (`BF`, `HF`, `NM`, `SF`) from `dune_env.csv`.
- Do the data-driven clusters line up well with the management categories,
  or do they cut across them? Point to at least one specific site where the
  cluster assignment and the management category disagree, and suggest a
  possible ecological reason why.
- How does this cross-tabulation relate to (but not replace) the formal
  PERMANOVA test of Management from the lecture?
