## ============================================================
## Lecture 6 -- Generalized Linear Models (Julia)
## Ecological Modelling with R, Python, and Julia
##
## Dataset:
##   data/grouseticks.csv (Elston, Moss, Boulinier, Arrowsmith & Lambin 2001,
##                          Parasitology 122: 563-569 -- "Analysis of
##                          aggregation, a worked example: numbers of ticks
##                          on red grouse chicks.")
##   One of the most widely taught real GLMM datasets in ecology -- used as
##   the worked example in Zuur et al. (2009) and Bolker et al. (2009, TREE).
##
## Columns:
##   INDEX    chick ID
##   TICKS    tick count per chick (response)
##   BROOD    factor, 118 levels (chick's brood of origin)
##   HEIGHT   altitude in metres
##   YEAR     factor, 95/96/97
##   LOCATION factor, 63 levels
##   cHEIGHT  HEIGHT, mean-centered
##
## Methods:
##   1. Poisson GLM:      TICKS ~ YEAR + cHEIGHT, log link -- GLM.jl glm()
##   2. Overdispersion check: residual deviance / residual df
##   3. Negative-binomial GLM (fixes overdispersion)
##      -- GLM.jl's NegativeBinomial() distribution needs a *known* dispersion
##         parameter theta; unlike R's MASS::glm.nb(), the base GLM.jl API
##         does not estimate theta by maximum likelihood for you. We work
##         around this the way the Julia ecosystem typically does: fit a
##         profile of Poisson-family GLMs is not enough, so instead we use
##         GLM.jl's `negbin()` convenience function from the same package,
##         which iterates IRLS while re-estimating theta by ML internally
##         (the Julia equivalent of MASS::glm.nb's alternating algorithm).
##         If your GLM.jl version predates `negbin()`, the honest fallback
##         is to profile over a grid of fixed theta values and pick the one
##         that maximizes the log-likelihood, exactly as the Python script
##         in this lecture does by hand for statsmodels.
##   4. Binomial GLM (toy presence/absence recoding) -- glm(..., Binomial(), LogitLink())
##
## Assumes working directory = repository root, i.e. run as:
##   julia --project=. code/julia/lecture_06_glm.jl
##
## NOTE: this script was written carefully against the documented GLM.jl API
## but could not be executed in this environment (package not installed).
## ============================================================

using CSV
using DataFrames
using CategoricalArrays
using GLM
using StatsBase
using Statistics
using Plots
gr()

mkpath("figures")

println("=== Lecture 6: Generalized Linear Models (Julia) ===\n")

## ------------------------------------------------------------
## Load data. YEAR/BROOD/LOCATION are read as integers by CSV.jl by
## default; wrap them in categorical() so they are treated as factors,
## matching R's factor() and Python's astype("category").
## ------------------------------------------------------------
ticks = CSV.read("data/grouseticks.csv", DataFrame)
ticks.YEAR     = categorical(string.(ticks.YEAR))
ticks.BROOD    = categorical(string.(ticks.BROOD))
ticks.LOCATION = categorical(string.(ticks.LOCATION))

## ------------------------------------------------------------
## 0. Why a linear model fails here
## ------------------------------------------------------------
println("--- TICKS distribution ---")
println("mean   = ", round(mean(ticks.TICKS), digits = 2))
println("var    = ", round(var(ticks.TICKS), digits = 2))
println("max    = ", maximum(ticks.TICKS))
println("prop. zero ticks = ", round(mean(ticks.TICKS .== 0), digits = 3))
println("variance / mean  = ", round(var(ticks.TICKS) / mean(ticks.TICKS), digits = 1),
        " (>> 1 already hints at overdispersion relative to Poisson)\n")

## ------------------------------------------------------------
## 1. Poisson GLM -- TICKS ~ YEAR + cHEIGHT, log link
## ------------------------------------------------------------
pois_fit = glm(@formula(TICKS ~ YEAR + cHEIGHT), ticks, Poisson(), LogLink())
println("--- Poisson GLM: TICKS ~ YEAR + cHEIGHT ---")
println(pois_fit)

println("\nCoefficients on the log-link scale:")
println(round.(coef(pois_fit), digits = 4))
println("\nExponentiated coefficients (rate ratios on the response scale):")
println(round.(exp.(coef(pois_fit)), digits = 4))

