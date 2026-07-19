## ============================================================
## Lecture 2 -- Data Structures and Management
## Ecological Modelling with R, Python, and Julia
##
## Datasets:
##   data/mite_species.csv + data/mite_env.csv   (Borcard & Legendre 1994)
##   data/dune_species.csv + data/dune_env.csv   (Jongman, ter Braak & van Tongeren)
##
## Assumes working directory = repository root, i.e. run as:
##   julia code/julia/lecture_02_data_management.jl
## ============================================================

using CSV
using DataFrames
using Statistics
using Plots

## ------------------------------------------------------------
## 1. Load data
## ------------------------------------------------------------

mite_species = CSV.read("data/mite_species.csv", DataFrame)
mite_env     = CSV.read("data/mite_env.csv", DataFrame)

dune_species = CSV.read("data/dune_species.csv", DataFrame)
dune_env     = CSV.read("data/dune_env.csv", DataFrame)

println("mite_species: ", nrow(mite_species), " sites x ", ncol(mite_species) - 1, " species")
println("mite_env    : ", nrow(mite_env), " rows x ", ncol(mite_env), " columns")

## ------------------------------------------------------------
## 2. Missing-data check
##    (Real field surveys are rarely fully complete -- always check,
##    even when you expect a clean textbook dataset like this one.)
## ------------------------------------------------------------

println("\n--- Missing data check ---")
n_missing(df) = sum(sum(ismissing.(eachcol(df)[i])) for i in 1:ncol(df))
println("NAs in mite_species: ", n_missing(mite_species))
println("NAs in mite_env    : ", n_missing(mite_env))
for col in names(mite_env)
    nmiss = count(ismissing, mite_env[!, col])
    nmiss > 0 && println("  ", col, ": ", nmiss, " missing")
end

## ------------------------------------------------------------
## 3. Join species matrix to environmental covariates (mite data)
## ------------------------------------------------------------

mite_joined = leftjoin(mite_species, mite_env, on = :site)
sort!(mite_joined, :site)

## ------------------------------------------------------------
## 4. Derived variables: total abundance and species richness
## ------------------------------------------------------------

sp_cols = filter(c -> c != "site", names(mite_species))

mite_joined.total_abundance = [sum(row) for row in eachrow(mite_joined[:, sp_cols])]
mite_joined.richness        = [count(>(0), row) for row in eachrow(mite_joined[:, sp_cols])]

println("\n--- Derived variables (head) ---")
show(first(mite_joined[:, [:site, :Substrate, :total_abundance, :richness]], 6), allrows=true, allcols=true)
println()

## ------------------------------------------------------------
## 5. Group + summarize: mean richness/abundance by Substrate
## ------------------------------------------------------------

richness_by_substrate = combine(
    groupby(mite_joined, :Substrate),
    :richness => mean => :mean_richness,
    :total_abundance => mean => :mean_abundance,
)
sort!(richness_by_substrate, :mean_richness, rev = true)

println("\n--- Mean richness & abundance by Substrate ---")
show(richness_by_substrate, allrows=true, allcols=true)
println()

## ------------------------------------------------------------
## 6. Wide-to-long reshape (dune species matrix)
## ------------------------------------------------------------

dune_long = stack(dune_species, Not(:site), variable_name = :species, value_name = :count)
sort!(dune_long, [:site, :species])

println("\n--- Dune species matrix reshaped wide -> long (head) ---")
show(first(dune_long, 10), allrows=true, allcols=true)
println()

## ------------------------------------------------------------
## 7. Dune worked example: richness, join to dune_env, group by Management
## ------------------------------------------------------------

dune_sp_cols = filter(c -> c != "site", names(dune_species))
dune_species.richness = [count(>(0), row) for row in eachrow(dune_species[:, dune_sp_cols])]

dune_joined = leftjoin(dune_species[:, [:site, :richness]], dune_env, on = :site)

richness_by_mgmt = combine(
    groupby(dune_joined, :Management),
    :richness => mean => :mean_richness,
)

println("\n--- Dune: mean richness by Management ---")
show(richness_by_mgmt, allrows=true, allcols=true)
println()

## ------------------------------------------------------------
## 8. Figure: mean richness by substrate (mite data)
## ------------------------------------------------------------

isdir("figures") || mkpath("figures")

bar(
    richness_by_substrate.Substrate,
    richness_by_substrate.mean_richness,
    legend = false,
    color = "#0e7c86",
    xlabel = "Substrate",
    ylabel = "Mean species richness",
    title = "Mean Oribatid Mite Species Richness by Substrate",
    xrotation = 90,
    bottom_margin = 20Plots.px,
    size = (1000, 700),
)
savefig("figures/lecture_02_richness_by_substrate.png")

println("\nFigure saved to figures/lecture_02_richness_by_substrate.png")
println("\nDone.")

## --- EXERCISES ---
## 1. TODO: Compute species richness per site in the dune dataset and merge
##    with dune_env. Find the mean richness by Management type.
##    (Partially demonstrated above -- extend to explore Use and Manure too.)
##
## 2. TODO: Load varespec.csv and varechem.csv. Join them by site (row order/id),
##    compute total abundance per site, and report the correlation between
##    total abundance and soil pH.
##
## 3. TODO: Reshape mite_species.csv from wide to long format. Then compute,
##    for each species, the number of sites in which it is present (nonzero).
##    Which species is the most widespread?
##
## 4. TODO: In the mite_env data, introduce artificial missing values into
##    WatrCont for 5 random sites (set to missing). Compare the mean of
##    WatrCont computed with and without skipmissing(), and discuss when
##    it would be appropriate to drop vs. impute those rows.
