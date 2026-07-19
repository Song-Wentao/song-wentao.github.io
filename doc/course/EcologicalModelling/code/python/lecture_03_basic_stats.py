"""
Lecture 3: Basic Statistical Analysis (Python)
Ecological Modelling with R, Python, and Julia

Datasets:
    mite_env.csv  -- Borcard & Legendre (1994), Ecology 75(4), oribatid mites
    varechem.csv  -- Vare, Ohtonen & Oksanen (1995), J. Vegetation Science

Convention used all semester:
    - Run scripts with the working directory set to the repository root
      (i.e. the folder that contains data/, code/, figures/, exercises/).
    - Read inputs from   data/<file>.csv
    - Write figures to   figures/lecture_NN_<slug>.png
"""

import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy import stats
from statsmodels.stats.multicomp import pairwise_tukeyhsd
import statsmodels.api as sm
import statsmodels.formula.api as smf

print("=== Lecture 3: Basic Statistical Analysis (Python) ===\n")

# NOTE: keep_default_na=False is required here because the Shrub column
# contains the literal category label "None" (no shrub cover), which pandas
# would otherwise silently parse as a missing value (NaN).
mite = pd.read_csv("data/mite_env.csv", keep_default_na=False)
mite["Substrate"] = mite["Substrate"].astype("category")
mite["Shrub"] = mite["Shrub"].astype("category")

# ---- 1. Descriptive statistics: mean / sd / CV ------------------------------
def cv(x):
    return x.std(ddof=1) / x.mean() * 100

print("--- Descriptive statistics (mite_env.csv) ---")
for v in ["WatrCont", "SubsDens"]:
    x = mite[v]
    print(f"{v:<10}: mean = {x.mean():8.2f}  median = {x.median():8.2f}  "
          f"sd = {x.std(ddof=1):8.2f}  CV = {cv(x):6.1f}%")
print()
# Ecological note: counts, cover, and biomass are frequently right-skewed
# (many small values, a few large ones) -> mean > median, CV often > 50-100%.
# Always inspect the distribution (histogram/boxplot) before assuming normality.

# ---- 2. Two-sample t-test: WatrCont between two Substrate groups ------------
sub_a = mite.loc[mite["Substrate"] == "Sphagn1", "WatrCont"]
sub_b = mite.loc[mite["Substrate"] == "Litter", "WatrCont"]

t_stat, p_val = stats.ttest_ind(sub_a, sub_b, equal_var=False)  # Welch's t-test
print("--- Two-sample t-test: WatrCont, Sphagn1 vs Litter ---")
print(f"t = {t_stat:.3f}, p-value = {p_val:.4f}")
print(f"Mean Sphagn1 = {sub_a.mean():.2f}, Mean Litter = {sub_b.mean():.2f}\n")

# ---- 3. One-way ANOVA: WatrCont ~ Substrate (all levels) --------------------
groups = [g["WatrCont"].values for _, g in mite.groupby("Substrate", observed=True)]
f_stat, p_anova = stats.f_oneway(*groups)

print("--- One-way ANOVA: WatrCont ~ Substrate ---")
print(f"F = {f_stat:.3f}, p-value = {p_anova:.5f}")

# Cross-check with statsmodels OLS ANOVA table (also gives eta-squared/R^2)
ols_fit = smf.ols("WatrCont ~ C(Substrate)", data=mite).fit()
anova_table = sm.stats.anova_lm(ols_fit, typ=2)
print("\nstatsmodels ANOVA table:")
print(anova_table)

ss_sub = anova_table.loc["C(Substrate)", "sum_sq"]
ss_resid = anova_table.loc["Residual", "sum_sq"]
eta_sq = ss_sub / (ss_sub + ss_resid)
r_sq = ols_fit.rsquared
print(f"\neta-squared = {eta_sq:.3f}, R^2 (equivalent for one-way ANOVA) = {r_sq:.3f}\n")

# ---- 4. Post-hoc: Tukey HSD --------------------------------------------------
print("--- Tukey HSD post-hoc comparisons ---")
tukey_res = pairwise_tukeyhsd(endog=mite["WatrCont"], groups=mite["Substrate"], alpha=0.05)
print(tukey_res)
print()

# ---- 5. Correlation matrix: soil chemistry (varechem.csv) -------------------
varechem = pd.read_csv("data/varechem.csv")
chem_vars = ["N", "P", "K", "Ca", "Mg", "pH"]
chem_sub = varechem[chem_vars]

cor_pearson = chem_sub.corr(method="pearson")
print("--- Pearson correlation matrix (N, P, K, Ca, Mg, pH) ---")
print(cor_pearson.round(3))
print()

cor_spearman = chem_sub.corr(method="spearman")
print("--- Spearman correlation matrix (N, P, K, Ca, Mg, pH) ---")
print(cor_spearman.round(3))
print()

# Single-pair example with a test statistic and p-value
r_np, p_np = stats.pearsonr(varechem["N"], varechem["P"])
print(f"pearsonr(N, P): r = {r_np:.3f}, p-value = {p_np:.4f}\n")

# ---- 6. Chi-square test of independence: Shrub x Topo -----------------------
shrub_topo_tab = pd.crosstab(mite["Shrub"], mite["Topo"])
print("--- Contingency table: Shrub x Topo ---")
print(shrub_topo_tab)

chi2, p_chi, dof, expected = stats.chi2_contingency(shrub_topo_tab)
print(f"\nChi-square = {chi2:.3f}, df = {dof}, p-value = {p_chi:.4f}\n")

# ---- 7. Figure: boxplot of WatrCont by Substrate -----------------------------
os.makedirs("figures", exist_ok=True)

order = sorted(mite["Substrate"].cat.categories)
data_by_group = [mite.loc[mite["Substrate"] == lvl, "WatrCont"].values for lvl in order]

fig, ax = plt.subplots(figsize=(9, 6.5))
ax.boxplot(data_by_group, tick_labels=order, patch_artist=True,
           boxprops=dict(facecolor="#8FBFDB"))
ax.set_xlabel("")
ax.set_ylabel("Water content (WatrCont, g/L substrate)")
ax.set_title("Water content by substrate type\nLac Cromwell (Borcard & Legendre 1994)")
plt.setp(ax.get_xticklabels(), rotation=60, ha="right")
fig.tight_layout()
fig.savefig("figures/lecture_03_watercontent_by_substrate.png", dpi=140)
plt.close(fig)

print("Saved figures/lecture_03_watercontent_by_substrate.png")

# =============================================================================
# --- EXERCISES ---
# TODO 1: Run a two-sample t-test comparing SubsDens (substrate density)
#         between two Substrate groups of your choice (e.g. "Litter" vs
#         "Barepeat"). Report t and p-value.
# TODO 2: Run a one-way ANOVA of SubsDens ~ Substrate across all Substrate
#         levels. Follow up with a Tukey HSD test -- which pairs differ
#         significantly?
# TODO 3: Compute the Pearson and Spearman correlation between Humdepth and
#         pH in varechem.csv. Do the two correlation coefficients agree?
# TODO 4: Build a contingency table of Shrub x Substrate from mite_env.csv
#         and run a chi-square test of independence. Interpret the result.
# =============================================================================
