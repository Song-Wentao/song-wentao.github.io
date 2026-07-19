## ============================================================
## Lecture 4 -- Multivariate and Ordination Methods (Julia)
## Ecological Modelling with R, Python, and Julia
##
## Datasets:
##   data/varechem.csv + data/varespec.csv   (Vare, Ohtonen & Oksanen 1995,
##                                             J. Vegetation Science -- reindeer
##                                             grazing effects on lichen pastures)
##   data/dune_species.csv + data/dune_env.csv (Jongman, ter Braak & van Tongeren,
##                                             Dutch dune meadow vegetation survey)
##
## Methods:
##   1. PCA on soil chemistry (varechem)          -- MultivariateStats.jl
##   2. NMDS on dune community data (Bray-Curtis)  -- hand-rolled gradient-descent
##      NMDS (Kruskal stress minimization) since Julia has no maintained
##      turnkey NMDS package; kept simple and correct rather than clever.
##   3. PERMANOVA: does Management explain dune community composition?
##      -- hand-rolled permutation test on pseudo-F (same logic as the Python
##         fallback, so students can compare the three languages line-for-line)
##   4. Hierarchical clustering (average linkage)  -- Clustering.jl
##
## Assumes working directory = repository root, i.e. run as:
##   julia --project=. code/julia/lecture_04_multivariate_ordination.jl
## ============================================================

using CSV
using DataFrames
using Statistics
using StatsBase: sample
using LinearAlgebra
using Random
using Distances                 # BrayCurtis, pairwise
using MultivariateStats          # fit(PCA, ...)
using Clustering                  # hclust
using Plots                       # save NMDS figure
gr()

mkpath("figures")

println("=== Lecture 4: Multivariate & Ordination (Julia) ===\n")

## ------------------------------------------------------------
## 1. PCA on soil chemistry -- data/varechem.csv
##    Why standardize: N, P, K, ... are on wildly different scales
##    (mg/kg vs pH units) so raw covariance PCA would be dominated
##    by whichever variable has the largest variance.
## ------------------------------------------------------------

varechem = CSV.read("data/varechem.csv", DataFrame)
chem_names = names(varechem)[names(varechem) .!= "site"]
chem = Matrix{Float64}(varechem[:, chem_names])

# Standardize columns (mean 0, sd 1), then MultivariateStats expects
# variables-as-rows, observations-as-columns, so transpose.
chem_std = (chem .- mean(chem, dims = 1)) ./ std(chem, dims = 1)
pca_model = fit(PCA, permutedims(chem_std); maxoutdim = size(chem_std, 2))

var_explained = principalvars(pca_model) ./ sum(principalvars(pca_model)) .* 100
println("--- PCA on varechem (soil chemistry, 24 sites x 14 variables) ---")
println("Variance explained by PC1-PC4: ", round.(var_explained[1:4], digits = 1))

pc1_loadings = projection(pca_model)[:, 1]
println("\nPC1 loadings (variable contributions):")
for (name, load) in sort(collect(zip(chem_names, pc1_loadings)), by = x -> x[2])
    println("  ", rpad(name, 10), round(load, digits = 3))
end

## ------------------------------------------------------------
## 2. NMDS on dune community data (Bray-Curtis dissimilarity)
##    NMDS does not assume linear relationships between species and axes,
##    which is why it (not PCA) is the workhorse ordination method for
##    community abundance data with many zeros and nonlinear turnover.
## ------------------------------------------------------------

dune_species = CSV.read("data/dune_species.csv", DataFrame)
dune_env     = CSV.read("data/dune_env.csv", DataFrame)

@assert string.(dune_species.site) == string.(dune_env.site)

sp_names = names(dune_species)[names(dune_species) .!= "site"]
sp_mat = Matrix{Float64}(dune_species[:, sp_names])   # sites x species
sites = string.(dune_species.site)
n = size(sp_mat, 1)

# Bray-Curtis distance matrix (sites x sites)
bc_dist = pairwise(BrayCurtis(), permutedims(sp_mat); dims = 2)

"""
    nmds_gradient_descent(D; k=2, n_iter=500, lr=0.05, seed=42)

Minimal, from-scratch nonmetric MDS via isotonic-regression-free "monotone"
stress approximation: we minimize Kruskal stress-1 using a rank-based target
distance (a simple, transparent stand-in for full isotonic regression,
adequate for teaching purposes on a 20-site dataset).
"""
function nmds_gradient_descent(D::AbstractMatrix; k = 2, n_iter = 500, lr = 0.05, seed = 42)
    Random.seed!(seed)
    n = size(D, 1)
    X = 0.1 .* randn(n, k)

    # target (disparities): rank-preserving monotone transform of D via
    # simple linear rescaling of ranks into the observed distance range.
    iu = [(i, j) for i in 1:n for j in (i + 1):n]
    dvec = [D[i, j] for (i, j) in iu]
    order = sortperm(dvec)
    ranks = invperm(order)
    dhat = similar(dvec)
    dmin, dmax = minimum(dvec), maximum(dvec)
    for idx in 1:length(dvec)
        dhat[idx] = dmin + (dmax - dmin) * (ranks[idx] - 1) / (length(dvec) - 1)
    end

    stress = 0.0
    for iter in 1:n_iter
        # current configuration distances
        dcur = [norm(X[i, :] .- X[j, :]) for (i, j) in iu]
        num = sum((dcur .- dhat) .^ 2)
        den = sum(dcur .^ 2)
        stress = sqrt(num / den)

        # gradient of raw stress numerator wrt X (finite-difference-free
        # analytic gradient of sum((d_ij - dhat_ij)^2))
        grad = zeros(n, k)
        for (idx, (i, j)) in enumerate(iu)
            diff = X[i, :] .- X[j, :]
            dij = dcur[idx] < 1e-9 ? 1e-9 : dcur[idx]
            coef = 2 * (dij - dhat[idx]) / dij
            grad[i, :] .+= coef .* diff
            grad[j, :] .-= coef .* diff
        end
        X .-= lr .* grad ./ n
    end
    return X, stress
