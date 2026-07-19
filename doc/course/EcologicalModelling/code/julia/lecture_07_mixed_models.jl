## ============================================================
## Lecture 7 -- Mixed-Effects Models (Julia)
## Ecological Modelling with R, Python, and Julia
##
## Dataset:
##   data/grouseticks.csv  (Elston, Moss, Boulinier, Arrowsmith &
##                          Lambin 2001, Parasitology 122:563-569)
##
##   403 red grouse chicks, TICKS (tick count) measured on each chick.
##   Chicks are nested within BROOD (118 broods), and broods are
##   nested within LOCATION (63 locations). HEIGHT/cHEIGHT is altitude
##   (centered). YEAR is 95/96/97.
##
##   The canonical real dataset for teaching GLMMs with nested random
##   effects in ecology (Elston et al. 2001; Zuur et al. 2009; Bolker
##   et al. 2009, TREE, "Generalized linear mixed models: a practical
##   guide for ecology and evolution").
##
## Models:
##   1. LMM intuition:  log1p(TICKS) ~ YEAR + cHEIGHT + (1|LOCATION/BROOD)
##   2. Poisson GLMM (nested random intercepts for LOCATION and BROOD)
##   3. Crossed-vs-nested comparison, and a variance-component-based ICC
##
## MixedModels.jl is NOT installed in this teaching environment; this
## script is written carefully from the documented MixedModels.jl API
## (as used in the package's own GLMM examples and by Douglas Bates,
## Phillip Alday & Reinhold Kliegl's MixedModels.jl documentation) but
## has NOT been executed here. Treat it as a faithful reference
## implementation to run locally with MixedModels.jl installed -- see
## code/R/lecture_07_mixed_models.R for the executed, verified numbers.
##
## Assumes working directory = repository root, i.e. run as:
##   julia --project=. code/julia/lecture_07_mixed_models.jl
## ============================================================

using CSV
using DataFrames
using CategoricalArrays
using Statistics
using MixedModels             # fit(MixedModel, formula, data, family)
using StatsPlots               # save the location/brood figure
gr()

mkpath("figures")

println("=== Lecture 7: Mixed-Effects Models (Julia) ===\n")

## ------------------------------------------------------------
## 1. Load data, set categorical types
## ------------------------------------------------------------

dat = CSV.read("data/grouseticks.csv", DataFrame)

dat.BROOD    = categorical(dat.BROOD)
dat.LOCATION = categorical(dat.LOCATION)
dat.YEAR     = categorical(dat.YEAR)

println("n chicks:    ", nrow(dat))
println("n broods:    ", length(levels(dat.BROOD)))
println("n locations: ", length(levels(dat.LOCATION)))
println("TICKS range: ", extrema(dat.TICKS), "  mean: ", round(mean(dat.TICKS), digits = 2))
println()

brood_means = combine(groupby(dat, :BROOD), :TICKS => mean => :mean_ticks)
println("Spread of brood-level mean TICKS: range ",
        round.(extrema(brood_means.mean_ticks), digits = 2),
        "  sd ", round(std(brood_means.mean_ticks), digits = 2))
println()

## ------------------------------------------------------------
## 2. LMM intuition: log1p(TICKS) as a (roughly) Gaussian response
## ------------------------------------------------------------

dat.logTICKS = log1p.(dat.TICKS)

lmm_formula = @formula(logTICKS ~ YEAR + cHEIGHT + (1 | LOCATION) + (1 | BROOD))
fit_lmm = fit(MixedModel, lmm_formula, dat)

println("--- LMM (Gaussian, log1p(TICKS)): ",
        "logTICKS ~ YEAR + cHEIGHT + (1|LOCATION) + (1|BROOD) ---")
println(fit_lmm)
println()

## ------------------------------------------------------------
## 3. Poisson GLMM: TICKS ~ YEAR + cHEIGHT + (1|LOCATION) + (1|BROOD)
##    MixedModels.jl expresses nested-vs-crossed grouping purely
##    through the data: because BROOD codes are already unique
##    across LOCATIONs in this dataset, writing crossed random
##    intercepts (1|LOCATION) + (1|BROOD) is equivalent to the
##    nested (1|LOCATION/BROOD) notation used in R.
## ------------------------------------------------------------

