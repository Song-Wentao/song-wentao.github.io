# ============================================================
# Lecture 5 -- Linear Models
# Ecological Modelling with R, Python, and Julia
#
# Dataset:
#   data/mite_species.csv + data/mite_env.csv  (Borcard & Legendre 1994,
#                                                Ecology -- oribatid mite
#                                                community, Lac Cromwell
#                                                peat moss, 70 sites)
#
# Response:
#   richness = number of species with nonzero abundance at each site
#
# Models:
#   1. Simple LM:   richness ~ WatrCont
#   2. Multiple LM: richness ~ WatrCont + SubsDens + Substrate
#   3. Four classic diagnostic plots for the multiple LM
#
# Assumes working directory = repository root, i.e. run as:
#   python3 code/python/lecture_05_linear_models.py
# ============================================================

import os
import warnings

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import statsmodels.api as sm
import statsmodels.formula.api as smf
from statsmodels.graphics.gofplots import ProbPlot

os.makedirs("figures", exist_ok=True)

## ------------------------------------------------------------
## 1. Load and join data, compute richness
## ------------------------------------------------------------

species = pd.read_csv("data/mite_species.csv")
env = pd.read_csv("data/mite_env.csv")

sp_cols = [c for c in species.columns if c != "site"]
richness = (species[sp_cols] > 0).sum(axis=1)
rich_df = pd.DataFrame({"site": species["site"], "richness": richness})

dat = env.merge(rich_df, on="site")
dat["Substrate"] = dat["Substrate"].astype("category")

print("=== Lecture 5: Linear Models (Python) ===\n")
print("n sites:", len(dat))
print("richness range:", dat["richness"].min(), "-", dat["richness"].max())
print()

## ------------------------------------------------------------
## 2. Simple linear regression: richness ~ WatrCont
## ------------------------------------------------------------

fit_simple = smf.ols("richness ~ WatrCont", data=dat).fit()

print("--- Simple LM: richness ~ WatrCont ---")
print(fit_simple.summary())
print()

## ------------------------------------------------------------
## 3. Multiple linear regression: richness ~ WatrCont + SubsDens + Substrate
## ------------------------------------------------------------

fit_multi = smf.ols("richness ~ WatrCont + SubsDens + C(Substrate)", data=dat).fit()

print("--- Multiple LM: richness ~ WatrCont + SubsDens + Substrate ---")
print(fit_multi.summary())
print()

print("--- ANOVA table for the multiple LM (Type II) ---")
anova_tbl = sm.stats.anova_lm(fit_multi, typ=2)
print(anova_tbl)
print()

print("R-squared comparison:")
print(f"  simple model:   R2 = {fit_simple.rsquared:.3f}, "
      f"adj R2 = {fit_simple.rsquared_adj:.3f}")
print(f"  multiple model: R2 = {fit_multi.rsquared:.3f}, "
      f"adj R2 = {fit_multi.rsquared_adj:.3f}")
print()

## ------------------------------------------------------------
## 4. Diagnostic plots for the multiple LM
##    residuals vs fitted | Q-Q | scale-location | residuals vs leverage
## ------------------------------------------------------------

fitted = fit_multi.fittedvalues
resid = fit_multi.resid
influence = fit_multi.get_influence()
# One site has leverage very close to 1 (a near-perfect fit at that point),
# which makes the studentized residual denominator ~0 there -- same edge
# case R's plot.lm() flags with "not plotting observations with leverage
# one". Suppress the resulting sqrt(negative-~0) RuntimeWarning; the
# offending point simply won't plot on the Q-Q / scale-location panels.
with warnings.catch_warnings():
    warnings.simplefilter("ignore", RuntimeWarning)
    student_resid = influence.resid_studentized_internal
sqrt_abs_student_resid = np.sqrt(np.abs(student_resid))
leverage = influence.hat_matrix_diag
cooks_d = influence.cooks_distance[0]

fig, axes = plt.subplots(2, 2, figsize=(9, 9), dpi=125)

# (1) Residuals vs Fitted
ax = axes[0, 0]
ax.scatter(fitted, resid, edgecolor="k", facecolor="none", alpha=0.8)
ax.axhline(0, color="grey", linestyle="--", linewidth=1)
lowess = sm.nonparametric.lowess(resid, fitted, frac=0.6)
ax.plot(lowess[:, 0], lowess[:, 1], color="red", linewidth=1.2)
ax.set_xlabel("Fitted values")
ax.set_ylabel("Residuals")
ax.set_title("Residuals vs Fitted")

# (2) Normal Q-Q
ax = axes[0, 1]
qq = ProbPlot(student_resid)
qq.qqplot(line="45", ax=ax, markerfacecolor="black", markeredgecolor="black", alpha=0.8)
ax.set_title("Normal Q-Q")

# (3) Scale-Location
ax = axes[1, 0]
ax.scatter(fitted, sqrt_abs_student_resid, edgecolor="k", facecolor="none", alpha=0.8)
lowess2 = sm.nonparametric.lowess(sqrt_abs_student_resid, fitted, frac=0.6)
ax.plot(lowess2[:, 0], lowess2[:, 1], color="red", linewidth=1.2)
ax.set_xlabel("Fitted values")
ax.set_ylabel(r"$\sqrt{|Studentized\ residuals|}$")
ax.set_title("Scale-Location")

# (4) Residuals vs Leverage (with Cook's distance contours)
ax = axes[1, 1]
ax.scatter(leverage, student_resid, edgecolor="k", facecolor="none", alpha=0.8)
ax.axhline(0, color="grey", linestyle="--", linewidth=1)
for i in np.argsort(cooks_d)[-3:]:
    ax.annotate(str(i), (leverage[i], student_resid[i]))
ax.set_xlabel("Leverage")
ax.set_ylabel("Studentized residuals")
ax.set_title("Residuals vs Leverage")

fig.suptitle("Diagnostics: richness ~ WatrCont + SubsDens + Substrate", y=1.0)
fig.tight_layout()
fig.savefig("figures/lecture_05_diagnostics.png")
plt.close(fig)

print("Saved figures/lecture_05_diagnostics.png")
print("\n=== Done ===")

# --- EXERCISES ---
# TODO 1: Fit richness ~ SubsDens alone. Compare its R2 (and adjusted R2) to
#         the richness ~ WatrCont simple model above. Which single predictor
#         explains more variation in richness?
# TODO 2: Fit richness ~ Substrate alone (Substrate as the only predictor).
#         Interpret the coefficients -- what do they represent relative to
#         the reference level? Use sm.stats.anova_lm() to test whether
#         Substrate explains a significant amount of variation.
# TODO 3: Add an interaction term: richness ~ WatrCont * C(Substrate). Does
#         the slope of richness on WatrCont differ meaningfully across
#         substrate types? Use sm.stats.anova_lm(fit_multi, fit_interaction)
#         to compare the two models.
# TODO 4: Fit richness ~ WatrCont using only sites with SubsDens > 60 (an
#         extreme subset) and inspect the four diagnostic plots. Which
#         assumption looks most violated, and what would you do about it?
