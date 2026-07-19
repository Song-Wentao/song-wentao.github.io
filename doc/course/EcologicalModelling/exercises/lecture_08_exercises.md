# Lecture 8 Exercises -- Generalized Additive Models

Use the starter scripts in `code/R/lecture_08_gam.R`,
`code/python/lecture_08_gam.py`, and `code/julia/lecture_08_gam.jl` as your
starting point. All three load `data/mite_species.csv` and
`data/mite_env.csv`, compute species richness per site, and fit
richness ~ smooth(WatrCont). Work in whichever language(s) you are
practicing this week.

## Exercise 1 -- A smooth term for SubsDens

Fit `richness ~ s(SubsDens)` (R: `mgcv::gam`; Python: `pygam.LinearGAM`;
Julia: `fit_spline_gam` on `SubsDens`) instead of `WatrCont`.

- Report the effective degrees of freedom (EDF) of `s(SubsDens)` and compare
  it to the EDF of `s(WatrCont)` from the lecture script.
- Plot the fitted smooth for `SubsDens`. Does it show meaningful curvature,
  or is it close to flat/linear?
- Based on the EDF and the shape of the curve, which of the two predictors
  -- `WatrCont` or `SubsDens` -- has a stronger and/or more nonlinear
  relationship with richness at this site?

## Exercise 2 -- A two-dimensional smooth

Fit a bivariate smooth over both environmental variables jointly:
`richness ~ s(WatrCont, SubsDens)` in R (a single isotropic smooth of two
variables), or the nearest equivalent in your language of choice (e.g.
`te(0, 1)` in pygam, or a hand-built two-predictor spline basis in Julia).

- Visualize the fitted surface (R: `plot(gam_model, scheme = 1)` or
  `vis.gam()`; Python: a contour or 3-D surface plot of predictions over a
  grid of the two variables; Julia: a heatmap or contour of predictions).
- Does richness peak somewhere in the interior of the WatrCont-SubsDens
  plane, or does the joint smooth mostly just reflect the WatrCont effect
  from Exercise 1 combined with a flat SubsDens effect?
- What are the risks of fitting a 2-D smooth with only 70 sites? Relate your
  answer to the idea of effective degrees of freedom and overfitting.

## Exercise 3 -- Gaussian vs. Poisson GAM

Compare the Gaussian GAM (`gam_fit` in the lecture script) and the Poisson
GAM (`gam_pois`) fitted to `richness ~ s(WatrCont)`.

- Report the EDF and AIC for each. Since AIC is not directly comparable
  across different response distributions, instead compare the two fitted
  curves visually by overlaying them on the same plot.
- Richness is a non-negative count. What does the Poisson GAM guarantee
  about its fitted values that the Gaussian GAM does not, and why might that
  matter near the low end of the water content gradient?
- In 2-3 sentences, argue for which family you would use if you had to
  report a single "final" model for this relationship, and justify your
  choice using the diagnostics you have available (EDF, AIC, and the shape
  of the fitted curve).

## Exercise 4 -- Basis dimension k and overfitting

Refit the Gaussian GAM `richness ~ s(WatrCont)` several times with different
basis dimensions: a small `k` (e.g. `k = 4` in R, or a small `n_splines` in
pygam, or 1 interior knot in the Julia hand-built basis) and a large `k`
(e.g. `k = 20`, or many splines/knots).

- Report the EDF actually used by the smoothing penalty at each basis
  dimension. Does increasing `k` always increase the EDF by the same
  amount, or does the penalty compensate?
- Plot the fitted smooth at the smallest and largest `k` you tried. At what
  point (if any) does the curve start to look overfit -- wiggling to chase
  individual data points rather than the underlying trend?
- Explain, in your own words, the difference between `k` (the basis
  dimension, a hard upper limit on flexibility) and the EDF (the actual
  flexibility used, after the smoothing penalty). Why does mgcv (and GAMs
  in general) need both a basis dimension *and* a penalty, rather than just
  picking a single "right" number of knots?
