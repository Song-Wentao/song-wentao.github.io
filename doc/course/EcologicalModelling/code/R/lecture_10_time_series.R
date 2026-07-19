# ============================================================
# Lecture 10 -- Time Series and State-Space Models
# Ecological Modelling with R, Python, and Julia
#
# Dataset:
#   data/lynx.csv (year, trappings)
#   114 consecutive annual counts (1821-1934) of Canadian lynx (Lynx
#   canadensis) pelts trapped and traded by the Hudson's Bay Company.
#   Originally compiled by MacLulich (1937); the classic AR(2) analysis
#   is Moran (1953); the dataset is the base-R built-in "lynx" series,
#   popularized as a teaching example by Campbell & Walker (1977).
#   Extensively reanalyzed for density dependence and predator-prey
#   dynamics by Stenseth, Falck, Bjornstad & Krebs (1997), PNAS 94:5147-52,
#   and Stenseth et al. (1998, Science; 1999) -- the lynx-hare cycle is
#   one of the most heavily studied ecological time series in existence.
#
# Methods:
#   1. Plot the raw trapping series -- the ~10-year cycle is visible by eye
#   2. Log-transform to stabilize variance
#   3. ACF / PACF of log(trappings) to diagnose autocorrelation structure
#   4. ARIMA fit to log(trappings) via forecast::auto.arima() (automatic
#      order selection)
#   5. A local-level state-space model (random walk state + noisy
#      observation) fit via stats::StructTS() -- a genuine base-R Kalman
#      filter/smoother -- with the smoothed state extracted via tsSmooth()
#   6. Figure: raw log series vs. Kalman-smoothed state, saved to
#      figures/lecture_10_lynx_state_space.png
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_10_time_series.R
# ============================================================

suppressMessages(library(forecast))

dir.create("figures", showWarnings = FALSE)

## ------------------------------------------------------------
## 0. Load the data and build a ts() object
## ------------------------------------------------------------
lynx <- read.csv("data/lynx.csv", stringsAsFactors = FALSE)
lynx_ts <- ts(lynx$trappings, start = lynx$year[1])

cat("=== Lecture 10: Time Series and State-Space Models (R) ===\n\n")
cat("--- Lynx trappings summary ---\n")
print(summary(lynx$trappings))
cat("Years:", min(lynx$year), "-", max(lynx$year),
    "(", length(lynx$year), "years )\n\n")

## ------------------------------------------------------------
## 1. Raw series plot -- the cycle is visible by eye
## ------------------------------------------------------------
png("figures/lecture_10_lynx_raw.png", width = 1400, height = 700, res = 150)
plot(lynx_ts, type = "o", pch = 16, cex = 0.5, col = "grey30",
     xlab = "Year", ylab = "Pelts trapped",
     main = "Canadian lynx pelts, Hudson's Bay Company (1821-1934)")
dev.off()
cat("Saved figures/lecture_10_lynx_raw.png\n\n")

## ------------------------------------------------------------
## 2. Log transform -- stabilize variance across the century
## ------------------------------------------------------------
log_lynx <- log(lynx_ts)
cat("--- log(trappings) summary ---\n")
print(summary(as.numeric(log_lynx)))
cat("\n")

## ------------------------------------------------------------
## 3. ACF and PACF of log(trappings)
## ------------------------------------------------------------
png("figures/lecture_10_lynx_acf_pacf.png", width = 1400, height = 700, res = 150)
par(mfrow = c(1, 2))
acf_out  <- acf(log_lynx,  lag.max = 20, main = "ACF: log(trappings)")
pacf_out <- pacf(log_lynx, lag.max = 20, main = "PACF: log(trappings)")
dev.off()
cat("Saved figures/lecture_10_lynx_acf_pacf.png\n")
cat("--- ACF at lags 1-10 ---\n")
print(round(acf_out$acf[2:11], 3))
cat("--- PACF at lags 1-10 ---\n")
print(round(pacf_out$acf[1:10], 3))
cat("\n")

## ------------------------------------------------------------
## 4. ARIMA fit via forecast::auto.arima() -- automatic order search
## ------------------------------------------------------------
fit_arima <- auto.arima(log_lynx, seasonal = FALSE,
                         stepwise = FALSE, approximation = FALSE)
cat("--- auto.arima() fit to log(trappings) ---\n")
print(fit_arima)
cat("\nSelected order (p,d,q):", paste(arimaorder(fit_arima), collapse = ","), "\n")
cat("Coefficients:\n")
print(round(coef(fit_arima), 4))
cat("\n")

