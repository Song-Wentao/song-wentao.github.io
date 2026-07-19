"""
Lecture 10 -- Time Series and State-Space Models
Ecological Modelling with R, Python, and Julia

Dataset:
    data/lynx.csv (year, trappings)
    114 consecutive annual counts (1821-1934) of Canadian lynx (Lynx
    canadensis) pelts trapped and traded by the Hudson's Bay Company.
    Originally compiled by MacLulich (1937); the classic AR(2) analysis
    is Moran (1953); the dataset is the same series popularized as a
    teaching example by Campbell & Walker (1977) (base R's built-in
    "lynx"). Extensively reanalyzed for density dependence and
    predator-prey dynamics by Stenseth, Falck, Bjornstad & Krebs (1997),
    PNAS 94:5147-52, and Stenseth et al. (1998, Science; 1999) -- the
    lynx-hare cycle is one of the most heavily studied ecological time
    series in existence.

Methods:
    1. Plot the raw trapping series -- the ~10-year cycle is visible by eye
    2. Log-transform to stabilize variance
    3. ACF / PACF of log(trappings) to diagnose autocorrelation structure
    4. ARIMA fit to log(trappings) via statsmodels.tsa.arima.model.ARIMA,
       order chosen from the ACF/PACF diagnosis (AR(2), matching the
       classical Moran analysis and R's auto.arima AR component)
    5. A local-level state-space model (random walk state + noisy
       observation) fit via
       statsmodels.tsa.statespace.structural.UnobservedComponents --
       a genuine Kalman filter/smoother -- with the smoothed state
       extracted via .smoothed_state
    6. Figure: raw log series vs. Kalman-smoothed state, saved to
       figures/lecture_10_lynx_state_space.png

Assumes working directory = repository root, i.e. run as:
    python3 code/python/lecture_10_time_series.py
"""

import os

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from statsmodels.tsa.stattools import acf, pacf, adfuller
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.statespace.structural import UnobservedComponents
from statsmodels.stats.diagnostic import acorr_ljungbox

os.makedirs("figures", exist_ok=True)

print("=== Lecture 10: Time Series and State-Space Models (Python) ===\n")

# ------------------------------------------------------------
# 0. Load the data
# ------------------------------------------------------------
lynx = pd.read_csv("data/lynx.csv")
years = lynx["year"].to_numpy()
trappings = lynx["trappings"].to_numpy(dtype=float)

print("--- Lynx trappings summary ---")
print(pd.Series(trappings).describe())
print(f"Years: {years.min()} - {years.max()} ({len(years)} years)\n")

# ------------------------------------------------------------
# 1. Raw series plot -- the cycle is visible by eye
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(9, 4.5))
ax.plot(years, trappings, "o-", color="dimgray", markersize=3, linewidth=1)
ax.set_xlabel("Year")
ax.set_ylabel("Pelts trapped")
ax.set_title("Canadian lynx pelts, Hudson's Bay Company (1821-1934)")
fig.tight_layout()
fig.savefig("figures/lecture_10_lynx_raw.png", dpi=150)
plt.close(fig)
print("Saved figures/lecture_10_lynx_raw.png\n")

# ------------------------------------------------------------
# 2. Log transform -- stabilize variance across the century
# ------------------------------------------------------------
log_lynx = np.log(trappings)
print("--- log(trappings) summary ---")
print(pd.Series(log_lynx).describe())
print()

# ------------------------------------------------------------
# 3. ACF and PACF of log(trappings)
# ------------------------------------------------------------
fig, axes = plt.subplots(1, 2, figsize=(11, 4.2))
plot_acf(log_lynx, lags=20, ax=axes[0], title="ACF: log(trappings)")
plot_pacf(log_lynx, lags=20, ax=axes[1], method="ywm",
          title="PACF: log(trappings)")
fig.tight_layout()
fig.savefig("figures/lecture_10_lynx_acf_pacf.png", dpi=150)
plt.close(fig)
print("Saved figures/lecture_10_lynx_acf_pacf.png")

acf_vals = acf(log_lynx, nlags=10)
pacf_vals = pacf(log_lynx, nlags=10, method="ywm")
print("--- ACF at lags 1-10 ---")
print(np.round(acf_vals[1:11], 3))
print("--- PACF at lags 1-10 ---")
print(np.round(pacf_vals[1:11], 3))
print()

# Augmented Dickey-Fuller test: is the log series stationary?
adf_stat, adf_p, *_ = adfuller(log_lynx)
print(f"--- Augmented Dickey-Fuller test on log(trappings) ---")
print(f"ADF statistic = {adf_stat:.3f}, p-value = {adf_p:.4f}")
print("(A small p-value rejects a unit root -- the series is stationary,")
print(" consistent with fitting ARIMA with d = 0, no differencing.)\n")

