## ============================================================
## Lecture 16 -- Spatial Modeling (course finale)
## Ecological Modelling with R, Python, and Julia
##
## Datasets:
##   data/mite_env.csv            (SubsDens, WatrCont, Substrate, Shrub,
##                                  Topo, x, y for 70 oribatid mite cores,
##                                  Lac Cromwell -- Borcard & Legendre 1994,
##                                  Ecology)
##   data/bei_points.csv          (x, y of 3604 individually mapped
##                                  Beilschmiedia pendula trees)
##   data/bei_covariates_grid.csv (x, y, elev, grad -- a fine regular grid
##                                  of elevation/slope-gradient covariates)
##   Barro Colorado Island 50-ha forest census: Condit, Hubbell & Foster
##   (2002), Science.
##
## Part 1: Spatial autocorrelation. Every model in Lectures 5-13 assumes
##         independent residuals. We quantify how badly that assumption
##         is violated for mite WatrCont using a hand-rolled Moran's I on
##         a k-nearest-neighbour spatial weights matrix, with a
##         permutation test -- matching R's spdep-free hand-rolled
##         version and Python's esda version.
##
## Part 2: Spatial point process modeling. The BEI tree locations are
##         binned into a coarse grid and modeled with a discretized
##         Poisson GLM (GLM.jl) -- a piecewise-constant approximation to
##         a continuous-space inhomogeneous Poisson point process, and
##         the direct extension of Lecture 13's presence-background SDM
##         into a formal point-process framework.
##
## This script is written from the documented GLM.jl / NearestNeighbors.jl
## APIs but has NOT been executed in this environment (these packages are
## not installed here). Cross-check function signatures against the
## installed package versions before running.
##
## Assumes working directory = repository root, i.e. run as:
##   julia code/julia/lecture_16_spatial_modeling.jl
## ============================================================

using CSV
using DataFrames
using Statistics
using StatsBase        # sample(), for the permutation test
using Random
using Plots

using GLM               # Poisson GLM for the discretized point process
using NearestNeighbors  # KD-tree k-NN lookup for spatial weights

Random.seed!(16)
isdir("figures") || mkpath("figures")

## ============================================================
## PART 1 -- Moran's I on mite WatrCont (spatial autocorrelation)
## ============================================================

mite_env = CSV.read("data/mite_env.csv", DataFrame)
println("Mite cores: ", nrow(mite_env))
println("x range: ", extrema(mite_env.x), "  y range: ", extrema(mite_env.y))
println()

## ------------------------------------------------------------
## 1. Build a k-nearest-neighbour spatial weights matrix (k = 5),
##    hand-rolled: row-standardized so each row of W sums to 1.
##    NearestNeighbors.jl expects points as columns (dim x n).
## ------------------------------------------------------------
function knn_weights(coords_xy::AbstractMatrix, k::Int)
    # coords_xy: n x 2 matrix of (x, y)
    n = size(coords_xy, 1)
    tree = KDTree(permutedims(coords_xy))         # 2 x n for NearestNeighbors.jl
    idxs, _ = knn(tree, permutedims(coords_xy), k + 1)  # k+1: point itself is closest
    W = zeros(n, n)
    for i in 1:n
        neighbours = filter(!=(i), idxs[i])[1:k]   # drop self, keep k nearest
        W[i, neighbours] .= 1.0 / k
    end
    return W
end

k = 5
coords = Matrix(mite_env[:, [:x, :y]])
W = knn_weights(coords, k)

