"""
Lecture 1: Introduction -- "Hello Data" demonstration (Python)
Ecological Modelling with R, Python, and Julia

Dataset: Oribatid mite community, Lac Cromwell peat blanket
         Borcard & Legendre (1994), Ecology 75(4)

Convention used all semester:
  - Run scripts with the working directory set to the repository root
    (i.e. the folder that contains data/, code/, figures/, exercises/).
  - Read inputs from   data/<file>.csv
  - Write figures to   figures/lecture_NN_<slug>.png
"""

import os

import matplotlib
matplotlib.use("Agg")  # headless-safe backend for saving figures without a display
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# ---- 1. Load data ------------------------------------------------------------
species = pd.read_csv("data/mite_species.csv")
env = pd.read_csv("data/mite_env.csv")

# ---- 2. Compute total abundance per site -------------------------------------
# All columns except "site" are species counts; sum across columns (axis=1).
species_cols = [c for c in species.columns if c != "site"]
abundance_df = pd.DataFrame({
    "site": species["site"],
    "total_abund": species[species_cols].sum(axis=1),
})

# ---- 3. Join to environmental data on site -----------------------------------
mite = abundance_df.merge(env, on="site", how="left")

# ---- 4. Summary statistics ----------------------------------------------------
print("=== Lecture 1: Hello Data (Python) ===")
print(f"Sites joined: {len(mite)}")

watr_mean = mite["WatrCont"].mean()
watr_sd = mite["WatrCont"].std()
print(f"Water content (WatrCont): mean = {watr_mean:.2f}, sd = {watr_sd:.2f}")

abund_mean = mite["total_abund"].mean()
abund_sd = mite["total_abund"].std()
print(f"Total abundance: mean = {abund_mean:.2f}, sd = {abund_sd:.2f}")

r_val = mite["total_abund"].corr(mite["WatrCont"])
print(f"Correlation(total abundance, WatrCont) = {r_val:.3f}")

# ---- 5. Plot: total abundance vs. water content -------------------------------
os.makedirs("figures", exist_ok=True)

fig, ax = plt.subplots(figsize=(7.2, 5.6), dpi=125)
ax.scatter(mite["WatrCont"], mite["total_abund"], color="#2E6E8E", edgecolor="white")

# Fit and overlay a simple linear trend (numpy, not a modelling library --
# regression proper is covered starting Lecture 5).
slope, intercept = np.polyfit(mite["WatrCont"], mite["total_abund"], 1)
x_line = np.linspace(mite["WatrCont"].min(), mite["WatrCont"].max(), 100)
ax.plot(x_line, slope * x_line + intercept, color="firebrick", linewidth=2)

ax.set_xlabel("Water content (WatrCont, g/L substrate)")
ax.set_ylabel("Total mite abundance (individuals per core)")
ax.set_title("Mite abundance vs. substrate water content\nLac Cromwell (Borcard & Legendre 1994)")
fig.tight_layout()
fig.savefig("figures/lecture_01_abundance_vs_watercontent.png")
plt.close(fig)

print("Saved figures/lecture_01_abundance_vs_watercontent.png")

# =============================================================================
# --- EXERCISES ---
# TODO 1: Repeat this analysis using SubsDens (substrate density) instead of
#         WatrCont. Is the correlation with total abundance stronger or weaker?
# TODO 2: Compute total abundance separately for each level of Shrub
#         (None/Few/Many) and compare the group means.
# TODO 3: Identify the single most abundant species overall (largest column
#         sum in mite_species.csv) and plot its abundance against WatrCont.
# =============================================================================