end

X_nmds, stress = nmds_gradient_descent(bc_dist; k = 2, n_iter = 800, lr = 0.03, seed = 42)

println("\n--- NMDS on dune_species (Bray-Curtis, k = 2, hand-rolled) ---")
println("Stress: ", round(stress, digits = 4),
        " -- rule of thumb: <0.10 excellent, <0.20 usable, >0.20 risky")
println("(A dedicated NMDS package such as vegan in R will generally reach")
println(" lower stress via proper isotonic regression + multiple random starts;")
println(" this implementation favors transparency over polish.)")

## Ordination plot colored by Management
palette = Dict("BF" => :steelblue, "HF" => :orangered, "NM" => :seagreen, "SF" => :purple)
mgmt = string.(dune_env.Management)

plt = plot(; title = "NMDS of Dune Meadow Vegetation (Bray-Curtis)",
           xlabel = "NMDS1", ylabel = "NMDS2", legend = :topright, size = (900, 700))
for lvl in unique(mgmt)
    idx = findall(==(lvl), mgmt)
    scatter!(plt, X_nmds[idx, 1], X_nmds[idx, 2];
             label = lvl, color = palette[lvl], markersize = 6, markerstrokecolor = :white)
end
annotate!(plt, [(X_nmds[i, 1], X_nmds[i, 2] + 0.02, text(sites[i], 6)) for i in 1:n])
savefig(plt, "figures/lecture_04_dune_nmds_julia.png")
println("Saved figures/lecture_04_dune_nmds_julia.png")

## ------------------------------------------------------------
## 3. PERMANOVA -- does Management explain community composition?
##    Hand-rolled permutation test on pseudo-F, computed directly from the
##    Bray-Curtis distance matrix by permuting group labels; this is the
##    multivariate analogue of ANOVA when the response is a distance matrix.
## ------------------------------------------------------------

function pseudo_f(D::AbstractMatrix, groups::Vector{<:AbstractString})
    n = size(D, 1)
    ss_total = sum(D .^ 2) / (2n)
    ss_within = 0.0
    for lvl in unique(groups)
        idx = findall(==(lvl), groups)
        ni = length(idx)
        sub = D[idx, idx]
        ss_within += sum(sub .^ 2) / (2ni)
    end
    ss_among = ss_total - ss_within
    a = length(unique(groups))
    df_among, df_within = a - 1, n - a
    F = (ss_among / df_among) / (ss_within / df_within)
    return F, ss_among, ss_total
end

function permanova(D::AbstractMatrix, groups::Vector{<:AbstractString}; n_perm = 999, seed = 42)
    Random.seed!(seed)
    f_obs, ss_among, ss_total = pseudo_f(D, groups)
    r2 = ss_among / ss_total
    count_ge = 0
    for _ in 1:n_perm
        perm_groups = groups[Random.shuffle(1:length(groups))]
        f_perm, _, _ = pseudo_f(D, perm_groups)
        if f_perm >= f_obs
            count_ge += 1
        end
    end
    p_value = (count_ge + 1) / (n_perm + 1)
    return (pseudo_F = f_obs, R2 = r2, p_value = p_value, n_perm = n_perm)
end

result = permanova(bc_dist, mgmt; n_perm = 999, seed = 42)
println("\n--- PERMANOVA (hand-rolled): bray-curtis distance ~ Management (999 permutations) ---")
println("pseudo-F = ", round(result.pseudo_F, digits = 4),
        ", R2 = ", round(result.R2, digits = 4),
        ", p = ", round(result.p_value, digits = 4),
        " (n_perm = ", result.n_perm, ")")

## ------------------------------------------------------------
## 4. Hierarchical clustering (average linkage) -- complementary,
##    exploratory view of the same Bray-Curtis dissimilarity matrix.
## ------------------------------------------------------------

hc = hclust(bc_dist; linkage = :average)

plt2 = plot(hc; xticks = (1:n, sites[hc.order]), xrotation = 90,
            title = "Average-linkage clustering of dune sites (Bray-Curtis)",
            ylabel = "Bray-Curtis distance", size = (950, 550))
savefig(plt2, "figures/lecture_04_dune_hclust_julia.png")
println("\nSaved figures/lecture_04_dune_hclust_julia.png")

println("\n=== Done ===")

## --- EXERCISES ---
## TODO 1: Run PCA on a subset of varechem variables (e.g. N, P, K, Ca, Mg, pH
##         only). Compare PC1 loadings and % variance explained to the
##         full-variable PCA above. Which variables dominate PC1?
## TODO 2: Refit the PERMANOVA using Moisture instead of Management
##         (permanova(bc_dist, string.(dune_env.Moisture))). Is the pseudo-F
##         larger or smaller than for Management? What does that imply?
## TODO 3: Re-run nmds_gradient_descent with k = 3 instead of k = 2. Does
##         stress drop substantially? Is the extra dimension worth the loss
##         of a simple 2-D plot?
## TODO 4: Cut the hclust dendrogram into 4 groups (cutree(hc; k = 4) from
##         Clustering.jl) and cross-tabulate against dune_env.Management. Do
##         the cluster groups line up with the management categories?
