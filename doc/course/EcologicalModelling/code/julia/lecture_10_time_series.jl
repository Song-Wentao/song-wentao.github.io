## ============================================================
## Lecture 10 -- Time Series and State-Space Models (Julia)
## Ecological Modelling with R, Python, and Julia
##
## Dataset:
##   data/lynx.csv (year, trappings)
##   114 consecutive annual counts (1821-1934) of Canadian lynx (Lynx
##   canadensis) pelts trapped and traded by the Hudson's Bay Company.
##   Originally compiled by MacLulich (1937); the classic AR(2) analysis
##   is Moran (1953); the same series is popularized as a teaching example
##   by Campbell & Walker (1977) (base R's built-in "lynx"). Extensively
##   reanalyzed for density dependence and predator-prey dynamics by
##   Stenseth, Falck, Bjornstad & Krebs (1997), PNAS 94:5147-52, and
##   Stenseth et al. (1998, Science; 1999) -- the lynx-hare cycle is one
##   of the most heavily studied ecological time series in existence.
##
## A note on the Julia time-series ecosystem, honestly stated: unlike R's
## forecast::auto.arima() or Python's statsmodels.tsa, Julia has no single
## dominant, actively-maintained package that fits general ARIMA(p,d,q)
## models (with MA terms) via automatic order search with full confidence.
## StateSpaceModels.jl exists and provides a LocalLevel model type and
## SARIMA support, but its exact current API is not something to bet a
## reproducible course script on without being able to test it in this
## environment. We therefore take the same two honest substitutes used
## elsewhere in this course when a package is uncertain:
##   1. ARIMA -> a pure AR(p) model fit as ordinary lagged regression with
##      GLM.jl. This is mathematically exact for a pure-AR process (no MA
##      terms) and recovers essentially the same AR coefficients as R's
##      AR(2) component and Python's ARIMA(2,0,0) fit.
##   2. State-space local-level model -> a small, fully transparent,
##      hand-rolled Kalman filter + RTS smoother (predict/update equations
##      written out explicitly, ~20 lines). This is exactly the algorithm
##      StructTS() and UnobservedComponents() run internally, just without
##      a package wrapper -- arguably more pedagogically useful to see once.
##
## Methods:
##   1. Plot the raw trapping series -- the ~10-year cycle is visible by eye
##   2. Log-transform to stabilize variance
##   3. ACF / PACF of log(trappings) to diagnose autocorrelation structure
##   4. AR(2) fit to log(trappings) via lagged-regression with GLM.jl
##   5. A local-level state-space model (random walk state + noisy
##      observation) fit via a hand-rolled Kalman filter and RTS smoother,
##      with variances chosen to match the MLE story from R/Python
##      (process variance ~0.68 from a free fit; observation variance
##      fixed at a modest 0.05 for a visible smoothing demonstration,
##      exactly as in the R and Python scripts -- see the note there about
##      the free MLE pushing observation variance to the zero boundary)
##   6. Figure: raw log series vs. Kalman-smoothed state, saved to
##      figures/lecture_10_lynx_state_space.png
##
## Assumes working directory = repository root, i.e. run as:
##   julia --project=. code/julia/lecture_10_time_series.jl
## ============================================================

using CSV
using DataFrames
using Statistics
using GLM
using StatsPlots
gr()

mkpath("figures")

println("=== Lecture 10: Time Series and State-Space Models (Julia) ===\n")

## ------------------------------------------------------------
## 0. Load the data
## ------------------------------------------------------------
lynx = CSV.read("data/lynx.csv", DataFrame)
years = lynx.year
trappings = Float64.(lynx.trappings)
n = length(trappings)

println("n years:  ", n)
println("years:    ", minimum(years), " - ", maximum(years))
println("trappings summary: min=", minimum(trappings),
        " median=", median(trappings),
        " max=", maximum(trappings), "\n")

## ------------------------------------------------------------
## 1. Raw series plot -- the cycle is visible by eye
## ------------------------------------------------------------
p_raw = plot(years, trappings, seriestype = :path, marker = :circle,
             markersize = 2, color = :gray30, legend = false,
             xlabel = "Year", ylabel = "Pelts trapped",
             title = "Canadian lynx pelts, Hudson's Bay Company (1821-1934)")
