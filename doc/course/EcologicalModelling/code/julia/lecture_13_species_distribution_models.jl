## ============================================================
## Lecture 13 -- Species Distribution / Niche Models
## Ecological Modelling with R, Python, and Julia
##
## Dataset:
##   data/bei_points.csv          (x, y coordinates of 3604 individually
##                                  mapped Beilschmiedia pendula trees)
##   data/bei_covariates_grid.csv (x, y, elev, grad -- a fine regular grid
##                                  of elevation and slope-gradient
##                                  covariates across the same plot)
##   Barro Colorado Island 50-ha forest census: Condit, Hubbell & Foster
##   (2002), Science; Hubbell et al. (1999), Science. One of the most-cited
##   real datasets in spatial/community ecology, and the standard teaching
##   example for spatial point-process / SDM-style modeling.
##
## Task: we only have tree LOCATIONS, not surveyed absences -- the classic
##       presence-only / presence-background SDM data problem. We generate
##       random background points across the plot, build a presence (1)
##       vs. background (0) classification dataset with elev/grad
##       covariates, and fit a logistic regression SDM (GLM.jl) and a
##       Random Forest SDM (DecisionTree.jl, reusing Lecture 12's
##       toolkit), compare them by AUC, and produce a habitat-suitability
##       map.
##
## This script is written from the documented GLM.jl / DecisionTree.jl /
## NearestNeighbors.jl APIs but has NOT been executed in this environment
## (none of these packages are installed here). Cross-check function
## signatures against the installed package versions before running.
##
## Assumes working directory = repository root, i.e. run as:
##   julia code/julia/lecture_13_species_distribution_models.jl
## ============================================================

using CSV
using DataFrames
using Statistics
using Random
using Plots

using GLM                  # binomial logistic regression
using DecisionTree         # random forest (same toolkit as Lecture 12)
using NearestNeighbors     # KD-tree nearest-neighbour lookup

Random.seed!(13)
isdir("figures") || mkpath("figures")

## ------------------------------------------------------------
## 0. Load data
## ------------------------------------------------------------
pts  = CSV.read("data/bei_points.csv", DataFrame)
grid = CSV.read("data/bei_covariates_grid.csv", DataFrame)

println("Tree locations: ", nrow(pts))
println("Covariate grid cells: ", nrow(grid))
println("Plot extent: x in [", minimum(grid.x), ", ", maximum(grid.x),
        "]  y in [", minimum(grid.y), ", ", maximum(grid.y), "]")

## ------------------------------------------------------------
## 1. Nearest-neighbour join: extract elev/grad at each tree location
##    from the nearest grid cell using a KD-tree (grid is regular but
##    tree coordinates are continuous).
##    NearestNeighbors.jl expects points as columns, dim x n.
## ------------------------------------------------------------
grid_xy = permutedims(Matrix(grid[:, [:x, :y]]))   # 2 x n_grid
kdtree = KDTree(grid_xy)

pts_xy = permutedims(Matrix(pts[:, [:x, :y]]))     # 2 x n_pts
idx_presence, _ = knn(kdtree, pts_xy, 1)
idx_presence = first.(idx_presence)                # vector of nearest indices

pts = copy(pts)
pts.elev = grid.elev[idx_presence]
pts.grad = grid.grad[idx_presence]

## ------------------------------------------------------------
## 2. Background (pseudo-absence) points
##    Standard presence-background workaround: sample random points
##    across the study area to contrast against presence locations.
##    We sample 2x as many background points as presences, directly
##    from the covariate grid's coordinate range, with a fixed seed.
## ------------------------------------------------------------
n_presence   = nrow(pts)
n_background = 2 * n_presence

bg_x = rand(n_background) .* (maximum(grid.x) - minimum(grid.x)) .+ minimum(grid.x)
bg_y = rand(n_background) .* (maximum(grid.y) - minimum(grid.y)) .+ minimum(grid.y)

bg_xy = permutedims(hcat(bg_x, bg_y))              # 2 x n_background
idx_bg, _ = knn(kdtree, bg_xy, 1)
idx_bg = first.(idx_bg)

background = DataFrame(
    x = bg_x, y = bg_y,
    elev = grid.elev[idx_bg],
    grad = grid.grad[idx_bg],
)

