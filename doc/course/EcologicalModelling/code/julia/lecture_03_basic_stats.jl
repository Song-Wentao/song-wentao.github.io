#=
Lecture 3: Basic Statistical Analysis (Julia)
Ecological Modelling with R, Python, and Julia

Datasets:
    mite_env.csv  -- Borcard & Legendre (1994), Ecology 75(4), oribatid mites
    varechem.csv  -- Vare, Ohtonen & Oksanen (1995), J. Vegetation Science

Convention used all semester:
    - Run scripts with the working directory set to the repository root
      (i.e. the folder that contains data/, code/, figures/, exercises/).
    - Read inputs from   data/<file>.csv
    - Write figures to   figures/lecture_NN_<slug>.png

Packages (add once per environment):
    using Pkg
    Pkg.add(["CSV", "DataFrames", "Statistics", "StatsBase",
              "HypothesisTests", "GLM", "StatsPlots"])
=#

using CSV
using DataFrames
using Statistics       # mean, std, cor
using StatsBase        # corspearman, and general summary helpers
using HypothesisTests  # OneWayANOVATest, UnequalVarianceTTest, ChisqTest, CorrelationTest
using GLM               # lm() for R^2/eta-squared cross-check
using StatsPlots        # boxplot recipe (built on top of Plots.jl)

println("=== Lecture 3: Basic Statistical Analysis (Julia) ===\n")

mite = CSV.read("data/mite_env.csv", DataFrame)
substrate_levels = sort(unique(mite.Substrate))

# ---- 1. Descriptive statistics: mean / sd / CV ------------------------------
cv(x) = std(x) / mean(x) * 100

println("--- Descriptive statistics (mite_env.csv) ---")
for v in [:WatrCont, :SubsDens]
    x = mite[!, v]
    println(rpad(string(v), 10), ": mean = ", round(mean(x), digits=2),
            "  median = ", round(median(x), digits=2),
            "  sd = ", round(std(x), digits=2),
            "  CV = ", round(cv(x), digits=1), "%")
end
println()
# Ecological note: counts, cover, and biomass are frequently right-skewed
# (many small values, a few large ones) -> mean > median, CV often > 50-100%.
# Always inspect the distribution (histogram/boxplot) before assuming normality.

# ---- 2. Two-sample t-test: WatrCont between two Substrate groups ------------
sub_a = mite.WatrCont[mite.Substrate .== "Sphagn1"]
sub_b = mite.WatrCont[mite.Substrate .== "Litter"]

t_res = UnequalVarianceTTest(sub_a, sub_b)   # Welch's t-test
println("--- Two-sample t-test: WatrCont, Sphagn1 vs Litter ---")
println(t_res)
println("Mean Sphagn1 = ", round(mean(sub_a), digits=2),
        ", Mean Litter = ", round(mean(sub_b), digits=2), "\n")

# ---- 3. One-way ANOVA: WatrCont ~ Substrate (all levels) --------------------
groups = [mite.WatrCont[mite.Substrate .== lvl] for lvl in substrate_levels]
anova_res = OneWayANOVATest(groups...)
println("--- One-way ANOVA: WatrCont ~ Substrate ---")
println(anova_res)

# Cross-check with GLM for R^2 / eta-squared
ols_fit = lm(@formula(WatrCont ~ Substrate), mite)
r_sq = r2(ols_fit)
println("\nR^2 (== eta-squared for a one-way design) = ", round(r_sq, digits=3), "\n")

# ---- 4. Post-hoc: Tukey HSD --------------------------------------------------
# HypothesisTests.jl does not ship a Tukey HSD function directly; the standard
# approach is the MultipleComparisons.jl / SimpleANOVA.jl packages, or manual
# pairwise UnequalVarianceTTest() calls with a Bonferroni/Holm correction via
# MultipleTesting.jl. Sketch (pairwise + Holm correction):
#
#   using MultipleTesting
#   lvls = substrate_levels
#   pvals = Float64[]
#   for i in 1:length(lvls), j in (i+1):length(lvls)
#       gi = mite.WatrCont[mite.Substrate .== lvls[i]]
#       gj = mite.WatrCont[mite.Substrate .== lvls[j]]
#       push!(pvals, pvalue(UnequalVarianceTTest(gi, gj)))
#   end
#   adjusted = adjust(pvals, Holm())
#
# For a "true" Tukey-HSD table with the studentized range distribution,
# call out to R via RCall.jl (TukeyHSD(aov(...))) or use SimpleANOVA.jl,
# which implements post-hoc Tukey comparisons natively.

# ---- 5. Correlation matrix: soil chemistry (varechem.csv) -------------------
varechem = CSV.read("data/varechem.csv", DataFrame)
chem_vars = [:N, :P, :K, :Ca, :Mg, :pH]
chem_mat = Matrix(varechem[:, chem_vars])

cor_pearson = cor(chem_mat)
println("--- Pearson correlation matrix (N, P, K, Ca, Mg, pH) ---")
show(stdout, "text/plain", round.(cor_pearson, digits=3))
println("\n")

cor_spearman = corspearman(chem_mat)
println("--- Spearman correlation matrix (N, P, K, Ca, Mg, pH) ---")
show(stdout, "text/plain", round.(cor_spearman, digits=3))
println("\n")

# Single-pair example with a test statistic and p-value
pear_np = CorrelationTest(varechem.N, varechem.P)
println("CorrelationTest(N, P) Pearson: ", pear_np, "\n")

# ---- 6. Chi-square test of independence: Shrub x Topo -----------------------
shrub_levels = unique(mite.Shrub)
topo_levels  = unique(mite.Topo)
tab = [count((mite.Shrub .== s) .& (mite.Topo .== t)) for s in shrub_levels, t in topo_levels]

println("--- Contingency table: Shrub x Topo ---")
println("Rows = ", shrub_levels, "  Cols = ", topo_levels)
show(stdout, "text/plain", tab)
println()

chi_res = ChisqTest(tab)
println("\n", chi_res, "\n")

# ---- 7. Figure: boxplot of WatrCont by Substrate -----------------------------
mkpath("figures")

p = boxplot(
    string.(mite.Substrate), mite.WatrCont,
    legend = false,
    xlabel = "",
    ylabel = "Water content (WatrCont, g/L substrate)",
    title = "Water content by substrate type\nLac Cromwell (Borcard & Legendre 1994)",
    xrotation = 60,
    fillcolor = "#8FBFDB",
    size = (1000, 700),
)
savefig(p, "figures/lecture_03_watercontent_by_substrate.png")

println("Saved figures/lecture_03_watercontent_by_substrate.png")

# =============================================================================
# --- EXERCISES ---
# TODO 1: Run a two-sample t-test comparing SubsDens (substrate density)
#         between two Substrate groups of your choice (e.g. "Litter" vs
#         "Barepeat"). Report the t-statistic and p-value.
# TODO 2: Run a one-way ANOVA of SubsDens ~ Substrate across all Substrate
#         levels using OneWayANOVATest(). Follow up with pairwise t-tests
#         and a Holm correction -- which pairs differ significantly?
# TODO 3: Compute the Pearson and Spearman correlation between Humdepth and
#         pH in varechem.csv. Do the two correlation coefficients agree?
# TODO 4: Build a contingency table of Shrub x Substrate from mite_env.csv
#         and run a ChisqTest(). Interpret the result.
# =============================================================================
