## ============================================================
## Lecture 9 -- Bayesian Hierarchical Models (Julia)
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
## Continuity with Lecture 7:
##   Lecture 7's Julia script fit the frequentist Poisson GLMM with
##   MixedModels.jl:
##     fit(MixedModel, @formula(TICKS ~ YEAR + cHEIGHT + (1|LOCATION) + (1|BROOD)),
##         dat, Poisson())
##   which already performs partial pooling / shrinkage implicitly.
##   This lecture fits the SAME model structure fully Bayesian with
##   Turing.jl: the shrinkage becomes explicit posterior distributions
##   for every LOCATION and BROOD effect, and uncertainty propagates
##   correctly through every level, including the variance components.
##
## Model (Poisson, log link), same structure as the R (rstanarm) and
## Python (PyMC) fits in this lecture:
##   log(E[TICKS]) = Intercept + YEAR96 + YEAR97 + cHEIGHT
##                   + u_LOCATION[loc] + u_BROOD[brood]
##   u_LOCATION ~ Normal(0, sigma_location)
##   u_BROOD    ~ Normal(0, sigma_brood)   (nested within LOCATION,
##                                          BROOD ids globally unique)
##
## Priors (weakly informative, ecologically sensible defaults on the
## log scale):
##   Intercept, YEAR, cHEIGHT coefficients ~ Normal(0, 5)
##   sigma_location, sigma_brood           ~ Exponential(1) (i.e.
##                                            truncated to be positive
##                                            by construction)
##
## Turing.jl is NOT installed in this teaching environment; this
## script is written carefully from the documented Turing.jl API
## (@model macro, NUTS sampler, non-centered parameterization for
## random effects, as used in Turing's own hierarchical-model
## tutorials) but has NOT been executed here. Treat it as a faithful
## reference implementation to run locally with Turing.jl installed --
## see code/R/lecture_09_bayesian_hierarchical.R and
## code/python/lecture_09_bayesian_hierarchical.py for the executed,
## verified posterior numbers on this same dataset and model.
##
## Assumes working directory = repository root, i.e. run as:
##   julia --project=. code/julia/lecture_09_bayesian_hierarchical.jl
## ============================================================

using CSV
using DataFrames
using CategoricalArrays
using Statistics
using Turing
using StatsPlots
gr()

mkpath("figures")

println("=== Lecture 9: Bayesian Hierarchical Models (Julia / Turing.jl) ===\n")

## ------------------------------------------------------------
## 1. Load data, build integer indices for grouping factors
## ------------------------------------------------------------

dat = CSV.read("data/grouseticks.csv", DataFrame)

dat.BROOD    = categorical(string.(dat.BROOD))
dat.LOCATION = categorical(string.(dat.LOCATION))
dat.YEAR     = categorical(string.(dat.YEAR))

println("n chicks:    ", nrow(dat))
println("n broods:    ", length(levels(dat.BROOD)))
println("n locations: ", length(levels(dat.LOCATION)))
println()

loc_idx   = levelcode.(dat.LOCATION)          # 1..n_loc
brood_idx = levelcode.(dat.BROOD)             # 1..n_brood (globally unique ids)
n_loc     = length(levels(dat.LOCATION))
n_brood   = length(levels(dat.BROOD))

year96 = Float64.(dat.YEAR .== "96")
year97 = Float64.(dat.YEAR .== "97")

## Standardize cHEIGHT for sampler stability (matches the R and Python
## scripts in this lecture -- cHEIGHT ranges roughly -59 to +71 on its
## native scale, which is badly scaled for HMC without standardizing).
cheight_mean = mean(dat.cHEIGHT)
cheight_sd   = std(dat.cHEIGHT)
cheight_s    = (dat.cHEIGHT .- cheight_mean) ./ cheight_sd

y = dat.TICKS

## ------------------------------------------------------------
## 2. Define the hierarchical Poisson model
##    Non-centered parameterization (z * sigma) for the random
##    effects gives much better NUTS geometry than a centered
##    Normal(0, sigma) prior directly on the effects.
## ------------------------------------------------------------

@model function grouseticks_hier(y, year96, year97, cheight_s, loc_idx, brood_idx, n_loc, n_brood)
    # Weakly informative priors on fixed effects (log scale)
    intercept  ~ Normal(0, 5)
    b_year96   ~ Normal(0, 5)
    b_year97   ~ Normal(0, 5)
    b_cheight  ~ Normal(0, 5)

    # Weakly informative priors on variance-component SDs
    sigma_loc   ~ Exponential(1)
    sigma_brood ~ Exponential(1)

    # Non-centered random effects
    z_loc   ~ filldist(Normal(0, 1), n_loc)
    z_brood ~ filldist(Normal(0, 1), n_brood)
    u_loc   = z_loc .* sigma_loc
    u_brood = z_brood .* sigma_brood

    n = length(y)
    for i in 1:n
        eta_i = intercept + b_year96 * year96[i] + b_year97 * year97[i] +
                b_cheight * cheight_s[i] + u_loc[loc_idx[i]] + u_brood[brood_idx[i]]
        y[i] ~ Poisson(exp(eta_i))
    end
