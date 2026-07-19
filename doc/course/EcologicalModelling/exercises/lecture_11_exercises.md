# Lecture 11 Exercises -- Occupancy and N-mixture Models

Use `data/crossbill_occupancy_sim.csv` and the lecture scripts
(`code/R/lecture_11_occupancy.R`, `code/python/lecture_11_occupancy.py`,
`code/julia/lecture_11_occupancy.jl`) as your starting point. Work in the
language of your choice (or try more than one and compare).

Recall: this dataset is simulated but calibrated to the design and
parameter ranges of the Swiss crossbill/willow tit breeding bird survey
(Schmid, Zbinden & Keller 2004; Royle & Kery 2007). The fitting code is
identical in structure to what you would run on the real `unmarked::crossbill`
dataset.

## Exercise 1 -- Detection probability and the naive-vs-estimated gap

Modify `code/R/generate_crossbill_data.R` to produce two additional
datasets: one with lower detection probability (e.g. set `alpha0 = -0.5`
so mean p is closer to 0.3) and one with higher detection probability
(e.g. `alpha0 = 1.5` so mean p is closer to 0.85). Keep everything else
(sample size, psi model, seed) the same. For each dataset, compute the
naive occupancy estimate and the model-estimated occupancy. How does the
gap between naive and model-estimated occupancy change as detection
probability increases? Explain in one or two sentences why that pattern
makes sense given the observation-process formula y_ij ~ Bernoulli(z_i * p_ij).

## Exercise 2 -- A quadratic elevation effect

Crossbills depend on conifer seed crops that are common at a range of
mid-to-high elevations but may become less suitable at very high or very
low sites, suggesting a hump-shaped (quadratic) relationship between psi
and elevation rather than a purely linear one. Extend the occupancy
sub-model to `psi_i = plogis(b0 + b1*elev_z_i + b2*elev_z_i^2)`, add the
extra parameter to the log-likelihood function, and refit by maximum
likelihood. Compare AIC (`2*k - 2*logLik`, where k is the number of
estimated parameters) between the linear and quadratic models. Does the
data support adding the quadratic term?

## Exercise 3 -- How many visits do you actually need?

Refit the model using only the first 2 of the 3 repeat visits (drop
`det3`/`date3`), then refit again using only 1 visit. Compare the
estimated coefficients and their standard errors across the 3-visit,
2-visit, and 1-visit fits. What happens to the precision (standard
errors) of the psi and p coefficients as you remove visits? At 1 visit,
does the optimizer still converge to a sensible, well-identified
answer -- or do you see evidence of the identifiability problem discussed
in lecture (psi and p trading off against each other)?

## Exercise 4 -- N-mixture models: from detect/non-detect to counts

Suppose that instead of recording presence/absence at each visit, field
observers had recorded the *number of individual crossbills* seen at each
visit (a common alternative protocol, modeled with N-mixture models;
Royle 2004, Biometrics). Simulate a small N-mixture dataset yourself:
for each of 100 sites, draw a true abundance `N_i ~ Poisson(lambda_i)`
with `lambda_i` depending on an elevation covariate (as in the lecture),
then for 3 repeat visits draw counts `C_ij ~ Binomial(N_i, p)` with a
fixed detection probability p (e.g. 0.5). Write out (in words or as
pseudocode -- you do not need to fit it) the marginal likelihood for one
site, summing the binomial-Poisson mixture over the unknown true
abundance N_i from N_i = max(C_i1,...,C_iJ) up to some reasonable upper
bound. How does this likelihood generalize the occupancy likelihood from
lecture?
