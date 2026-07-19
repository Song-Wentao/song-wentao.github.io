# Lecture 16 Exercises -- Spatial Modeling

Use the starter scripts in `code/R/lecture_16_spatial_modeling.R`,
`code/python/lecture_16_spatial_modeling.py`, and
`code/julia/lecture_16_spatial_modeling.jl` as your starting point. Part 1
of each script loads `data/mite_env.csv` and computes Moran's I for
`WatrCont` using a k-nearest-neighbour (k=5) spatial weights matrix. Part
2 loads `data/bei_points.csv` and `data/bei_covariates_grid.csv` and fits
an inhomogeneous Poisson point process (R: `spatstat::ppm`; all three
languages: a discretized 25 x 10 grid Poisson GLM) to the Beilschmiedia
pendula tree locations. Work in whichever language(s) you are practicing
this week.

## Exercise 1 -- Moran's I at different neighbourhood sizes

Recompute Moran's I for `WatrCont` using k = 3 and k = 10 nearest
neighbours instead of the k = 5 used in the lecture script (just change
the `k` variable and rebuild the weights matrix).

- Report the observed I and its permutation p-value for k = 3, 5, and 10.
- Does the strength (and significance) of spatial autocorrelation change
  much across these neighbourhood sizes?
- Relate your answer to the physical spacing of the mite cores (look at
  the x, y ranges printed at the top of the script) -- what does a
  k-dependent answer tell you about the spatial *scale* at which water
  content is patchy at Lac Cromwell?

## Exercise 2 -- A GAM spatial smooth, s(x, y)

Using R and `mgcv`, fit `gam(WatrCont ~ s(x, y), data = mite_env)` (already
fit in the lecture script as `gam_spatial`) and produce a visualization of
the fitted 2-D smooth surface (e.g. `vis.gam(gam_spatial, plot.type =
"contour")` or `plot(gam_spatial, scheme = 2)`).

- Where in the plot is predicted water content highest? Lowest?
- Compare this to a simple scatterplot of the raw x, y coordinates
  coloured by `WatrCont` -- does the smooth surface look like a
  reasonable, de-noised version of the raw spatial pattern, or does it
  look over- or under-smoothed?
- Compute Moran's I on the residuals of `gam_spatial` (the lecture script
  already does this) and compare it to Moran's I of the raw data. In your
  own words, explain *why* fitting `s(x, y)` reduces residual spatial
  autocorrelation -- what is the smooth term actually absorbing?

## Exercise 3 -- Point process model selection: elevation alone vs. elevation + gradient

Using the R script's `spatstat::ppm` models (`ppm_null`, `ppm_elev`,
`ppm_full`) or the discretized Poisson GLM equivalents in any language
(`glm_null`, `glm_elev`, `glm_full`):

- Report AIC for all three models (homogeneous, elevation-only,
  elevation + gradient) and identify the best model.
- Interpret the likelihood ratio test comparing elevation-only to
  elevation + gradient (already computed in each script). Does gradient
  add real explanatory power for Beilschmiedia's spatial distribution, or
  is elevation alone doing most of the work?
- Beilschmiedia pendula is a shade-tolerant canopy tree on Barro Colorado
  Island. Does the sign and magnitude of the fitted elevation and
  gradient coefficients make ecological sense (e.g. steep slopes often
  correspond to different soil drainage and light conditions than flat
  terrain)?

## Exercise 4 -- Grid resolution and the discretized point process

The discretized Poisson GLM in Part 2 used a 25 x 10 cell grid. Refit it
with a much coarser grid (e.g. 10 x 4 cells) and a much finer grid (e.g.
50 x 20 cells), keeping the elevation + gradient model structure fixed.

- How do the fitted elev/grad coefficients change across the three grid
  resolutions? How does AIC change (note that AIC is not directly
  comparable across different binnings of the same data -- explain why,
  and what you can and cannot conclude from comparing AIC across grid
  resolutions)?
- What goes wrong with a grid that is too coarse (a handful of huge
  cells)? What goes wrong with a grid that is too fine (thousands of
  mostly-empty cells)? Connect your answer to the general bias-variance
  tradeoff you have seen elsewhere in this course (e.g. smoothing
  parameter selection in Lecture 8's GAMs).

## Exercise 5 -- Interpreting the fitted intensity surface

Using the fitted intensity surface saved to
`figures/lecture_16_bei_intensity_surface.png` (or by recomputing
`cell_dat$fitted_intensity` / `cell_dat.fitted_intensity` yourself):

- Identify the grid cell(s) with the highest fitted intensity. What are
  their elevation and gradient values?
- Identify one or two cells where the observed density and the fitted
  intensity disagree noticeably (a "hotspot" the model under-predicts, or
  a "coldspot" it over-predicts). Propose an ecological or methodological
  explanation for the mismatch -- e.g. a covariate not included in the
  model (soil type, canopy gap history, dispersal limitation from parent
  trees), or a small-sample artifact of a sparsely populated cell.
- In 2-3 sentences, connect this exercise back to Lecture 13: how is this
  point process model doing something genuinely different from -- not
  just a fancier version of -- the presence-background SDM fit there?
