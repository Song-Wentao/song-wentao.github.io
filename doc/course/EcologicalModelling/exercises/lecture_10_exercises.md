# Lecture 10 Exercises -- Time Series and State-Space Models

Use the starter scripts in `code/R/lecture_10_time_series.R`,
`code/python/lecture_10_time_series.py`, and
`code/julia/lecture_10_time_series.jl` as your starting point. All three
load `data/lynx.csv` (annual Canadian lynx pelts trapped by the Hudson's
Bay Company, 1821-1934), compute `log(trappings)`, and fit an ARIMA model
and a local-level state-space model to the log series. Work in whichever
language(s) you are practicing this week.

## Exercise 1 -- ARIMA on the raw series vs. the log series

Fit an ARIMA model to the **raw** (non-log) `trappings` series instead of
`log(trappings)` (R: `auto.arima(lynx_ts, ...)`; Python:
`ARIMA(trappings, order=(2,0,0)).fit()`; Julia: rerun the AR(2) lagged
regression on `trappings` instead of `log_lynx`).

- Compare the selected/fitted order and coefficients to the log-scale fit
  from the lecture script.
- Look at the residual diagnostics (Ljung-Box test, residual plot) for
  both fits. Does the raw-scale model leave more or less structure in the
  residuals than the log-scale model?
- Explain, using what you know about the raw series' changing variance
  across the century, why the log transform is standard practice before
  fitting a model like ARIMA that assumes constant-variance noise.

## Exercise 2 -- Sensitivity to the observation-noise variance

The lecture script's local-level state-space model fixes the observation
variance at a specific value (R/Python: `0.05`; Julia: `sigma_obs2 = 0.05`)
because the freely-estimated maximum likelihood solution pushes the
observation variance to (essentially) zero for this series.

- Refit the model with the observation variance set much larger (e.g.
  `0.3`) and much smaller (e.g. `0.01`) than the lecture's `0.05`, keeping
  the process variance fixed at the lecture's value.
- Plot the raw log series together with all three smoothed states (small,
  lecture, large observation variance) on one figure.
- Describe in your own words: as the assumed observation variance
  increases, does the smoothed state get closer to the raw series or
  further from it? Why does that make sense given what the observation
  variance represents?

## Exercise 3 -- Reading the cycle length off the ACF

Compute and plot the ACF and PACF of `log(trappings)` yourself (you may
reuse the lecture script's code, but reproduce the numbers independently
rather than just rereading the printed output).

- Identify the lag at which the ACF first crosses zero (going from
  positive to negative), and the lag of the next positive peak after that.
- Use those two lags to estimate the length of the lynx cycle in years.
  How does your estimate compare to the commonly cited "~10-year" cycle
  length for this system?
- Explain why the PACF cutting off sharply after lag 2 supports choosing
  an AR(2) (rather than AR(1) or AR(4)) model for this series.

## Exercise 4 -- ARIMA fitted values vs. the Kalman-smoothed state

Plot the ARIMA model's fitted/in-sample values (R: `fitted(fit_arima)`;
Python: `fit_arima.fittedvalues`; Julia: predicted values from the AR(2)
regression) together with the Kalman-smoothed state from the local-level
model, both overlaid on the raw log series.

- In your own words, what is each of the two lines actually trying to
  estimate? (Hint: one is a one-step-ahead prediction of the next
  observed value; the other is a full-data reconstruction of an
  unobserved true state.)
- Which line is smoother, and why would you expect that given how each
  model is built?
- For a hypothetical management question -- "how many lynx were really
  out there in 1880, given that trapping effort that year was unusually
  low?" -- which of the two model outputs is the more appropriate thing
  to report, and why?