## ------------------------------------------------------------
## 3. Build the presence (1) / background (0) classification dataset
## ------------------------------------------------------------
dat = vcat(
    DataFrame(presence = ones(Int, n_presence), x = pts.x, y = pts.y,
              elev = pts.elev, grad = pts.grad),
    DataFrame(presence = zeros(Int, n_background), x = background.x,
              y = background.y, elev = background.elev, grad = background.grad),
)

println("\nPresence-background dataset:")
println("  Presence points:   ", sum(dat.presence .== 1))
println("  Background points: ", sum(dat.presence .== 0))

## Train/test split for honest AUC estimation
n = nrow(dat)
perm = randperm(n)
n_train = floor(Int, 0.75 * n)
train_idx = perm[1:n_train]
test_idx  = perm[(n_train + 1):end]
train_dat = dat[train_idx, :]
test_dat  = dat[test_idx, :]

## ------------------------------------------------------------
## 4. Logistic regression SDM: presence ~ elev + grad
## ------------------------------------------------------------
glm_fit = glm(@formula(presence ~ elev + grad), train_dat, Binomial(), LogitLink())

println("\n--- Logistic Regression SDM ---")
println(glm_fit)
println("AIC: ", round(aic(glm_fit), digits = 1))

glm_pred_test = predict(glm_fit, test_dat)

## Rank-based (Mann-Whitney U) AUC -- no extra AUC package needed
function auc_rank(scores::AbstractVector, labels::AbstractVector)
    pos = scores[labels .== 1]
    neg = scores[labels .== 0]
    n_pos, n_neg = length(pos), length(neg)
    ranks = invperm(sortperm(vcat(pos, neg)))
    rank_sum_pos = sum(ranks[1:n_pos])
    return (rank_sum_pos - n_pos * (n_pos + 1) / 2) / (n_pos * n_neg)
end

glm_auc = auc_rank(glm_pred_test, test_dat.presence)
glm_acc = mean((glm_pred_test .> 0.5) .== (test_dat.presence .== 1))
println("Held-out test AUC (GLM): ", round(glm_auc, digits = 3))
println("Held-out test accuracy (GLM, 0.5 cutoff): ", round(glm_acc, digits = 3))

## ------------------------------------------------------------
## 5. Random Forest SDM (DecisionTree.jl, reusing Lecture 12's toolkit)
## ------------------------------------------------------------
X_train = Matrix{Float64}(train_dat[:, [:elev, :grad]])
y_train_labels = string.(train_dat.presence)     # DecisionTree.jl wants a class vector
X_test = Matrix{Float64}(test_dat[:, [:elev, :grad]])

n_subfeatures = 1     # like R's/Python's default sqrt(2 features) ~= 1
n_trees = 500
partial_sampling = 0.7
max_depth = -1

rf_model = build_forest(y_train_labels, X_train, n_subfeatures, n_trees,
                         partial_sampling, max_depth)

println("\n--- Random Forest SDM ---")
println(rf_model)

## Predicted class probabilities on the test set
rf_probs_test = apply_forest_proba(rf_model, X_test, ["0", "1"])
rf_pred_test = rf_probs_test[:, 2]   # P(presence = 1)

rf_auc = auc_rank(rf_pred_test, test_dat.presence)
rf_pred_class = apply_forest(rf_model, X_test)
rf_acc = mean(parse.(Int, rf_pred_class) .== test_dat.presence)
println("Held-out test AUC (Random Forest): ", round(rf_auc, digits = 3))
println("Held-out test accuracy (Random Forest): ", round(rf_acc, digits = 3))

println("\n--- GLM vs. Random Forest, held-out AUC ---")
println("  Logistic regression: ", round(glm_auc, digits = 3))
println("  Random forest:       ", round(rf_auc, digits = 3))

## Permutation-based variable importance (as in Lecture 12's Julia script)
function permutation_importance_rf(model, X, y_true; n_repeats = 5)
    n, p = size(X)
    baseline_acc = mean(parse.(Int, apply_forest(model, X)) .== y_true)
    importances = zeros(p)
    for j in 1:p
        drops = zeros(n_repeats)
        for r in 1:n_repeats
            Xp = copy(X)
            Xp[:, j] = shuffle(Xp[:, j])
            acc = mean(parse.(Int, apply_forest(model, Xp)) .== y_true)
            drops[r] = baseline_acc - acc
        end
        importances[j] = mean(drops)
    end
    return importances