glmm_formula = @formula(TICKS ~ YEAR + cHEIGHT + (1 | LOCATION) + (1 | BROOD))
fit_glmm = fit(MixedModel, glmm_formula, dat, Poisson())

println("--- Poisson GLMM: TICKS ~ YEAR + cHEIGHT + (1|LOCATION) + (1|BROOD) ---")
println(fit_glmm)
println()

println("Fixed effects (log scale):")
println(fixef(fit_glmm))
println()

println("Variance components:")
println(VarCorr(fit_glmm))
println()

## ------------------------------------------------------------
## 4. ICC / variance partition coefficient from the random-effect SDs
## ------------------------------------------------------------

vc = VarCorr(fit_glmm)
## sigmas is a named tuple of grouping-variable => (Intercept = sd, ...)
sd_location = vc.σρ.LOCATION.σ[1]
sd_brood    = vc.σρ.BROOD.σ[1]
var_location = sd_location^2
var_brood    = sd_brood^2

icc_location = var_location / (var_location + var_brood)
icc_brood    = var_brood / (var_location + var_brood)

println("--- ICC (share of random-effect variance) ---")
println("  Var(LOCATION) = ", round(var_location, digits = 4))
println("  Var(BROOD)    = ", round(var_brood, digits = 4))
println("  Share of RE variance at LOCATION level: ",
        round(100 * icc_location, digits = 1), "%")
println("  Share of RE variance at BROOD level:    ",
        round(100 * icc_brood, digits = 1), "%")
println()

## ------------------------------------------------------------
## 5. AIC comparison to a model with only LOCATION as random effect
##    (drops BROOD) -- same comparison as the R script's Section 4/
##    Exercise 3, expressed the Julia way.
## ------------------------------------------------------------

glmm_location_only_formula = @formula(TICKS ~ YEAR + cHEIGHT + (1 | LOCATION))
fit_glmm_location_only = fit(MixedModel, glmm_location_only_formula, dat, Poisson())

println("AIC full (LOCATION + BROOD): ", round(aic(fit_glmm), digits = 2))
println("AIC LOCATION-only:           ", round(aic(fit_glmm_location_only), digits = 2))
println()

## ------------------------------------------------------------
## 6. Figure: mean TICKS across a sample of LOCATIONs
## ------------------------------------------------------------

loc_means = combine(groupby(dat, :LOCATION), :TICKS => mean => :mean_ticks)
sort!(loc_means, :mean_ticks)

n_sample = min(20, nrow(loc_means))
idx = round.(Int, range(1, nrow(loc_means), length = n_sample))
plot_dat = loc_means[idx, :]

p = bar(string.(plot_dat.LOCATION), plot_dat.mean_ticks,
        legend = false, xrotation = 90,
        xlabel = "LOCATION (sample of 20)", ylabel = "Mean TICKS per chick",
        title = "Mean tick count varies sharply by LOCATION",
        color = :steelblue)
hline!(p, [mean(dat.TICKS)], linestyle = :dash, color = :grey)

savefig(p, "figures/lecture_07_ticks_by_location_brood.png")
println("Figure saved: figures/lecture_07_ticks_by_location_brood.png")

## ------------------------------------------------------------
## EXERCISES
## ------------------------------------------------------------
# 1. Add a random slope for cHEIGHT by LOCATION, i.e.
#    @formula(TICKS ~ YEAR + cHEIGHT + (1 + cHEIGHT | LOCATION) + (1 | BROOD)),
#    and compare AIC to fit_glmm above.
# 2. Compute the ICC from the variance components of fit_glmm (see
#    Section 4) and interpret: is more of the unexplained variance at
#    the LOCATION level or the BROOD level?
# 3. Refit with only LOCATION as a random effect (see Section 5,
#    fit_glmm_location_only) and compare AIC and fixed-effect standard
#    errors to fit_glmm.
# 4. Use ranef(fit_glmm) to extract the BLUPs for BROOD and plot them
#    against the number of chicks per brood -- confirm that broods with
#    fewer chicks show more shrinkage toward zero (partial pooling).
