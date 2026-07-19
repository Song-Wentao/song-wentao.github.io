"""
Lecture 6: Generalized Linear Models (Python)
Ecological Modelling with R, Python, and Julia

Dataset:
  data/grouseticks.csv (Elston, Moss, Boulinier, Arrowsmith & Lambin 2001,
                         Parasitology 122: 563-569 -- "Analysis of
                         aggregation, a worked example: numbers of ticks
                         on red grouse chicks.")
  One of the most widely taught real GLMM datasets in ecology -- used as
  the worked example in Zuur et al. (2009) and Bolker et al. (2009, TREE).

Columns:
  INDEX    chick ID
  TICKS    tick count per chick (response)
  BROOD    factor, 118 levels (chick's brood of origin)
  HEIGHT   altitude in metres
  YEAR     factor, 95/96/97 -- must be cast to categorical/string, pandas
           would otherwise read it as an integer
  LOCATION factor, 63 levels
  cHEIGHT  HEIGHT, mean-centered

Methods:
  1. Poisson GLM:      TICKS ~ YEAR + cHEIGHT, log link
     -- statsmodels.formula.api.glm(family=sm.families.Poisson())
  2. Overdispersion check: residual deviance / residual df
  3. Negative-binomial GLM (fixes overdispersion)
     -- statsmodels.formula.api.glm(family=sm.families.NegativeBinomial())
  4. Binomial GLM (toy presence/absence recoding)
     -- statsmodels.formula.api.glm(family=sm.families.Binomial())

Convention used all semester:
  - Run scripts with the working directory set to the repository root.
  - Read inputs from   data/<file>.csv
  - Write figures to   figures/lecture_NN_<slug>.png
"""

import os

import matplotlib
matplotlib.use("Agg")  # headless-safe backend
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf

os.makedirs("figures", exist_ok=True)

print("=== Lecture 6: Generalized Linear Models (Python) ===\n")

# ---- Load data -----------------------------------------------------------
# YEAR/BROOD/LOCATION load as integers by default in pandas; cast YEAR to a
# categorical/string type explicitly so it is treated as a factor, matching
# R's behavior (glm(..., data) with YEAR as factor() gives level contrasts,
# not a numeric slope).
ticks = pd.read_csv("data/grouseticks.csv")
ticks["YEAR"] = ticks["YEAR"].astype(str).astype("category")
ticks["BROOD"] = ticks["BROOD"].astype(str).astype("category")
ticks["LOCATION"] = ticks["LOCATION"].astype(str).astype("category")

# ---- 0. Why a linear model fails here -------------------------------------
print("--- TICKS distribution ---")
print(ticks["TICKS"].describe())
print("Proportion of chicks with zero ticks:",
      round((ticks["TICKS"] == 0).mean(), 3))
print("Variance / mean of TICKS:",
      round(ticks["TICKS"].var() / ticks["TICKS"].mean(), 1),
      "(>> 1 already hints at overdispersion relative to Poisson)\n")

# ---- 1. Poisson GLM: TICKS ~ YEAR + cHEIGHT, log link ----------------------
pois_fit = smf.glm(
    formula="TICKS ~ YEAR + cHEIGHT",
    data=ticks,
    family=sm.families.Poisson(link=sm.families.links.Log()),
).fit()
print("--- Poisson GLM: TICKS ~ YEAR + cHEIGHT ---")
print(pois_fit.summary())

print("\nCoefficients on the log-link scale:")
print(pois_fit.params.round(4))
print("\nExponentiated coefficients (rate ratios on the response scale):")
print(np.exp(pois_fit.params).round(4))

# ---- 2. Overdispersion check ----------------------------------------------
# Ratio >> 1 signals overdispersion (variance > mean, more than Poisson
# allows).
disp_ratio = pois_fit.deviance / pois_fit.df_resid
print("\n--- Overdispersion check ---")
print(f"Residual deviance: {pois_fit.deviance:.1f} on {pois_fit.df_resid:.0f} df")
print(f"Dispersion ratio (deviance / df): {disp_ratio:.2f}")
if disp_ratio > 1.5:
    print("--> Ratio is well above 1: the Poisson model is overdispersed.")
    print("    This matches the paper's own point: tick counts are strongly")
    print("    aggregated (clumped), not Poisson-distributed.\n")
else:
    print("--> Ratio is close to 1: no strong evidence of overdispersion.\n")