savefig(p_raw, "figures/lecture_10_lynx_raw.png")
println("Saved figures/lecture_10_lynx_raw.png\n")

## ------------------------------------------------------------
## 2. Log transform -- stabilize variance across the century
## ------------------------------------------------------------
log_lynx = log.(trappings)
println("log(trappings) summary: min=", round(minimum(log_lynx), digits = 3),
        " mean=", round(mean(log_lynx), digits = 3),
        " max=", round(maximum(log_lynx), digits = 3), "\n")

## ------------------------------------------------------------
## 3. ACF and PACF of log(trappings), computed by hand
##    (StatsBase.autocor exists too; shown explicitly here for clarity)
## ------------------------------------------------------------
function sample_acf(x::Vector{Float64}, maxlag::Int)
    xm = x .- mean(x)
    denom = sum(xm .^ 2)
    return [sum(xm[1:end-k] .* xm[(1+k):end]) / denom for k in 1:maxlag]
end

acf_vals = sample_acf(log_lynx, 20)
println("--- ACF at lags 1-10 ---")
println(round.(acf_vals[1:10], digits = 3))

# Partial ACF via successive Yule-Walker-style AR fits (Durbin-Levinson
# would be the exact classical recursion; a direct lagged-regression PACF
# is used here for transparency, matching R's/Python's ywm-style PACF).
function sample_pacf(x::Vector{Float64}, maxlag::Int)
    n = length(x)
    pacf = zeros(maxlag)
    for k in 1:maxlag
        df = DataFrame(y = x[(k+1):end])
        for j in 1:k
            df[!, Symbol("lag$j")] = x[(k+1-j):(end-j)]
        end
        rhs = join(["lag$j" for j in 1:k], " + ")
        f = eval(Meta.parse("@formula(y ~ " * rhs * ")"))
        fit_k = lm(f, df)
        pacf[k] = coef(fit_k)[end]  # coefficient on the k-th lag
    end
    return pacf
end

pacf_vals = sample_pacf(log_lynx, 10)
println("--- PACF at lags 1-10 ---")
println(round.(pacf_vals, digits = 3))

p_acf = bar(1:20, acf_vals, legend = false, xlabel = "Lag", ylabel = "ACF",
            title = "ACF: log(trappings)")
p_pacf = bar(1:10, pacf_vals, legend = false, xlabel = "Lag", ylabel = "PACF",
             title = "PACF: log(trappings)")
p_both = plot(p_acf, p_pacf, layout = (1, 2), size = (1000, 400))
savefig(p_both, "figures/lecture_10_lynx_acf_pacf.png")
println("Saved figures/lecture_10_lynx_acf_pacf.png\n")

## ------------------------------------------------------------
## 4. AR(2) fit to log(trappings) via lagged regression (GLM.jl)
##    Exact for a pure-AR process; matches R's AR(2) component and
##    Python's ARIMA(2,0,0) coefficients closely.
## ------------------------------------------------------------
ar_df = DataFrame(y  = log_lynx[3:end],
                   y1 = log_lynx[2:end-1],
                   y2 = log_lynx[1:end-2])
ar2_fit = lm(@formula(y ~ y1 + y2), ar_df)
println("--- AR(2) fit to log(trappings) via GLM.jl lagged regression ---")
println(coeftable(ar2_fit))
println("\n(Compare: R's auto.arima AR component ar1~1.37-1.56, ar2~-0.73")
println(" to -0.95 depending on MA terms included; Python's ARIMA(2,0,0)")
println(" gives ar1=1.378, ar2=-0.740 -- this plain AR(2) regression")
println(" recovers essentially the same oscillatory AR structure.)\n")

## ------------------------------------------------------------
## 5. Local-level state-space model: hand-rolled Kalman filter + smoother
##    State equation:       x_t = x_{t-1} + w_t,  w_t ~ N(0, sigma_proc2)
##    Observation equation: y_t = x_t + v_t,       v_t ~ N(0, sigma_obs2)
## ------------------------------------------------------------
function kalman_filter(y::Vector{Float64}, sigma_proc2::Float64,
                        sigma_obs2::Float64)
    n = length(y)
    a_filt = zeros(n); P_filt = zeros(n)
    a_pred = zeros(n); P_pred = zeros(n)

    # diffuse-ish initialization at the first observation
    a_pred[1] = y[1]
    P_pred[1] = sigma_proc2 + 1e6

    for t in 1:n
        if t > 1
            a_pred[t] = a_filt[t-1]
            P_pred[t] = P_filt[t-1] + sigma_proc2
        end
        K = P_pred[t] / (P_pred[t] + sigma_obs2)
        a_filt[t] = a_pred[t] + K * (y[t] - a_pred[t])
        P_filt[t] = (1 - K) * P_pred[t]
    end
    return a_filt, P_filt, a_pred, P_pred
