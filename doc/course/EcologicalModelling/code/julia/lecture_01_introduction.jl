#=
Lecture 1: Introduction -- "Hello Data" demonstration (Julia)
Ecological Modelling with R, Python, and Julia

Dataset: Oribatid mite community, Lac Cromwell peat blanket
         Borcard & Legendre (1994), Ecology 75(4)

Convention used all semester:
  - Run scripts with the working directory set to the repository root
    (i.e. the folder that contains data/, code/, figures/, exercises/).
  - Read inputs from   data/<file>.csv
  - Write figures to   figures/lecture_NN_<slug>.png

Packages (see code/julia/Project.toml / instructions in Lecture 1 slides):
  CSV, DataFrames, Statistics, Plots
=#

using CSV
using DataFrames
using Statistics
using Plots

# ---- 1. Load data ------------------------------------------------------------
species = CSV.read("data/mite_species.csv", DataFrame)
env     = CSV.read("data/mite_env.csv",     DataFrame)

# ---- 2. Compute total abundance per site -------------------------------------
# All columns except :site are species counts; sum across columns (row-wise).
species_cols = setdiff(names(species), ["site"])
total_abund  = [sum(row) for row in eachrow(species[:, species_cols])]

abundance_df = DataFrame(site = species.site, total_abund = total_abund)

# ---- 3. Join to environmental data on site -----------------------------------
mite = innerjoin(abundance_df, env, on = :site)

# ---- 4. Summary statistics ----------------------------------------------------
println("=== Lecture 1: Hello Data (Julia) ===")
println("Sites joined: ", nrow(mite))

watr_mean = mean(mite.WatrCont)
watr_sd   = std(mite.WatrCont)
println("Water content (WatrCont): mean = ", round(watr_mean, digits = 2),
        ", sd = ", round(watr_sd, digits = 2))

abund_mean = mean(mite.total_abund)
abund_sd   = std(mite.total_abund)
println("Total abundance: mean = ", round(abund_mean, digits = 2),
        ", sd = ", round(abund_sd, digits = 2))

r_val = cor(mite.total_abund, mite.WatrCont)
println("Correlation(total abundance, WatrCont) = ", round(r_val, digits = 3))

# ---- 5. Plot: total abundance vs. water content -------------------------------
mkpath("figures")

p = scatter(
    mite.WatrCont, mite.total_abund,
    xlabel = "Water content (WatrCont, g/L substrate)",
    ylabel = "Total mite abundance (individuals per core)",
    title  = "Mite abundance vs. substrate water content\nLac Cromwell (Borcard & Legendre 1994)",
    color  = :steelblue,
    markerstrokecolor = :white,
    legend = false,
)

# Overlay a simple linear trend line (basic least-squares via \, not a
# modelling package -- regression proper is covered starting Lecture 5).
X = hcat(ones(length(mite.WatrCont)), mite.WatrCont)
beta = X \ mite.total_abund
x_line = range(minimum(mite.WatrCont), maximum(mite.WatrCont), length = 100)
plot!(p, x_line, beta[1] .+ beta[2] .* x_line, color = :firebrick, linewidth = 2)

savefig(p, "figures/lecture_01_abundance_vs_watercontent.png")

println("Saved figures/lecture_01_abundance_vs_watercontent.png")

# =============================================================================
# --- EXERCISES ---
# TODO 1: Repeat this analysis using SubsDens (substrate density) instead of
#         WatrCont. Is the correlation with total abundance stronger or weaker?
# TODO 2: Compute total abundance separately for each level of Shrub
#         (None/Few/Many) and compare the group means.
# TODO 3: Identify the single most abundant species overall (largest column
#         sum in mite_species.csv) and plot its abundance against WatrCont.
# =============================================================================
