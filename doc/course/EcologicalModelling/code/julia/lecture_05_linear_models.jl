## ============================================================
## Lecture 5 -- Linear Models (Julia)
## Ecological Modelling with R, Python, and Julia
##
## Dataset:
##   data/mite_species.csv + data/mite_env.csv  (Borcard & Legendre 1994,
##                                                Ecology -- oribatid mite
##                                                community, Lac Cromwell
##                                                peat moss, 70 sites)
##
## Response:
##   richness = number of species with nonzero abundance at each site
##
## Models:
##   1. Simple LM:   richness ~ WatrCont                        -- GLM.jl
##   2. Multiple LM: richness ~ WatrCont + SubsDens + Substrate  -- GLM.jl
##   3. Four classic diagnostic plots for the multiple LM        -- Plots.jl
##
## Assumes working directory = repository root, i.e. run as:
##   julia --project=. code/julia/lecture_05_linear_models.jl
## ============================================================

using CSV
using DataFrames
using Statistics
using GLM                # lm(), coeftable, r2, etc. (normal-error linear model)
using StatsModels        # @formula
using Distributions      # Normal() quantiles for the Q-Q plot
using LinearAlgebra      # diag(), inv() for the hat matrix
using Plots
gr()

mkpath("figures")

println("=== Lecture 5: Linear Models (Julia) ===\n")

## ------------------------------------------------------------
## 1. Load and join data, compute richness
## ------------------------------------------------------------

species = CSV.read("data/mite_species.csv", DataFrame)
env = CSV.read("data/mite_env.csv", DataFrame)

sp_cols = names(species)[names(species) .!= "site"]
richness = [count(>(0), Vector(row)) for row in eachrow(species[:, sp_cols])]
rich_df = DataFrame(site = species.site, richness = richness)

dat = innerjoin(env, rich_df, on = :site)
# Substrate is loaded as a String column; StatsModels' @formula machinery
# automatically treats String (and CategoricalArray) columns as categorical
# predictors and dummy-codes them against a reference level, exactly as
# factor() does implicitly inside R's lm().

println("n sites: ", nrow(dat))
println("richness range: ", extrema(dat.richness))
println()

## ------------------------------------------------------------
## 2. Simple linear regression: richness ~ WatrCont
## ------------------------------------------------------------

fit_simple = lm(@formula(richness ~ WatrCont), dat)

println("--- Simple LM: richness ~ WatrCont ---")
println(fit_simple)
println("R2 = ", round(r2(fit_simple), digits = 3),
        ", adj R2 = ", round(adjr2(fit_simple), digits = 3))
println()

## ------------------------------------------------------------
## 3. Multiple linear regression: richness ~ WatrCont + SubsDens + Substrate
## ------------------------------------------------------------

fit_multi = lm(@formula(richness ~ WatrCont + SubsDens + Substrate), dat)

println("--- Multiple LM: richness ~ WatrCont + SubsDens + Substrate ---")
println(fit_multi)
println("R2 = ", round(r2(fit_multi), digits = 3),
        ", adj R2 = ", round(adjr2(fit_multi), digits = 3))
println()

## GLM.jl does not ship a one-line sequential (Type I) ANOVA table for lm()
## the way R does; the standard approach is to compare nested models with
## an F-test via ftest(), which reproduces the same logic anova() uses.
fit_watr_only = lm(@formula(richness ~ WatrCont), dat)
fit_watr_subs = lm(@formula(richness ~ WatrCont + SubsDens), dat)

println("--- Sequential (Type I style) F-tests, nested model comparison ---")
println(ftest(fit_watr_only, fit_watr_subs, fit_multi))
println()

println("R-squared comparison:")
println("  simple model:   R2 = ", round(r2(fit_simple), digits = 3),
        ", adj R2 = ", round(adjr2(fit_simple), digits = 3))
println("  multiple model: R2 = ", round(r2(fit_multi), digits = 3),
        ", adj R2 = ", round(adjr2(fit_multi), digits = 3))
println()

## ------------------------------------------------------------
## 4. Diagnostic plots for the multiple LM
##    residuals vs fitted | Q-Q | scale-location | residuals vs leverage
## ------------------------------------------------------------

fitted_vals = predict(fit_multi)
resid_vals = residuals(fit_multi)

# Studentized (internally standardized) residuals and leverage (hat values).
X = modelmatrix(fit_multi)
hat_diag = diag(X * inv(X' * X) * X')
sigma_hat = sqrt(deviance(fit_multi) / dof_residual(fit_multi))
student_resid = resid_vals ./ (sigma_hat .* sqrt.(1 .- hat_diag))
sqrt_abs_student_resid = sqrt.(abs.(student_resid))

# Cook's distance for the residuals-vs-leverage panel.
p = length(coef(fit_multi))
cooks_d = (student_resid .^ 2 ./ p) .* (hat_diag ./ (1 .- hat_diag))

p1 = scatter(fitted_vals, resid_vals, legend = false,
             xlabel = "Fitted values", ylabel = "Residuals",
             title = "Residuals vs Fitted", markerstrokewidth = 0.5,
             markercolor = :white, markerstrokecolor = :black)
hline!(p1, [0], linestyle = :dash, color = :grey)

sorted_student = sort(student_resid)
n = length(sorted_student)
theoretical_q = [quantile(Normal(), (i - 0.5) / n) for i in 1:n]
p2 = scatter(theoretical_q, sorted_student, legend = false,
             xlabel = "Theoretical quantiles", ylabel = "Sample quantiles",
             title = "Normal Q-Q", markerstrokewidth = 0.5,
             markercolor = :white, markerstrokecolor = :black)
plot!(p2, theoretical_q, theoretical_q, color = :grey, linestyle = :dash)

p3 = scatter(fitted_vals, sqrt_abs_student_resid, legend = false,
             xlabel = "Fitted values", ylabel = "sqrt(|Studentized residuals|)",
             title = "Scale-Location", markerstrokewidth = 0.5,
             markercolor = :white, markerstrokecolor = :black)

p4 = scatter(hat_diag, student_resid, legend = false,
             xlabel = "Leverage", ylabel = "Studentized residuals",
             title = "Residuals vs Leverage", markerstrokewidth = 0.5,
             markercolor = :white, markerstrokecolor = :black)
hline!(p4, [0], linestyle = :dash, color = :grey)

diag_panel = plot(p1, p2, p3, p4, layout = (2, 2), size = (900, 900),
                   plot_title = "Diagnostics: richness ~ WatrCont + SubsDens + Substrate")
savefig(diag_panel, "figures/lecture_05_diagnostics.png")

println("Saved figures/lecture_05_diagnostics.png")
println("\n=== Done ===")

# --- EXERCISES ---
# TODO 1: Fit richness ~ SubsDens alone. Compare its R2 (and adjusted R2) to
#         the richness ~ WatrCont simple model above. Which single predictor
#         explains more variation in richness?
# TODO 2: Fit richness ~ Substrate alone (Substrate as the only predictor).
#         Interpret the coefficients -- what do they represent relative to
#         the reference level? Use ftest() against an intercept-only model
#         to test whether Substrate explains a significant amount of
#         variation.
# TODO 3: Add an interaction term: richness ~ WatrCont * Substrate. Does the
#         slope of richness on WatrCont differ meaningfully across substrate
#         types? Use ftest(fit_multi, fit_interaction) to compare.
# TODO 4: Fit richness ~ WatrCont using only sites with SubsDens > 60 (an
#         extreme subset, e.g. filter(row -> row.SubsDens > 60, dat)) and
#         inspect the four diagnostic plots. Which assumption looks most
#         violated, and what would you do about it?