end

rf_importance = permutation_importance_rf(rf_model, X_test, test_dat.presence)
println("\nVariable importance (permutation, elev then grad): ",
        round.(rf_importance, digits = 4))

## ------------------------------------------------------------
## 6. Partial dependence on elevation (grad held at its median)
##    -- what did the GLM/RF learn about Beilschmiedia's elevation
##    preference on BCI?
## ------------------------------------------------------------
elev_seq = range(minimum(grid.elev), maximum(grid.elev), length = 100)
grad_median = median(dat.grad)
pd_dat = DataFrame(elev = collect(elev_seq), grad = fill(grad_median, 100))

pd_dat.glm_suitability = predict(glm_fit, pd_dat)
pd_X = Matrix{Float64}(pd_dat[:, [:elev, :grad]])
pd_probs = apply_forest_proba(rf_model, pd_X, ["0", "1"])
pd_dat.rf_suitability = pd_probs[:, 2]

println("\n--- Partial dependence on elevation (grad held at median) ---")
println("Elevation range in data: ", round(minimum(dat.elev), digits = 1), " to ",
        round(maximum(dat.elev), digits = 1))
println("GLM: suitability is monotonic (no interior optimum by construction);")
println("     max predicted suitability at elev = ",
        round(pd_dat.elev[argmax(pd_dat.glm_suitability)], digits = 1), " m")
println("RF:  max predicted suitability at elev = ",
        round(pd_dat.elev[argmax(pd_dat.rf_suitability)], digits = 1), " m")

## ------------------------------------------------------------
## 7. Predict suitability across the full covariate grid and map it
##    (Random Forest prediction shown here -- the same idea applies to
##    the GLM; both models predict a probability for every grid cell.)
## ------------------------------------------------------------
X_grid = Matrix{Float64}(grid[:, [:elev, :grad]])
grid_probs = apply_forest_proba(rf_model, X_grid, ["0", "1"])
grid.suitability_rf = grid_probs[:, 2]
grid.suitability_glm = predict(glm_fit, grid)

println("\nSuitability grid summary (Random Forest):")
println("  min:    ", round(minimum(grid.suitability_rf), digits = 3))
println("  median: ", round(median(grid.suitability_rf), digits = 3))
println("  mean:   ", round(mean(grid.suitability_rf), digits = 3))
println("  max:    ", round(maximum(grid.suitability_rf), digits = 3))

p = scatter(grid.x, grid.y, zcolor = grid.suitability_rf,
            markersize = 2, markerstrokewidth = 0, markershape = :square,
            color = :viridis, aspect_ratio = :equal,
            xlabel = "x (m)", ylabel = "y (m)",
            title = "Beilschmiedia pendula habitat suitability (Random Forest SDM)\n" *
                    "Barro Colorado Island 50-ha plot -- presence-background model",
            colorbar_title = "Predicted suitability", legend = false)

savefig(p, "figures/lecture_13_suitability_map.png")
println("\nFigure saved to figures/lecture_13_suitability_map.png")

## --- EXERCISES ---
## TODO 1: Resample background points at 2x and 4x the presence count
##         used here (n_background = 2 * n_presence). Refit the logistic
##         regression each time with `glm(...)` and compare the elev/grad
##         coefficients (coef(glm_fit)) -- how sensitive is the model to
##         the number of background points?
## TODO 2: Add an elev^2 term to the GLM formula
##         (@formula(presence ~ elev + elev^2 + grad)) to allow an
##         interior elevation optimum rather than a monotonic response.
##         Compare AIC to the linear-elevation model and re-plot the
##         partial dependence curve.
## TODO 3: Using the SAME train/test split (train_idx/test_idx above),
##         compare RF vs. GLM AUC and accuracy across a few different
##         Random.seed!() values used to build `perm`. How much does the
##         "winner" change seed to seed?
## TODO 4: The train/test split here is a simple random split of
##         presence+background points, which does NOT account for
##         spatial autocorrelation (nearby points are not independent).
##         Try a spatial block split instead (e.g. dat.x .< 500 for
##         training, dat.x .>= 500 for testing) and compare AUC to the
##         random-split estimate above -- is the spatially honest AUC
##         higher or lower, and why?
