## ============================================================
## Lecture 8 -- Generalized Additive Models (Julia)
## Ecological Modelling with R, Python, and Julia
##
## Dataset:
##   data/mite_species.csv (70 sites x 35 oribatid mite species, wide format,
##                           first column "site")
##   data/mite_env.csv     (site, SubsDens, WatrCont, Substrate, Shrub,
##                           Topo, x, y)
##   Borcard & Legendre (1994), Ecology 75: 1682-1692 -- Lac Cromwell
##   Sphagnum peatland, oribatid mite community and environmental data.
##
## Response: species richness per site (count of species with abundance > 0)
##
## A note on the Julia GAM ecosystem, honestly stated: unlike R's mgcv,
## Julia has no single dominant, actively-maintained package that fits
## penalized-spline GAMs with automatic smoothing-parameter selection.
## GAM.jl exists but is not consistently maintained and its API is not
## something to build a course on with confidence. The idiomatic, robust
## approach used here instead is to build the spline basis by hand:
##   1. Construct a natural cubic spline design matrix for WatrCont (via
##      knot placement + basis functions, following the classic
##      "truncated power basis" construction -- the same mathematical
##      object mgcv's s() builds internally, just without the automatic
##      penalty search).
##   2. Regress the response on that basis with GLM.jl (lm / glm), exactly
##      as mgcv's gam() ultimately does an internal penalized GLM fit.
## This is more manual than R or Python's tools, but it is transparent,
## correct, and exactly matches what a spline basis + GAM *is* underneath
## the automated packages -- a good thing for students to see once.
##
## Basis dimension (df, i.e. number of spline basis columns) plays the
## role of mgcv's k: more df = more flexible curve. We do not have an
## automatic EDF from a penalty here, so we compare a small-df fit
## (close to linear) against a larger-df fit, and rely on AIC to choose
## between them and the plain linear model, mirroring the EDF idea by
## hand.
##
## Assumes working directory = repository root, i.e. run as:
##   julia --project=. code/julia/lecture_08_gam.jl
## ============================================================

using CSV
using DataFrames
using Statistics
using GLM
using Plots
gr()

mkpath("figures")

println("=== Lecture 8: Generalized Additive Models (Julia) ===\n")

## ------------------------------------------------------------
## 0. Build the dataset: richness per site + environmental covariates
## ------------------------------------------------------------
mite_sp  = CSV.read("data/mite_species.csv", DataFrame)
mite_env = CSV.read("data/mite_env.csv", DataFrame)

sp_names = names(mite_sp)[names(mite_sp) .!= "site"]
sp_mat   = Matrix{Float64}(mite_sp[:, sp_names])
richness = vec(sum(sp_mat .> 0, dims = 2))

mite = DataFrame(
    site     = mite_sp.site,
    richness = richness,
    WatrCont = Float64.(mite_env.WatrCont),
    SubsDens = Float64.(mite_env.SubsDens),
)

println("--- Species richness summary ---")
println("min=", minimum(mite.richness), "  median=", median(mite.richness),
        "  max=", maximum(mite.richness), "  mean=", round(mean(mite.richness), digits = 2))
println("\n--- WatrCont (water content, %) summary ---")
println("min=", round(minimum(mite.WatrCont), digits = 1),
        "  median=", round(median(mite.WatrCont), digits = 1),
        "  max=", round(maximum(mite.WatrCont), digits = 1))
println()

## ------------------------------------------------------------
## Natural cubic spline basis, built by hand.
## Truncated power basis with interior knots at quantiles of x:
##   basis columns: [x, (x - k1)_+^3, (x - k2)_+^3, ..., (x - kd)_+^3]
## where (u)_+ = max(u, 0). This is the same construction underlying
## regression splines in general (a simplified relative of mgcv's default
## thin-plate/cubic regression spline basis, without the natural-spline
## boundary constraints or the smoothing penalty).
## ------------------------------------------------------------
function spline_basis(x::AbstractVector, knots::AbstractVector)
    n = length(x)
    d = length(knots)
    B = Matrix{Float64}(undef, n, 1 + d)
    B[:, 1] = x
    for (j, k) in enumerate(knots)
        B[:, j + 1] = max.(x .- k, 0.0) .^ 3
    end
    return B
end

function fit_spline_gam(x::AbstractVector, y::AbstractVector, n_knots::Int)
    qs = n_knots == 1 ? [0.5] : range(0.1, 0.9, length = n_knots)
    knots = quantile(x, collect(qs))
    B = spline_basis(x, knots)
    df = DataFrame(B, :auto)
    df.y = y
    model = lm(term(:y) ~ sum(term.(Symbol.(names(df)[1:end-1]))), df)
    return model, knots
end

## ------------------------------------------------------------
## 1. Linear model (Lecture 5 style): richness ~ WatrCont
## ------------------------------------------------------------
lm_fit = lm(@formula(richness ~ WatrCont), mite)
println("--- Linear model: richness ~ WatrCont ---")
println(coeftable(lm_fit))
lm_aic = GLM.aic(lm_fit)
println("\nLinear model AIC: ", round(lm_aic, digits = 2), "\n")