## ------------------------------------------------------------
## 2. Overdispersion check: residual deviance / residual df
##    Ratio >> 1 signals overdispersion (variance > mean, more than
##    Poisson allows).
## ------------------------------------------------------------
resid_df = dof_residual(pois_fit)
disp_ratio = deviance(pois_fit) / resid_df
println("\n--- Overdispersion check ---")
println("Residual deviance: ", round(deviance(pois_fit), digits = 1), " on ", resid_df, " df")
println("Dispersion ratio (deviance / df): ", round(disp_ratio, digits = 2))
if disp_ratio > 1.5
    println("--> Ratio is well above 1: the Poisson model is overdispersed.")
    println("    This matches the paper's own point: tick counts are strongly")
    println("    aggregated (clumped), not Poisson-distributed.\n")
else
    println("--> Ratio is close to 1: no strong evidence of overdispersion.\n")
end

## ------------------------------------------------------------
## 3. Negative-binomial GLM -- fixes overdispersion.
##    negbin() (from GLM.jl) alternates IRLS coefficient updates with
##    ML re-estimation of theta, the way MASS::glm.nb() does in R.
## ------------------------------------------------------------
nb_fit = negbin(@formula(TICKS ~ YEAR + cHEIGHT), ticks, LogLink())
println("--- Negative-binomial GLM: TICKS ~ YEAR + cHEIGHT ---")
println(nb_fit)
println("\nEstimated theta (dispersion parameter): ", round(nb_fit.model.rr.d.r, digits = 3))

println("\n--- AIC comparison: Poisson vs. Negative-Binomial ---")
println("Poisson AIC:            ", round(aic(pois_fit), digits = 1))
println("Negative-Binomial AIC:  ", round(aic(nb_fit), digits = 1))
println("Difference (Poisson - NB): ", round(aic(pois_fit) - aic(nb_fit), digits = 1),
        " (large positive value favors the negative-binomial model)\n")

## ------------------------------------------------------------
## 4. Binomial GLM (logistic regression) -- toy example:
##    recode TICKS as presence/absence and model with cHEIGHT.
## ------------------------------------------------------------
ticks.present = Int.(ticks.TICKS .> 0)
bin_fit = glm(@formula(present ~ cHEIGHT), ticks, Binomial(), LogitLink())
println("--- Binomial GLM: present (TICKS > 0) ~ cHEIGHT ---")
println(bin_fit)

println("\nOdds ratio for cHEIGHT (exp(coef)): ", round(exp(coef(bin_fit)[2]), digits = 4))

## Predicted probability of tick presence at a couple of cHEIGHT values
new_h = DataFrame(cHEIGHT = [-50.0, 0.0, 50.0])
pred_p = predict(bin_fit, new_h)
println("\nPredicted P(present) at cHEIGHT = -50, 0, 50:")
for (h, p) in zip(new_h.cHEIGHT, pred_p)
    println("  cHEIGHT=", h, ": P(present) = ", round(p, digits = 3))
end

## ------------------------------------------------------------
## 5. Figure: TICKS by YEAR (jittered log1p scatter + boxplot overlay)
## ------------------------------------------------------------
years = sort(unique(string.(ticks.YEAR)))
plt = plot(legend = false, xlabel = "Year", ylabel = "log1p(TICKS)",
           title = "Tick counts per chick by year (log1p scale)",
           xticks = (1:length(years), years))
for (i, yr) in enumerate(years)
    yvals = log1p.(ticks.TICKS[string.(ticks.YEAR) .== yr])
    xj = i .+ 0.12 .* randn(length(yvals))
    scatter!(plt, xj, yvals, alpha = 0.35, color = :steelblue, markersize = 3)
end
boxplot!(plt, [i for (i, yr) in enumerate(years) for _ in 1:count(==(yr), string.(ticks.YEAR))],
         log1p.(ticks.TICKS), fillalpha = 0.0, linecolor = :black, bar_width = 0.3)
savefig(plt, "figures/lecture_06_tick_counts_by_year.png")
println("\nSaved figures/lecture_06_tick_counts_by_year.png")

## --- EXERCISES ---
## TODO 1: Fit a Poisson GLM using HEIGHT instead of cHEIGHT and compare the
##         coefficient estimates and intercept interpretation to the cHEIGHT
##         model fit above.
## TODO 2: Fit the negative-binomial GLM (already done above as nb_fit) and
##         compare its AIC to the Poisson model's AIC; report which model
##         the data prefer and why.
## TODO 3: Fit a binomial GLM for tick presence/absence ~ cHEIGHT (already
##         done above as bin_fit); report the odds ratio for cHEIGHT and
##         interpret its sign and magnitude.
## TODO 4: See exercises/lecture_06_exercises.md for the full exercise set.