# ------------------------------------------------------------
# 4. ARIMA fit to log(trappings)
#    statsmodels has no built-in automatic order search (unlike R's
#    auto.arima); order (2,0,0) is read directly off the ACF/PACF above --
#    PACF cuts off sharply after lag 2, ACF oscillates rather than decays
#    smoothly -- the classical AR(2) signature for this exact series
#    going back to Moran (1953).
# ------------------------------------------------------------
fit_arima = ARIMA(log_lynx, order=(2, 0, 0)).fit()
print("--- ARIMA(2,0,0) fit to log(trappings) ---")
print(fit_arima.summary())
print()
print("AR coefficients:", np.round(fit_arima.arparams, 4))
print("AIC:", round(fit_arima.aic, 2))
print()

lb = acorr_ljungbox(fit_arima.resid, lags=[10], return_df=True)
print("--- Ljung-Box test on ARIMA residuals (lag = 10) ---")
print(lb)
print("(A large p-value here supports the fitted order: little")
print(" autocorrelation left in the residuals.)\n")

# ------------------------------------------------------------
# 5. Local-level state-space model via UnobservedComponents
#    State equation:       x_t = x_{t-1} + w_t,  w_t ~ N(0, sigma_level^2)
#    Observation equation: y_t = x_t + v_t,       v_t ~ N(0, sigma_irregular^2)
# ------------------------------------------------------------
mod = UnobservedComponents(log_lynx, level="local level")
res = mod.fit(disp=False)
print("--- UnobservedComponents local-level state-space model (free MLE) ---")
print(res.summary())
print()
print("Estimated variances:")
for name, val in zip(res.model.param_names, res.params):
    print(f"  {name}: {val:.4f}")
print("  sigma2.level     = process (state) noise variance")
print("  sigma2.irregular = observation noise variance")
print("NOTE: the unconstrained MLE pushes sigma2.irregular to (essentially)")
print("zero for this series -- the same degenerate-boundary result R's")
print("StructTS finds. Given a pure random-walk state, the model decides")
print("almost none of the year-to-year wiggle is measurement noise, so the")
print("smoothed state would equal the raw series almost exactly, which")
print("defeats the point of the demo. To make the state/observation split")
print("visible, we also fit a second version with sigma2.irregular FIXED")
print("at a modest, plausible value (0.05) via fit_constrained() rather")
print("than freely estimated -- exactly the sensitivity analysis explored")
print("in Exercise 2.\n")

res_fixed = mod.fit_constrained({"sigma2.irregular": 0.05}, disp=False)
print("--- Local-level model, observation variance fixed at 0.05 ---")
print(res_fixed.params)
print()

# Kalman smoother: best reconstruction of the hidden state using ALL data
state_est = res_fixed.smoothed_state[0]

print("--- First 6 years: raw log series vs. Kalman-smoothed state ---")
preview = pd.DataFrame({
    "year": years[:6],
    "log_trappings": np.round(log_lynx[:6], 3),
    "smoothed_state": np.round(state_est[:6], 3),
})
print(preview.to_string(index=False))
print()

# ------------------------------------------------------------
# 6. Figure: raw log series vs. Kalman-smoothed state
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(9, 5))
ax.plot(years, log_lynx, "o-", color="grey", markersize=3, linewidth=1,
        label="Observed log(trappings)")
ax.plot(years, state_est, color="firebrick", linewidth=2,
        label="Kalman-smoothed state")
ax.set_xlabel("Year")
ax.set_ylabel("log(pelts trapped)")
ax.set_title("Lynx: raw log series vs. Kalman-smoothed state (local-level model)")
ax.legend(frameon=False)
fig.tight_layout()
fig.savefig("figures/lecture_10_lynx_state_space.png", dpi=150)
plt.close(fig)
print("Saved figures/lecture_10_lynx_state_space.png\n")

print("=== Done ===")

# --- EXERCISES ---
# TODO Exercise 1: Fit ARIMA to the RAW (non-log) trappings series
#   (ARIMA(trappings, order=(2,0,0)).fit()). Compare the fitted order,
#   coefficients, and residual diagnostics to the log-scale fit above.
# TODO Exercise 2: Refit UnobservedComponents with a fixed, non-default
#   observation-noise variance (see the `res.params` / start_params
#   arguments, or simply compare the freely-estimated fit here to a
#   manual Kalman run at a much larger and much smaller sigma2.irregular).
#   Compare how much the smoothed state changes.
# TODO Exercise 3: Reproduce the plot_acf()/plot_pacf() plots yourself
#   and identify the cycle length from the lag of the ACF's
#   zero-crossings and the spacing between positive peaks.
# TODO Exercise 4: Plot the ARIMA fitted values (fit_arima.fittedvalues)
#   against the Kalman-smoothed state on the same axes and describe, in
#   your own words, what each line is actually estimating.
