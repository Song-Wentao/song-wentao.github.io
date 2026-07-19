#=
Lecture 11 -- Occupancy and N-mixture Models
Ecological Modelling with R, Python, and Julia
================================================================================

DATA PROVENANCE (read this first):
data/crossbill_occupancy_sim.csv is SIMULATED, not raw field data. This
sandbox has no general internet access (only pypi.org and the apt mirror are
reachable) so the real "crossbill" repeat-visit dataset bundled with the R
package `unmarked` (data(crossbill); Swiss breeding bird survey MHB, Schmid,
Zbinden & Keller 2004, Swiss Ornithological Institute) could not be
downloaded. The simulation (code/R/generate_crossbill_data.R, seed
11042004) reproduces the same design -- 200 sites, 3 repeat visits, a
site-level elevation covariate on occupancy (psi), a visit-level date
covariate on detection (p) -- with probabilities calibrated to the ranges
reported in Schmid, Zbinden & Keller (2004) and Royle & Kery (2007, Ecology
88(7):1813-1823): psi ~ 0.3-0.6, p ~ 0.4-0.7.

JULIA PACKAGE NOTE: as in Python, there is no mature Julia package
equivalent to R's `unmarked` for occupancy modeling. This script implements
the marginal likelihood BY HAND (same closed-form single-season occupancy
likelihood used in the R/Python scripts) and maximizes it with Optim.jl.

    L_i = psi_i * prod_j p_ij^{y_ij} (1-p_ij)^{1-y_ij}      if any y_ij == 1
        = psi_i * prod_j (1-p_ij) + (1 - psi_i)               if all y_ij == 0

(missing visits are dropped from the product for that site.)

NOTE ON EXECUTION: Julia is not installed in the sandbox this course was
authored in, so this script could not be executed/debugged here (unlike the
R and Python versions, which were run successfully). It mirrors the R/Python
logic line-for-line and uses only well-established packages
(CSV, DataFrames, Optim, Plots) -- run it locally with
`julia --project code/julia/lecture_11_occupancy.jl` after
`] add CSV DataFrames Optim Plots StatsBase`.
================================================================================
=#

using CSV
using DataFrames
using Optim
using Statistics
using Plots

Random_seed = 11042004  # for documentation; no stochastic steps below

df = CSV.read("data/crossbill_occupancy_sim.csv", DataFrame)

det_cols  = [:det1, :det2, :det3]
date_cols = [:date1, :date2, :date3]

Y    = Matrix{Union{Missing,Float64}}(df[:, det_cols])
DATE = Matrix{Union{Missing,Float64}}(df[:, date_cols])
ELEV = Float64.(df.elevation)

n_site, n_visit = size(Y)

elev_z = (ELEV .- mean(ELEV)) ./ std(ELEV)

date_vec = collect(skipmissing(vec(DATE)))
date_mu, date_sd = mean(date_vec), std(date_vec)
date_z = [ismissing(DATE[i, j]) ? missing : (DATE[i, j] - date_mu) / date_sd
          for i in 1:n_site, j in 1:n_visit]

# -----------------------------------------------------------------------
# 1. Naive occupancy: proportion of sites with >=1 detection across visits
# -----------------------------------------------------------------------
plogis(x) = 1.0 / (1.0 + exp(-x))

any_detect = [any(skipmissing(Y[i, :]) .== 1.0) for i in 1:n_site]
naive_occupancy = mean(any_detect)
println("Naive occupancy (proportion of sites with >=1 detection): ", round(naive_occupancy, digits=3))

# -----------------------------------------------------------------------
# 2. Single-season occupancy model: psi ~ elevation, p ~ date
#    Hand-rolled marginal-likelihood MLE via Optim.jl
# -----------------------------------------------------------------------
function neg_log_lik(par, Y, elev_z, date_z)
    b0, b1, a0, a1 = par
    n, J = size(Y)
    psi = plogis.(b0 .+ b1 .* elev_z)
    ll = 0.0
    for i in 1:n
        obs_idx = findall(j -> !ismissing(Y[i, j]), 1:J)
        isempty(obs_idx) && continue
        p_ij = [plogis(a0 + a1 * date_z[i, j]) for j in obs_idx]
        y_ij = [Y[i, j] for j in obs_idx]
        if any(y_ij .== 1.0)
            lik = psi[i] * prod(p_ij[k]^y_ij[k] * (1 - p_ij[k])^(1 - y_ij[k]) for k in eachindex(p_ij))
        else
            lik = psi[i] * prod(1 .- p_ij) + (1 - psi[i])
        end
        ll += log(max(lik, 1e-12))
    end
    return -ll
end

start = zeros(4)
result = optimize(par -> neg_log_lik(par, Y, elev_z, date_z), start, BFGS())

coef_hat = Optim.minimizer(result)
param_names = ["psi_intercept", "psi_elevation", "p_intercept", "p_date"]

println("\nMLE coefficients (logit scale):")
for (name, est) in zip(param_names, coef_hat)
    println("  ", name, " = ", round(est, digits=4))
end

psi_hat_site = plogis.(coef_hat[1] .+ coef_hat[2] .* elev_z)
model_occupancy = mean(psi_hat_site)

println("\nModel-estimated occupancy (mean psi_hat across sites): ", round(model_occupancy, digits=3))
println("Naive occupancy                                       : ", round(naive_occupancy, digits=3))
println("Correction for imperfect detection (model - naive)    : +", round(model_occupancy - naive_occupancy, digits=3))

# -----------------------------------------------------------------------
# 3. Figure: naive vs model-estimated occupancy, and psi_hat vs elevation
# -----------------------------------------------------------------------
mkpath("figures")

p1 = bar(["Naive", "Model-estimated"], [naive_occupancy, model_occupancy],
         color = [:gray, :steelblue], ylim = (0, 1),
         ylabel = "Occupancy proportion", title = "Naive vs Model-Estimated Occupancy",
         legend = false)

ord = sortperm(elev_z)
p2 = plot(ELEV[ord], psi_hat_site[ord], lw = 2, color = :steelblue,
          xlabel = "Elevation (m)", ylabel = "psi_hat",
          title = "Estimated psi vs Elevation", ylim = (0, 1), legend = false)

plt = plot(p1, p2, layout = (1, 2), size = (1100, 500))
savefig(plt, "figures/lecture_11_naive_vs_estimated_occupancy.png")
println("\nSaved figures/lecture_11_naive_vs_estimated_occupancy.png")

# =============================================================================
# --- EXERCISES ---
# See exercises/lecture_11_exercises.md. TODOs to implement here:
# 1. TODO: Re-simulate the dataset (or subset detection columns) at lower and
#    higher true detection probability (e.g. modify alpha0 in
#    generate_crossbill_data.R) and recompute naive vs model-estimated
#    occupancy for each; compare how the gap changes.
# 2. TODO: Add a quadratic elevation term to psi (b0 + b1*elev_z + b2*elev_z^2)
#    in neg_log_lik and re-fit with Optim.jl; compare AIC (2*k - 2*logLik) to
#    the linear model.
# 3. TODO: Refit using only det_cols[1:2] / date_cols[1:2] (drop the third
#    visit) and compare coefficient estimates to the 3-visit fit -- what
#    happens to identifiability/precision?
# 4. TODO: Simulate a single-visit-only dataset (J=1) and show empirically
#    that psi and p become non-identifiable (try fitting neg_log_lik on it).
# =============================================================================
