"""
Lecture 2 -- Data Structures and Management
Ecological Modelling with R, Python, and Julia

Datasets:
    data/mite_species.csv + data/mite_env.csv   (Borcard & Legendre 1994)
    data/dune_species.csv + data/dune_env.csv   (Jongman, ter Braak & van Tongeren)

Assumes working directory = repository root, i.e. run as:
    python3 code/python/lecture_02_data_management.py
"""

import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ------------------------------------------------------------
# 1. Load data
# ------------------------------------------------------------

# NOTE: mite_env$Shrub has a legitimate category level literally called
# "None" (no shrub cover). pandas' default NA sniffer treats the bare
# string "None" as missing data, which would silently corrupt this column.
# keep_default_na=False (with an explicit, narrow na_values list) avoids
# that trap -- a good habit whenever a categorical column could plausibly
# contain the words "None"/"NA"/"NULL" as real values.
NA_VALUES = ["", "NA", "N/A", "NaN"]

mite_species = pd.read_csv("data/mite_species.csv", keep_default_na=False, na_values=NA_VALUES)
mite_env = pd.read_csv("data/mite_env.csv", keep_default_na=False, na_values=NA_VALUES)

dune_species = pd.read_csv("data/dune_species.csv", keep_default_na=False, na_values=NA_VALUES)
dune_env = pd.read_csv("data/dune_env.csv", keep_default_na=False, na_values=NA_VALUES)

print(f"mite_species: {mite_species.shape[0]} sites x {mite_species.shape[1] - 1} species")
print(f"mite_env    : {mite_env.shape[0]} rows x {mite_env.shape[1]} columns")

# ------------------------------------------------------------
# 2. Missing-data check
#    (Real field surveys are rarely fully complete -- always check,
#    even when you expect a clean textbook dataset like this one.)
# ------------------------------------------------------------

print("\n--- Missing data check ---")
print("NAs in mite_species:", int(mite_species.isna().sum().sum()))
print("NAs in mite_env    :", int(mite_env.isna().sum().sum()))
na_by_col = mite_env.isna().sum()
print(na_by_col[na_by_col > 0])  # empty here: dataset is complete

# ------------------------------------------------------------
# 3. Join species matrix to environmental covariates (mite data)
# ------------------------------------------------------------

mite_joined = mite_species.merge(mite_env, on="site", how="left")

# ------------------------------------------------------------
# 4. Derived variables: total abundance and species richness
# ------------------------------------------------------------

sp_cols = [c for c in mite_species.columns if c != "site"]

mite_joined["total_abundance"] = mite_joined[sp_cols].sum(axis=1)
mite_joined["richness"] = (mite_joined[sp_cols] > 0).sum(axis=1)

print("\n--- Derived variables (head) ---")
print(mite_joined[["site", "Substrate", "total_abundance", "richness"]].head())

# ------------------------------------------------------------
# 5. Group + summarize: mean richness/abundance by Substrate
# ------------------------------------------------------------

richness_by_substrate = (
    mite_joined.groupby("Substrate")[["richness", "total_abundance"]]
    .mean()
    .rename(columns={"richness": "mean_richness", "total_abundance": "mean_abundance"})
    .sort_values("mean_richness", ascending=False)
    .reset_index()
)

print("\n--- Mean richness & abundance by Substrate ---")
print(richness_by_substrate)

# ------------------------------------------------------------
# 6. Wide-to-long reshape (dune species matrix)
# ------------------------------------------------------------

dune_long = dune_species.melt(id_vars="site", var_name="species", value_name="count")
dune_long = dune_long.sort_values(["site", "species"]).reset_index(drop=True)

print("\n--- Dune species matrix reshaped wide -> long (head) ---")
print(dune_long.head(10))

# ------------------------------------------------------------
# 7. Dune worked example: richness, join to dune_env, group by Management
# ------------------------------------------------------------

dune_sp_cols = [c for c in dune_species.columns if c != "site"]
dune_species["richness"] = (dune_species[dune_sp_cols] > 0).sum(axis=1)

dune_joined = dune_species[["site", "richness"]].merge(dune_env, on="site", how="left")

richness_by_mgmt = (
    dune_joined.groupby("Management")["richness"]
    .mean()
    .rename("mean_richness")
    .reset_index()
)

print("\n--- Dune: mean richness by Management ---")
print(richness_by_mgmt)

# ------------------------------------------------------------
# 8. Figure: mean richness by substrate (mite data)
# ------------------------------------------------------------

os.makedirs("figures", exist_ok=True)

fig, ax = plt.subplots(figsize=(10, 7))
ax.bar(
    richness_by_substrate["Substrate"],
    richness_by_substrate["mean_richness"],
    color="#0e7c86",
)
ax.set_ylabel("Mean species richness")
ax.set_title("Mean Oribatid Mite Species Richness by Substrate")
plt.setp(ax.get_xticklabels(), rotation=90)
fig.tight_layout()
fig.savefig("figures/lecture_02_richness_by_substrate.png", dpi=120)
plt.close(fig)

print("\nFigure saved to figures/lecture_02_richness_by_substrate.png")
print("\nDone.")

# --- EXERCISES ---
# 1. TODO: Compute species richness per site in the dune dataset and merge
#    with dune_env. Find the mean richness by Management type.
#    (Partially demonstrated above -- extend to explore Use and Manure too.)
#
# 2. TODO: Load varespec.csv and varechem.csv. Join them by site (row order/id),
#    compute total abundance per site, and report the correlation between
#    total abundance and soil pH.
#
# 3. TODO: Reshape mite_species.csv from wide to long format. Then compute,
#    for each species, the number of sites in which it is present (nonzero).
#    Which species is the most widespread?
#
# 4. TODO: In the mite_env data, introduce artificial missing values into
#    WatrCont for 5 random sites (set to NaN). Compare the mean of WatrCont
#    computed with and without dropna(), and discuss when it would be
#    appropriate to drop vs. impute those rows.