end

# Rauch-Tung-Striebel (RTS) smoother: a backward pass over the filtered
# estimates that incorporates information from the WHOLE series, not just
# the past -- this is what turns "filtering" into "smoothing".
function kalman_smoother(a_filt::Vector{Float64}, P_filt::Vector{Float64},
                          a_pred::Vector{Float64}, P_pred::Vector{Float64},
                          sigma_proc2::Float64)
    n = length(a_filt)
    a_smooth = copy(a_filt)
    P_smooth = copy(P_filt)
    for t in (n-1):-1:1
        J = P_filt[t] / P_pred[t+1]
        a_smooth[t] = a_filt[t] + J * (a_smooth[t+1] - a_pred[t+1])
        P_smooth[t] = P_filt[t] + J^2 * (P_smooth[t+1] - P_pred[t+1])
    end
    return a_smooth, P_smooth
end

# As in the R and Python scripts: a freely-optimized local-level fit on
# this strongly cyclical AR-type series tends to push the observation
# variance toward zero (a real, honest degenerate-MLE result -- the model
# decides nearly all the wiggle is "real" process change, given a pure
# random-walk state). To make the state/observation split visible for
# teaching, we fix the observation variance at a modest, plausible value
# (0.05) rather than searching for the unconstrained MLE -- matching the
# process variance (~0.68) found by R's StructTS() and Python's
# UnobservedComponents() free fit, and exactly the sensitivity analysis in
# Exercise 2.
sigma_proc2 = 0.68
sigma_obs2  = 0.05

a_filt, P_filt, a_pred, P_pred = kalman_filter(log_lynx, sigma_proc2, sigma_obs2)
a_smooth, P_smooth = kalman_smoother(a_filt, P_filt, a_pred, P_pred, sigma_proc2)

println("--- Local-level Kalman filter/smoother ---")
println("sigma_process^2 = ", sigma_proc2, "  sigma_observation^2 = ", sigma_obs2)
println("--- First 6 years: raw log series vs. Kalman-smoothed state ---")
for i in 1:6
    println("year=", years[i],
            "  log_trappings=", round(log_lynx[i], digits = 3),
            "  smoothed_state=", round(a_smooth[i], digits = 3))
end
println()

## ------------------------------------------------------------
## 6. Figure: raw log series vs. Kalman-smoothed state
## ------------------------------------------------------------
p_ss = plot(years, log_lynx, seriestype = :path, marker = :circle,
            markersize = 2, color = :gray50, label = "Observed log(trappings)",
            xlabel = "Year", ylabel = "log(pelts trapped)",
            title = "Lynx: raw log series vs. Kalman-smoothed state (local-level model)")
plot!(p_ss, years, a_smooth, color = :firebrick, linewidth = 2,
      label = "Kalman-smoothed state")
savefig(p_ss, "figures/lecture_10_lynx_state_space.png")
println("Saved figures/lecture_10_lynx_state_space.png\n")

println("=== Done ===")

## --- EXERCISES ---
## TODO Exercise 1: Fit the AR(2) lagged regression to the RAW (non-log)
##   trappings series instead of log(trappings). Compare the fitted
##   coefficients and residual behavior to the log-scale fit above.
## TODO Exercise 2: Rerun kalman_filter()/kalman_smoother() with a much
##   larger and a much smaller sigma_obs2 than 0.05 (keeping sigma_proc2
##   fixed at 0.68). Compare how much the smoothed state changes.
## TODO Exercise 3: Reproduce the sample_acf()/sample_pacf() computation
##   yourself and identify the cycle length from the lag of the ACF's
##   zero-crossings and the spacing between positive peaks.
## TODO Exercise 4: Plot the AR(2) fitted values against the
##   Kalman-smoothed state on the same axes and describe, in your own
##   words, what each line is actually estimating.