end

model = grouseticks_hier(y, year96, year97, cheight_s, loc_idx, brood_idx, n_loc, n_brood)

## ------------------------------------------------------------
## 3. Sample with NUTS -- modest budget (2 chains x 500 samples,
##    500 adaptation steps) to keep runtime reasonable, matching the
##    R and Python scripts in this lecture.
## ------------------------------------------------------------

println("--- Sampling with NUTS (2 chains x 500 samples, 500 warmup) ---")
chain = sample(model, NUTS(500, 0.9), MCMCThreads(), 500, 2;
               progress = true)

## ------------------------------------------------------------
## 4. Posterior summary and diagnostics
## ------------------------------------------------------------

fixed_params = [:intercept, :b_year96, :b_year97, :b_cheight, :sigma_loc, :sigma_brood]

println("\n--- Posterior summary (fixed effects + variance components) ---")
println(summarystats(chain[fixed_params]))

println("\n--- R-hat and effective sample size ---")
println(describe(chain[fixed_params])[2])   # ess/rhat table

## ------------------------------------------------------------
## 5. Compare to Lecture 7's frequentist glmer point estimates
##    (hard-coded from Lecture 7's fitted model; re-derive with R's
##    glmer(TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD), family=poisson)
##    to confirm)
## ------------------------------------------------------------

post_intercept = mean(chain[:intercept])
post_year96    = mean(chain[:b_year96])
post_year97    = mean(chain[:b_year97])
post_cheight_s = mean(chain[:b_cheight])
post_cheight_orig = post_cheight_s / cheight_sd

glmer_est = Dict(
    "Intercept" => 0.467,
    "YEAR96"    => 1.166,
    "YEAR97"    => -0.978,
    "cHEIGHT"   => -0.024,
)
bayes_est = Dict(
    "Intercept" => post_intercept,
    "YEAR96"    => post_year96,
    "YEAR97"    => post_year97,
    "cHEIGHT"   => post_cheight_orig,
)

println("\n--- Lecture 7 (glmer) vs Lecture 9 (Turing.jl posterior mean) ---")
for p in ["Intercept", "YEAR96", "YEAR97", "cHEIGHT"]
    println(rpad(p, 12), "  glmer_L7 = ", round(glmer_est[p], digits = 3),
            "   bayes_L9 = ", round(bayes_est[p], digits = 3))
end
println("\nSame model structure, two philosophies -- point estimates should be close.\n")

## ------------------------------------------------------------
## 6. Figure: caterpillar plot of a sample of LOCATION-level
##    random-effect posterior means with 95% credible intervals
## ------------------------------------------------------------

z_loc_draws = Array(chain[Symbol.("z_loc[" .* string.(1:n_loc) .* "]")])  # (n_samples, n_loc)
sigma_loc_draws = vec(Array(chain[:sigma_loc]))
u_loc_draws = z_loc_draws .* sigma_loc_draws                              # broadcast over samples

loc_mean = vec(mean(u_loc_draws, dims = 1))
loc_lo   = [quantile(u_loc_draws[:, j], 0.025) for j in 1:n_loc]
loc_hi   = [quantile(u_loc_draws[:, j], 0.975) for j in 1:n_loc]

order = sortperm(loc_mean)
n_show = min(20, n_loc)
sample_pos = round.(Int, range(1, n_loc, length = n_show))
show_idx = order[sample_pos]

loc_labels = levels(dat.LOCATION)[show_idx]

p = scatter(loc_mean[show_idx], 1:n_show,
            xerror = (loc_mean[show_idx] .- loc_lo[show_idx], loc_hi[show_idx] .- loc_mean[show_idx]),
            yticks = (1:n_show, loc_labels),
            legend = false, color = :steelblue,
            xlabel = "Posterior LOCATION random effect (log scale)",
            title = "Bayesian posterior LOCATION effects\n(posterior mean + 95% credible interval)")
vline!(p, [0], linestyle = :dash, color = :grey)

savefig(p, "figures/lecture_09_posterior_LOCATION_effects.png")
println("Figure saved: figures/lecture_09_posterior_LOCATION_effects.png")


## ------------------------------------------------------------
## EXERCISES
## ------------------------------------------------------------
# 1. Change the prior on sigma_loc from Exponential(1) to
#    Exponential(0.2) (much flatter/more permissive) or a
#    half-Cauchy(0, 2) via `truncated(Cauchy(0, 2), 0, Inf)`, refit,
#    and compare the posterior mean and credible interval for
#    sigma_loc to the original.
# 2. Inspect describe(chain) in full -- are there any parameters with
#    rhat > 1.01 or ess < 400? Use `plot(chain[fixed_params])` to view
#    trace plots for the fixed effects.
# 3. Add a random slope for cheight_s by LOCATION (a second
#    non-centered Normal random effect multiplying cheight_s[i],
#    added inside the loop), refit, and compare model fit.
# 4. Compute and plot the 95% credible interval for the YEAR97 effect
#    exponentiated to the rate-ratio scale (exp.(chain[:b_year97])),
#    and compare its width and interpretation to the 95% confidence
#    interval Lecture 7's glmer produced for the same coefficient.