## ------------------------------------------------------------
## 2. Moran's I, hand-rolled (identical formula to the R/Python scripts):
##      I = (n / S0) * sum_ij( w_ij * (x_i - xbar) * (x_j - xbar) )
##              / sum_i( (x_i - xbar)^2 )
##    S0 = sum of all weights = n here, since W is row-standardized.
## ------------------------------------------------------------
function morans_i(x::AbstractVector, W::AbstractMatrix)
    n = length(x)
    xbar = mean(x)
    dev = x .- xbar
    S0 = sum(W)
    num = sum(W .* (dev * dev'))
    den = sum(dev .^ 2)
    return (n / S0) * (num / den)
end

watr = mite_env.WatrCont
I_obs = morans_i(watr, W)
println("Observed Moran's I for WatrCont (k=$k NN weights): ", round(I_obs, digits = 4))

n = nrow(mite_env)
I_expected = -1 / (n - 1)
println("Expected I under no autocorrelation: ", round(I_expected, digits = 4))

## ------------------------------------------------------------
## 3. Permutation test: shuffle WatrCont, recompute I, build a null
##    distribution, and get a one-sided permutation p-value.
## ------------------------------------------------------------
n_perm = 999
I_perm = zeros(n_perm)
for p in 1:n_perm
    I_perm[p] = morans_i(shuffle(watr), W)
end

p_value = (count(>=(I_obs), I_perm) + 1) / (n_perm + 1)
println("Permutation-based p-value ($n_perm permutations, one-sided): ",
        round(p_value, digits = 4))
println("Null distribution: mean = ", round(mean(I_perm), digits = 4),
        ", SD = ", round(std(I_perm), digits = 4))

if p_value < 0.05
    println("--> Significant POSITIVE spatial autocorrelation in WatrCont:")
    println("    nearby cores have more similar water content than expected")
    println("    by chance. The independence assumption behind ordinary")
    println("    GLM/GAM standard errors is violated for this variable.")
end

## ------------------------------------------------------------
## 4. Moran scatterplot: WatrCont vs. its spatially lagged value.
## ------------------------------------------------------------
lagged_watr = W * watr

## Simple OLS slope/intercept via the normal equations (no extra package)
X_design = hcat(ones(n), watr)
beta = X_design \ lagged_watr
intercept, slope = beta[1], beta[2]
println("\nMoran scatterplot regression slope: ", round(slope, digits = 4),
        " (compare to I = ", round(I_obs, digits = 4), ")")

p1 = scatter(watr, lagged_watr, markersize = 5, markerstrokewidth = 0,
             color = :steelblue, alpha = 0.7, legend = false,
             xlabel = "WatrCont (site i)",
             ylabel = "Spatially lagged WatrCont (mean of k=5 NN)",
             title = "Moran Scatterplot -- WatrCont " *
                     "(Moran's I = $(round(I_obs, digits=3)), " *
                     "p = $(round(p_value, digits=3)))")
vline!(p1, [mean(watr)], linestyle = :dot, color = :grey)
hline!(p1, [mean(lagged_watr)], linestyle = :dot, color = :grey)
xs_line = range(minimum(watr), maximum(watr), length = 100)
plot!(p1, xs_line, intercept .+ slope .* xs_line, color = :firebrick, linewidth = 2)

savefig(p1, "figures/lecture_16_moran_scatterplot.png")
println("Figure saved to figures/lecture_16_moran_scatterplot.png")

## ------------------------------------------------------------
## 5. What to do about it: a GAM with a 2-D smooth s(x, y) (Lecture 8)
##    absorbs the leftover spatial surface. Julia has no widely-used
##    2-D thin-plate smoother as turnkey as mgcv's s(x, y); a quadratic
##    trend-surface regression (via GLM.jl's lm) is a simple, honest
##    stand-in that captures the same idea -- a smooth function of x, y.
## ------------------------------------------------------------
mite_env.x2 = mite_env.x .^ 2
mite_env.y2 = mite_env.y .^ 2
mite_env.xy = mite_env.x .* mite_env.y

trend_fit = lm(@formula(WatrCont ~ x + y + x2 + y2 + xy), mite_env)
println("\n--- Trend-surface regression (polynomial stand-in for s(x,y)) ---")
println(trend_fit)

resid_trend = residuals(trend_fit)
I_resid = morans_i(resid_trend, W)
println("\nMoran's I of the trend-surface residuals: ", round(I_resid, digits = 4))
println("(vs. Moran's I of the raw data: ", round(I_obs, digits = 4),
        ") -- modeling x, y directly absorbs a large share of the",
        " spatial structure.")

## ============================================================
## PART 2 -- Discretized inhomogeneous Poisson point process (BEI trees)
## ============================================================

println("\n\n============================================================")
println("PART 2: Spatial point process model -- BEI Beilschmiedia trees")
println("============================================================\n")

pts  = CSV.read("data/bei_points.csv", DataFrame)
grid = CSV.read("data/bei_covariates_grid.csv", DataFrame)

println("Tree locations: ", nrow(pts))
println("Covariate grid cells: ", nrow(grid))

## ------------------------------------------------------------
## 1. Bin the plot into a coarse regular grid (25 x 10 cells) and count
##    trees per cell -- a piecewise-constant approximation to a
##    continuous-space inhomogeneous Poisson process.
## ------------------------------------------------------------
n_bins_x, n_bins_y = 25, 10
x_breaks = range(minimum(grid.x), maximum(grid.x), length = n_bins_x + 1)
y_breaks = range(minimum(grid.y), maximum(grid.y), length = n_bins_y + 1)
cell_area = step(x_breaks) * step(y_breaks)

## bin index for a value v given break vector `breaks` (1-based, clamped)
function bin_index(v::Real, breaks::AbstractRange)
    nb = length(breaks) - 1
    i = searchsortedlast(breaks, v)
    return clamp(i, 1, nb)
end

pts.bin_x = [bin_index(v, x_breaks) for v in pts.x]
pts.bin_y = [bin_index(v, y_breaks) for v in pts.y]

grid.bin_x = [bin_index(v, x_breaks) for v in grid.x]
grid.bin_y = [bin_index(v, y_breaks) for v in grid.y]

cell_cov = combine(groupby(grid, [:bin_x, :bin_y]),
                    :elev => mean => :elev, :grad => mean => :grad)

counts = combine(groupby(pts, [:bin_x, :bin_y]), nrow => :count)

cell_dat = leftjoin(cell_cov, counts, on = [:bin_x, :bin_y])
cell_dat.count = coalesce.(cell_dat.count, 0)
cell_dat.cell_area = fill(cell_area, nrow(cell_dat))
cell_dat.log_area = log.(cell_dat.cell_area)

println("\nDiscretized grid: $n_bins_x x $n_bins_y = ", nrow(cell_dat),
        " cells, cell size ", round(step(x_breaks), digits = 1), " x ",
        round(step(y_breaks), digits = 1), " m")
println("Mean tree count per cell: ", round(mean(cell_dat.count), digits = 1),
        " (min ", minimum(cell_dat.count), ", max ", maximum(cell_dat.count), ")")

## ------------------------------------------------------------
## 2. Fit Poisson GLMs of increasing complexity, with a log(cell area)
##    offset, and compare by AIC.
## ------------------------------------------------------------
glm_null = glm(@formula(count ~ 1), cell_dat, Poisson(), LogLink(),
               offset = cell_dat.log_area)
glm_elev = glm(@formula(count ~ elev), cell_dat, Poisson(), LogLink(),
               offset = cell_dat.log_area)
glm_full = glm(@formula(count ~ elev + grad), cell_dat, Poisson(), LogLink(),
               offset = cell_dat.log_area)

println("\n--- Homogeneous Poisson (intercept-only) ---")
println(glm_null)
println("\n--- Inhomogeneous Poisson GLM: ~ elev ---")
println(glm_elev)
println("\n--- Inhomogeneous Poisson GLM: ~ elev + grad ---")
println(glm_full)

println("\n--- Model comparison (AIC) ---")
println("  Homogeneous (intercept only): ", round(aic(glm_null), digits = 1))
println("  ~ elev:                       ", round(aic(glm_elev), digits = 1))
println("  ~ elev + grad:                ", round(aic(glm_full), digits = 1))

## Likelihood ratio test: elev + grad vs elev alone
lr_stat = 2 * (loglikelihood(glm_full) - loglikelihood(glm_elev))
using Distributions: Chisq, ccdf
lr_p = ccdf(Chisq(1), lr_stat)
println("\nLikelihood ratio test (elev+grad vs. elev alone): LR = ",
        round(lr_stat, digits = 2), ", df = 1, p = ", lr_p)

cell_dat.fitted_intensity = predict(glm_full) ./ cell_dat.cell_area
cell_dat.observed_density = cell_dat.count ./ cell_dat.cell_area

## ------------------------------------------------------------
## 3. Figure: observed tree density vs. fitted intensity surface
## ------------------------------------------------------------
obs_mat = fill(NaN, n_bins_y, n_bins_x)
fit_mat = fill(NaN, n_bins_y, n_bins_x)
for row in eachrow(cell_dat)
    obs_mat[row.bin_y, row.bin_x] = row.observed_density
    fit_mat[row.bin_y, row.bin_x] = row.fitted_intensity
end

clims = (minimum(skipmissing(vcat(vec(obs_mat), vec(fit_mat)))),
         maximum(skipmissing(vcat(vec(obs_mat), vec(fit_mat)))))

x_centers = [(x_breaks[i] + x_breaks[i+1]) / 2 for i in 1:n_bins_x]
y_centers = [(y_breaks[i] + y_breaks[i+1]) / 2 for i in 1:n_bins_y]

p_obs = heatmap(x_centers, y_centers, obs_mat, color = :viridis, clims = clims,
                 title = "Observed tree density\n(trees / m^2)",
                 xlabel = "x (m)", ylabel = "y (m)")
p_fit = heatmap(x_centers, y_centers, fit_mat, color = :viridis, clims = clims,
                 title = "Fitted intensity\n(Poisson GLM ~ elev + grad)",
                 xlabel = "x (m)", ylabel = "y (m)")

p2 = plot(p_obs, p_fit, layout = (1, 2), size = (1300, 560),
          plot_title = "BEI 50-ha plot -- Beilschmiedia pendula, " *
                       "inhomogeneous point process")

savefig(p2, "figures/lecture_16_bei_intensity_surface.png")
println("\nFigure saved to figures/lecture_16_bei_intensity_surface.png")

println("\nDone.")

## --- EXERCISES ---
## TODO 1: Recompute Moran's I for WatrCont using k = 3 and k = 10 nearest
##         neighbours instead of k = 5 (change `k` and rebuild `W`). Does
##         the observed I, and its permutation p-value, change much? What
##         does that tell you about the spatial scale at which water
##         content is patchy at this site?
## TODO 2: Fit a richer spatial surface than the quadratic trend-surface
##         model above (e.g. add x^3, y^3, or x^2*y interaction terms) and
##         compare its residual Moran's I to the quadratic version fit
##         here. Does more spatial flexibility keep removing
##         autocorrelation, or does it plateau?
## TODO 3: Refit the BEI point process with just ~ elev (glm_elev above)
##         and compare its AIC to ~ elev + grad (glm_full). Does gradient
##         add real explanatory power, or is elevation alone doing most of
##         the work? Cross-check your conclusion against the LRT above.
## TODO 4: The discretized Poisson GLM used 25 x 10 cells. Refit it with a
##         much coarser grid (e.g. 10 x 4) and a much finer grid (e.g.
##         50 x 20). How do the elev/grad coefficients and AIC change with
##         cell size? What are the tradeoffs of picking cells that are too
##         coarse vs. too fine for this kind of discretized approximation?
## TODO 5: Using glm_full's fitted_intensity surface, identify the grid
##         cell with the single highest predicted tree intensity. Look up
##         its elev and grad values -- does the combination make
##         ecological sense for a species like Beilschmiedia pendula
##         (a shade-tolerant canopy tree), or does it look like an
##         extrapolation artifact from a sparsely sampled corner of
##         covariate space?
