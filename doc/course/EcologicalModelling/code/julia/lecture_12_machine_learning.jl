## ============================================================
## Lecture 12 -- Machine Learning
## Ecological Modelling with R, Python, and Julia
##
## Dataset:
##   data/dune_species.csv (20 sites x 30 plant species abundance, wide
##                           format, first column "site")
##   data/dune_env.csv     (site, A1, Moisture, Management, Use, Manure)
##   Jongman, ter Braak & van Tongeren -- Dutch dune meadow vegetation survey.
##
## Task: predict Management regime (4 classes: BF = biological farming,
##       HF = hobby farming, NM = nature conservation, SF = standard
##       farming) from the plant species community matrix alone -- the
##       same ecological "predict site type from community composition"
##       classification task used in the R and Python scripts for this
##       lecture, so results are directly comparable across languages.
##
## Methods:
##   1. Random Forest classifier (DecisionTree.jl's RandomForestClassifier)
##      -- bagged decision trees, out-of-bag (OOB) error via
##      `DecisionTree.build_forest`, and a simple permutation-based
##      variable importance.
##   2. 5-fold cross-validation (DecisionTree.jl's `nfoldCV_forest`) to
##      estimate out-of-sample accuracy independently of the OOB estimate.
##   3. Gradient Boosted Trees -- DecisionTree.jl does not ship a native
##      gradient-boosting classifier, so we use `AdaBoostStumpClassifier`
##      (a boosted-stumps ensemble, the classic boosting algorithm that
##      GBM generalizes) as the boosting comparator, fit one-vs-rest for
##      each of the 4 Management classes. This keeps the same "bagging vs.
##      boosting" comparison as the R (gbm) and Python
##      (GradientBoostingClassifier) scripts, using the boosting tool
##      that is idiomatic in the DecisionTree.jl ecosystem.
##   4. Variable (species) importance and a bar plot of the top species
##      from the random forest, saved to
##      figures/lecture_12_variable_importance.png.
##
## NOTE ON THE BROADER JULIA ML ECOSYSTEM:
##   For a unified, scikit-learn-style interface across many algorithms
##   (random forests, boosting, GLMs, SVMs, pipelines, tuning, and more),
##   the standard choice in Julia is MLJ.jl, which wraps DecisionTree.jl
##   (and dozens of other packages) behind a single consistent API
##   (`machine`, `fit!`, `predict`, `evaluate!`). This script uses
##   DecisionTree.jl directly for transparency about what a random forest
##   and a boosted ensemble actually do; MLJ.jl is worth adopting once you
##   are comparing many model families routinely.
##
## Honest caveat: with only 20 sites, 5-fold CV means ~4 sites per test
## fold -- accuracy estimates here are noisy and illustrate the *method*,
## not a claim of a reliable operational classifier.
##
## This script is written from the documented DecisionTree.jl API but has
## NOT been executed in this environment (DecisionTree.jl is not
## installed here). Cross-check function signatures against the installed
## package version before running.
##
## Assumes working directory = repository root, i.e. run as:
##   julia code/julia/lecture_12_machine_learning.jl
## ============================================================

using CSV
using DataFrames
using Statistics
using Random
using Plots

using DecisionTree
# Broader Julia ML framework (not used here, see note above):
# using MLJ

Random.seed!(12)
isdir("figures") || mkpath("figures")

## ------------------------------------------------------------
## 0. Load and join species matrix with Management labels
## ------------------------------------------------------------
dune_sp  = CSV.read("data/dune_species.csv", DataFrame)
dune_env = CSV.read("data/dune_env.csv", DataFrame)

dat = innerjoin(dune_env[:, [:site, :Management]], dune_sp, on = :site)
select!(dat, Not(:site))

species_cols = filter(c -> c != "Management", names(dat))
X = Matrix{Float64}(dat[:, species_cols])
y = String.(dat.Management)

println("Sites: ", size(X, 1), "  Species predictors: ", size(X, 2))
println("Management class counts:")
for cls in unique(y)
    println("  ", cls, ": ", count(==(cls), y))
end

## ------------------------------------------------------------
## 1. Random Forest classifier
## ------------------------------------------------------------
n_features   = size(X, 2)
n_subfeatures = round(Int, sqrt(n_features))   # like R's/Python's max_features="sqrt"
n_trees      = 500
partial_sampling = 0.7   # fraction of rows bootstrapped per tree (bagging)
max_depth    = -1        # unlimited

rf_model = build_forest(y, X, n_subfeatures, n_trees, partial_sampling,
                         max_depth)

println("\n--- Random Forest ---")
println(rf_model)

# Out-of-bag-style estimate via DecisionTree.jl's built-in CV utility
# (DecisionTree.jl does not expose a direct .oob_score_ like sklearn; we
# use nfoldCV_forest below for a proper, comparable out-of-sample number).