# ---- 3. Negative-binomial GLM ----------------------------------------------
# Fixes overdispersion by adding a dispersion parameter (alpha) that lets
# variance exceed the mean. statsmodels' GLM NegativeBinomial family needs a
# fixed alpha; we estimate it by profiling over a small grid using the
# log-likelihood (a simple stand-in for MASS::glm.nb's internal ML search).
def fit_nb_glm(formula, data, alpha_grid=None):
    if alpha_grid is None:
        alpha_grid = np.linspace(0.05, 3.0, 60)
    best_fit, best_alpha, best_ll = None, None, -np.inf
    for a in alpha_grid:
        fit_a = smf.glm(
            formula=formula, data=data,
            family=sm.families.NegativeBinomial(alpha=a),
        ).fit()
        if fit_a.llf > best_ll:
            best_ll, best_alpha, best_fit = fit_a.llf, a, fit_a
    return best_fit, best_alpha


nb_fit, nb_alpha = fit_nb_glm("TICKS ~ YEAR + cHEIGHT", ticks)
print("--- Negative-binomial GLM: TICKS ~ YEAR + cHEIGHT ---")
print(nb_fit.summary())
print(f"\nProfiled alpha (dispersion parameter, 1/theta): {nb_alpha:.3f}")

print("\n--- AIC comparison: Poisson vs. Negative-Binomial ---")
print(f"Poisson AIC:            {pois_fit.aic:.1f}")
print(f"Negative-Binomial AIC:  {nb_fit.aic:.1f}")
print(f"Difference (Poisson - NB): {pois_fit.aic - nb_fit.aic:.1f} "
      "(large positive value favors the negative-binomial model)\n")

# ---- 4. Binomial GLM (logistic regression) ---------------------------------
# Toy example: recode TICKS as presence/absence and model with cHEIGHT.
ticks["present"] = (ticks["TICKS"] > 0).astype(int)
print("--- Binomial GLM: present (TICKS > 0) ~ cHEIGHT ---")
bin_fit = smf.glm(
    formula="present ~ cHEIGHT",
    data=ticks,
    family=sm.families.Binomial(link=sm.families.links.Logit()),
).fit()
print(bin_fit.summary())

print("\nOdds ratio for cHEIGHT (exp(coef)):",
      round(np.exp(bin_fit.params["cHEIGHT"]), 4))

# Predicted probability of tick presence at a couple of cHEIGHT values
new_h = pd.DataFrame({"cHEIGHT": [-50, 0, 50]})
pred_p = bin_fit.predict(new_h)
print("\nPredicted P(present) at cHEIGHT = -50, 0, 50:")
for h, p in zip(new_h["cHEIGHT"], pred_p):
    print(f"  cHEIGHT={h:>4}: P(present) = {p:.3f}")

# ---- 5. Figure: TICKS by YEAR ----------------------------------------------
fig, ax = plt.subplots(figsize=(7.5, 5.4))
years = sorted(ticks["YEAR"].cat.categories)
rng = np.random.default_rng(42)
for i, yr in enumerate(years):
    yvals = np.log1p(ticks.loc[ticks["YEAR"] == yr, "TICKS"])
    xj = rng.normal(loc=i, scale=0.06, size=len(yvals))
    ax.scatter(xj, yvals, alpha=0.35, color="steelblue", s=18)
ax.boxplot(
    [np.log1p(ticks.loc[ticks["YEAR"] == yr, "TICKS"]) for yr in years],
    positions=range(len(years)),
    widths=0.3,
    showfliers=False,
)
ax.set_xticks(range(len(years)))
ax.set_xticklabels(years)
ax.set_xlabel("Year")
ax.set_ylabel("log1p(TICKS)")
ax.set_title("Tick counts per chick by year (log1p scale)")
fig.tight_layout()
fig.savefig("figures/lecture_06_tick_counts_by_year.png", dpi=150)
plt.close(fig)
print("\nSaved figures/lecture_06_tick_counts_by_year.png")

# --- EXERCISES ---
# TODO 1: Fit a Poisson GLM using HEIGHT instead of cHEIGHT and compare the
#         coefficient estimates and intercept interpretation to the cHEIGHT
#         model fit above.
# TODO 2: Fit the negative-binomial GLM (already done above as nb_fit) and
#         compare its AIC to the Poisson model's AIC; report which model
#         the data prefer and why.
# TODO 3: Fit a binomial GLM for tick presence/absence ~ cHEIGHT (already
#         done above as bin_fit); report the odds ratio for cHEIGHT and
#         interpret its sign and magnitude.
# TODO 4: See exercises/lecture_06_exercises.md for the full exercise set.