## Residual diagnostic: Ljung-Box test for leftover autocorrelation
lb_test <- Box.test(residuals(fit_arima), lag = 10, type = "Ljung-Box",
                     fitdf = length(coef(fit_arima)) - 1)
cat("--- Ljung-Box test on ARIMA residuals (lag = 10) ---\n")
print(lb_test)
cat("(A large p-value here supports the fitted order: little autocorrelation left)\n\n")

## ------------------------------------------------------------
## 5. Local-level state-space model via base-R StructTS
##    State equation:       x_t = x_{t-1} + w_t,  w_t ~ N(0, sigma_level^2)
##    Observation equation: y_t = x_t + v_t,       v_t ~ N(0, sigma_eps^2)
## ------------------------------------------------------------
fit_ss <- StructTS(log_lynx, type = "level")
cat("--- StructTS local-level state-space model (free MLE) ---\n")
print(fit_ss)
cat("\nEstimated variances (coef):\n")
print(round(fit_ss$coef, 4))
cat("  level   = process (state) noise variance\n")
cat("  epsilon = observation noise variance\n")
cat("NOTE: the unconstrained MLE pushes the observation variance to the\n")
cat("zero boundary for this series -- i.e. it decides essentially all of\n")
cat("the year-to-year wiggle IS real process change, none of it gets\n")
cat("assigned to 'measurement noise', given a pure random-walk state.\n")
cat("This is a known, honest degenerate-solution issue for local-level\n")
cat("models fit to strongly cyclical AR-type data; the smoothed state\n")
cat("would then equal the raw series exactly, defeating the point of the\n")
cat("demo. To make the state/observation separation visible, we also fit\n")
cat("a second version with the observation variance FIXED at a modest,\n")
cat("plausible value (0.05) rather than freely estimated -- this is\n")
cat("exactly the sensitivity analysis explored in Exercise 2.\n\n")

fit_ss_fixed <- StructTS(log_lynx, type = "level", fixed = c(NA, 0.05))
cat("--- StructTS local-level model, observation variance fixed at 0.05 ---\n")
print(round(fit_ss_fixed$coef, 4))
cat("\n")

## Kalman smoother: best reconstruction of the hidden state using ALL data
smoothed  <- tsSmooth(fit_ss_fixed)
state_est <- smoothed[, "level"]

cat("--- First 6 years: raw log series vs. Kalman-smoothed state ---\n")
print(data.frame(year = lynx$year[1:6],
                  log_trappings = round(as.numeric(log_lynx)[1:6], 3),
                  smoothed_state = round(as.numeric(state_est)[1:6], 3)))
cat("\n")

## ------------------------------------------------------------
## 6. Figure: raw log series vs. Kalman-smoothed state
## ------------------------------------------------------------
png("figures/lecture_10_lynx_state_space.png", width = 1400, height = 800, res = 150)
plot(lynx$year, as.numeric(log_lynx), type = "o", pch = 16, cex = 0.5,
     col = "grey60", xlab = "Year", ylab = "log(pelts trapped)",
     main = "Lynx: raw log series vs. Kalman-smoothed state (local-level model)")
lines(lynx$year, as.numeric(state_est), col = "firebrick", lwd = 2)
legend("topright", legend = c("Observed log(trappings)", "Kalman-smoothed state"),
       col = c("grey60", "firebrick"), lty = 1, pch = c(16, NA), lwd = c(1, 2),
       bty = "n", cex = 0.85)
dev.off()
cat("Saved figures/lecture_10_lynx_state_space.png\n\n")

cat("=== Done ===\n")

# --- EXERCISES ---
# TODO Exercise 1: Fit auto.arima() to the RAW (non-log) trappings series.
#   Compare the selected (p,d,q) order and residual diagnostics to the
#   log-scale fit above.
# TODO Exercise 2: Refit the local-level state-space model (StructTS) after
#   manually fixing the observation-noise variance much larger and much
#   smaller than the MLE above (dlm or KFAS let you fix variances; or
#   compare StructTS runs on subsets/perturbed data as an approximation).
#   Compare how much the smoothed state changes.
# TODO Exercise 3: Reproduce the acf()/pacf() plots yourself and identify
#   the cycle length from the lag of the ACF's zero-crossings and the
#   spacing between positive peaks.
# TODO Exercise 4: Plot the ARIMA fitted values (fitted(fit_arima)) against
#   the Kalman-smoothed state on the same axes and describe, in your own
#   words, what each line is actually estimating.