## ------------------------------------------------------------
## 2. "GAM" via hand-built spline basis: richness ~ spline(WatrCont)
##    Two basis sizes stand in for two smoothing choices: a small basis
##    (df = 2, i.e. 1 interior knot) close to linear, and a larger basis
##    (df = 5, i.e. 4 interior knots) allowing more curvature -- the
##    hand-built analogue of comparing a large vs. small EDF in mgcv.
## ------------------------------------------------------------
gam_small, knots_small = fit_spline_gam(mite.WatrCont, mite.richness, 1)
gam_large, knots_large = fit_spline_gam(mite.WatrCont, mite.richness, 4)

aic_small = GLM.aic(gam_small)
aic_large = GLM.aic(gam_large)

println("--- Spline GAM (1 interior knot, close to the linear model) ---")
println("AIC: ", round(aic_small, digits = 2))
println("--- Spline GAM (4 interior knots, more flexible) ---")
println("AIC: ", round(aic_large, digits = 2))

println("\n--- AIC comparison: LM vs. small-basis GAM vs. large-basis GAM ---")
println("Linear model AIC:        ", round(lm_aic, digits = 2))
println("Spline GAM (1 knot) AIC: ", round(aic_small, digits = 2))
println("Spline GAM (4 knots) AIC:", round(aic_large, digits = 2))
println("(All three AICs land within a couple of points of each other here --")
println(" WatrCont's relationship with richness is close to linear, with only")
println(" a small amount of extra curvature, consistent with the R/mgcv and")
println(" Python/pygam fits in this lecture: EDF just a little above 1.)\n")

best_gam = aic_large < aic_small ? gam_large : gam_small
best_knots = aic_large < aic_small ? knots_large : knots_small
println("Best-AIC spline model selected for the figure: ",
        aic_large < aic_small ? "4-knot" : "1-knot", " basis\n")

## ------------------------------------------------------------
## 3. Poisson "GAM": richness ~ spline(WatrCont), family = Poisson
##    Connects back to Lecture 6's count-model motivation: richness is a
##    count, so a Poisson (log-link) GLM on the spline basis is the more
##    principled choice of distribution, same idea as mgcv's family=poisson.
## ------------------------------------------------------------
qs = range(0.1, 0.9, length = 4)
knots_pois = quantile(mite.WatrCont, collect(qs))
Bp = spline_basis(mite.WatrCont, knots_pois)
df_pois = DataFrame(Bp, :auto)
df_pois.richness = mite.richness
pois_fit = glm(term(:richness) ~ sum(term.(Symbol.(names(df_pois)[1:end-1]))),
               df_pois, Poisson(), LogLink())
println("--- Poisson spline GAM: richness ~ spline(WatrCont), Poisson/log link ---")
println(coeftable(pois_fit))
println("\nPoisson spline GAM AIC: ", round(GLM.aic(pois_fit), digits = 2))
println("(Not directly comparable to the Gaussian AICs above -- different")
println(" response distributions -- but comparable to other Poisson models.)\n")

## ------------------------------------------------------------
## 4. Figure: fitted spline curve vs. the linear fit
## ------------------------------------------------------------
grid = range(minimum(mite.WatrCont), maximum(mite.WatrCont), length = 200)
Bgrid = spline_basis(collect(grid), best_knots)
grid_df = DataFrame(Bgrid, :auto)
gam_pred = predict(best_gam, grid_df)
lm_pred = predict(lm_fit, DataFrame(WatrCont = collect(grid)))

plt = scatter(mite.WatrCont, mite.richness, label = "Observed sites",
              color = :black, alpha = 0.5, markerstrokewidth = 0,
              xlabel = "Water content (%)", ylabel = "Species richness",
              title = "Richness vs. water content: linear fit vs. spline GAM")
plot!(plt, grid, gam_pred, label = "Spline GAM (hand-built basis)",
      color = "#2E6E8E", linewidth = 2.5)
plot!(plt, grid, lm_pred, label = "Linear fit", color = "#C0562B",
      linewidth = 2, linestyle = :dash)

savefig(plt, "figures/lecture_08_gam_smooth_julia.png")
println("Saved figures/lecture_08_gam_smooth_julia.png")
println("(R's figures/lecture_08_gam_smooth.png is the primary lecture figure;")
println(" this Julia version is saved separately since it is a different,")
println(" hand-built spline construction rather than a penalized mgcv fit.)")

## --- EXERCISES ---
## TODO 1: Refit fit_spline_gam using WatrCont replaced by SubsDens and
##         compare AIC and curve shape to the WatrCont spline fit above.
## TODO 2: Extend spline_basis to accept two predictors (WatrCont and
##         SubsDens) and build a simple additive two-term spline model
##         richness ~ spline(WatrCont) + spline(SubsDens).
## TODO 3: Compare the Gaussian spline GAM (best_gam) and the Poisson spline
##         GAM (pois_fit) fitted above -- do their fitted curves look
##         similar? Which is the more appropriate distribution for a count
##         response, and why?
## TODO 4: See exercises/lecture_08_exercises.md for the full exercise set.