## ------------------------------------------------------------
## 2. 5-fold cross-validation of the random forest
##    (an out-of-sample accuracy estimate, directly analogous to the R
##     and Python 5-fold CV blocks in this lecture)
## ------------------------------------------------------------
n_folds = 5
accuracy_per_fold = nfoldCV_forest(y, X, n_folds, n_subfeatures, n_trees,
                                    partial_sampling, max_depth;
                                    verbose = false)

println("\n--- 5-fold CV (Random Forest) ---")
println("Per-fold accuracy: ", round.(accuracy_per_fold, digits = 3))
println("Mean CV accuracy: ", round(mean(accuracy_per_fold), digits = 3),
        " (SD ", round(std(accuracy_per_fold), digits = 3), ")")
println("NOTE: with 20 sites split 5 ways, each test fold has only ~4 ",
        "sites --")
println("      these accuracy numbers are illustrative of the method, ",
        "not a precise, low-variance estimate.")

## ------------------------------------------------------------
## 3. Boosted ensemble comparator (AdaBoost stumps, one-vs-rest)
##    -- the boosting analogue of the R gbm / Python GradientBoosting
##    models above, using DecisionTree.jl's native boosting algorithm.
## ------------------------------------------------------------
classes = sort(unique(y))
n_iterations = 100

println("\n--- Boosted Stumps (AdaBoost, one-vs-rest) ---")
ovr_cv_accuracy = Dict{String, Float64}()
for cls in classes
    y_bin = ifelse.(y .== cls, "yes", "no")
    fold_acc = nfoldCV_stumps(y_bin, X, n_folds, n_iterations;
                               verbose = false)
    ovr_cv_accuracy[cls] = mean(fold_acc)
    println("  Class '", cls, "' vs. rest -- mean 5-fold CV accuracy: ",
            round(mean(fold_acc), digits = 3))
end

## ------------------------------------------------------------
## 4. Variable (species) importance
##    DecisionTree.jl does not return impurity-based importances
##    directly from build_forest, so we compute a simple permutation
##    importance: shuffle one species column at a time and measure the
##    drop in training accuracy.
## ------------------------------------------------------------
function permutation_importance(model, X, y; n_repeats = 5)
    n, p = size(X)
    baseline_acc = mean(apply_forest(model, X) .== y)
    importances = zeros(p)
    for j in 1:p
        drops = zeros(n_repeats)
        for r in 1:n_repeats
            Xp = copy(X)
            Xp[:, j] = shuffle(Xp[:, j])
            acc = mean(apply_forest(model, Xp) .== y)
            drops[r] = baseline_acc - acc
        end
        importances[j] = mean(drops)
    end
    return importances
end

imp = permutation_importance(rf_model, X, y)
imp_order = sortperm(imp, rev = true)

println("\nTop 8 species by Random Forest permutation importance:")
for i in imp_order[1:8]
    println("  ", species_cols[i], ": ", round(imp[i], digits = 4))
end

## ------------------------------------------------------------
## 5. Plot: top species by Random Forest importance
## ------------------------------------------------------------
top_n = 10
top_idx = imp_order[1:top_n]
top_species = species_cols[top_idx]
top_imp = imp[top_idx]

# ascending order for a horizontal barplot (largest bar at top)
ord = sortperm(top_imp)

p = bar(top_imp[ord], orientation = :horizontal,
        yticks = (1:top_n, top_species[ord]),
        xlabel = "Permutation Importance (drop in accuracy)",
        title = "Random Forest Variable Importance\n" *
                "(dune species, predicting Management)",
        legend = false, color = :steelblue)

savefig(p, "figures/lecture_12_variable_importance.png")
println("\nFigure saved to figures/lecture_12_variable_importance.png")

## --- EXERCISES ---
## TODO 1: Refit the random forest with a grid of n_trees (e.g. 100, 500,
##         1500) and n_subfeatures (e.g. 2, 5, 10, round(Int,sqrt(29)))
##         values. Use nfoldCV_forest for each combination and report
##         which one maximizes mean CV accuracy.
## TODO 2: Compare Random Forest vs. boosted-stumps out-of-sample
##         accuracy using the SAME number of folds and, ideally, the same
##         fold assignment (set Random.seed!() immediately before each
##         nfoldCV_* call) so the comparison is apples-to-apples.
## TODO 3: Plot and interpret the top-5 most important species for
##         classifying Management -- look up what each species indicates
##         ecologically (e.g. nutrient tolerance, grazing tolerance) and
##         discuss whether the importance ranking matches ecological
##         intuition about the four Management regimes.
## TODO 4: Repeat the random forest and CV analysis on the BCI dataset
##         (data/BCI_species.csv, data/BCI_env.csv) using
##         DecisionTree.jl's build_forest for REGRESSION (a numeric
##         response, e.g. a continuous environmental variable) instead of
##         classification. Compare the R-squared from nfoldCV_forest to
##         what a linear model achieves on the same data.
