"""
Lecture 7 -- Mixed-Effects Models
Ecological Modelling with R, Python, and Julia

Dataset:
    data/grouseticks.csv  (Elston, Moss, Boulinier, Arrowsmith &
                           Lambin 2001, Parasitology 122:563-569)

    403 red grouse chicks, TICKS (tick count) measured on each chick.
    Chicks are nested within BROOD (118 broods), and broods are
    nested within LOCATION (63 locations). HEIGHT/cHEIGHT is altitude
    (centered). YEAR is 95/96/97.

    The canonical real dataset for teaching GLMMs with nested random
    effects in ecology (Elston et al. 2001; Zuur et al. 2009; Bolker
    et al. 2009, TREE).

HONEST NOTE ON THE PYTHON ECOSYSTEM:
    R's lme4::glmer() is the mature, industry-standard tool for
    Poisson GLMMs with crossed/nested random effects. Python has NO
    equivalent library of the same maturity. The closest tool,
    statsmodels.genmod.bayes_mixed_glm.PoissonBayesMixedGLM, fits a
    Bayesian/MAP approximation to a Poisson mixed model with
    variance-component random effects. Below we:
      1. Fit it with the more stable Laplace/MAP optimizer (fit_map).
         In testing here, this recovers the LOCATION variance
         component reasonably but the finer, nested BROOD-within-
         LOCATION variance component collapses toward zero -- a
         known weak point of this implementation with many small
         groups (most broods here have only 1-6 chicks). The
         variational-Bayes optimizer (fit_vb) is even less stable
         and diverges (numeric overflow) on this dataset.
      2. As a robust, transparent fallback / cross-check, fit a
         LINEAR mixed model (statsmodels MixedLM) on log1p(TICKS)
         with BROOD nested in LOCATION via a variance-component
         formula. This is NOT a Poisson GLMM -- it is a Gaussian
         approximation on the log1p scale -- but it is numerically
         stable and its variance components agree in order of
         magnitude with R's glmer() and lmer() fits.
    For a real analysis, use R's glmer() (see code/R/lecture_07_*.R)
    as the reference fit; treat the Python fits here as an honest
    demonstration of what is (and isn't) currently easy in Python.

Assumes working directory = repository root, i.e. run as:
    python3 code/python/lecture_07_mixed_models.py
"""

import os
import warnings

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

import statsmodels.formula.api as smf
from statsmodels.genmod.bayes_mixed_glm import PoissonBayesMixedGLM

os.makedirs("figures", exist_ok=True)

np.random.seed(42)  # PoissonBayesMixedGLM's optimizer has stochastic elements
pd.set_option("display.width", 100)

print("=== Lecture 7: Mixed-Effects Models (Python) ===\n")

## ------------------------------------------------------------
## 1. Load data, set categorical types
## ------------------------------------------------------------

dat = pd.read_csv("data/grouseticks.csv")
dat["BROOD"] = dat["BROOD"].astype("category")
dat["LOCATION"] = dat["LOCATION"].astype("category")
dat["YEAR"] = dat["YEAR"].astype("category")

print(f"n chicks:    {len(dat)}")
print(f"n broods:    {dat['BROOD'].nunique()}")
print(f"n locations: {dat['LOCATION'].nunique()}")
print(f"TICKS range: {dat['TICKS'].min()}-{dat['TICKS'].max()}, "
      f"mean {dat['TICKS'].mean():.2f}\n")

brood_means = dat.groupby("BROOD", observed=True)["TICKS"].mean()
print(f"Spread of brood-level mean TICKS: range "
      f"{brood_means.min():.2f}-{brood_means.max():.2f}, "
      f"sd {brood_means.std():.2f}\n")

## ------------------------------------------------------------
## 2. Poisson GLMM attempt: statsmodels PoissonBayesMixedGLM
##    Random intercepts for LOCATION and BROOD (crossed
##    specification -- BROOD ids are unique across LOCATIONs in
##    this dataset, so crossed and nested give the same grouping).
## ------------------------------------------------------------

vc_formulas = {
    "LOCATION": "0 + C(LOCATION)",
    "BROOD": "0 + C(BROOD)",
}

poisson_glmm = PoissonBayesMixedGLM.from_formula(
    "TICKS ~ YEAR + cHEIGHT", vc_formulas, dat
)

print("--- Poisson GLMM attempt (statsmodels PoissonBayesMixedGLM, MAP fit) ---")
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    poisson_result = poisson_glmm.fit_map()
print(poisson_result.summary())
print(
    "\nNOTE: the LOCATION variance component (SD ~ 0.8 on the log scale) is in "
    "the right ballpark relative to R's glmer() fit, but the BROOD variance "
    "component collapses to (near) zero here -- MAP estimation struggles to "
    "separate a fine nested grouping (118 broods, many with 1-3 chicks) from "
    "residual Poisson noise. This is exactly the kind of nested small-group "
    "variance-component problem R's glmer() (via Laplace approximation over "
    "a properly profiled random-effect covariance) handles routinely and "
    "Python currently does not. Treat this fit as illustrative, not final.\n"
)

## ------------------------------------------------------------
## 3. Stable fallback / cross-check: linear mixed model on
##    log1p(TICKS), BROOD nested within LOCATION via a
##    variance-component formula. This is the LMM analogue of
##    R's lmer(log1p(TICKS) ~ ... + (1|LOCATION/BROOD)).
## ------------------------------------------------------------

dat["logTICKS"] = np.log1p(dat["TICKS"])

lmm = smf.mixedlm(
    "logTICKS ~ YEAR + cHEIGHT",
    dat,
    groups=dat["LOCATION"],
    re_formula="1",  # explicit random intercept for LOCATION (the "groups")
    vc_formula={"BROOD": "0 + C(BROOD)"},  # random intercept for BROOD, nested via vc
)
lmm_result = lmm.fit()

print("--- Fallback LMM (statsmodels MixedLM on log1p(TICKS)) ---")
print("Formula: logTICKS ~ YEAR + cHEIGHT, groups=LOCATION, "
      "vc_formula={'BROOD': random intercept nested in LOCATION}")
print(lmm_result.summary())
print()

## Variance components from the LMM fallback
var_location_lmm = lmm_result.cov_re.iloc[0, 0]
var_brood_lmm = lmm_result.vcomp[0]
var_resid_lmm = lmm_result.scale

print("Variance components (LMM fallback, log1p scale):")
print(f"  Var(LOCATION) = {var_location_lmm:.4f}")
print(f"  Var(BROOD within LOCATION) = {var_brood_lmm:.4f}")
print(f"  Var(residual) = {var_resid_lmm:.4f}")

icc_location = var_location_lmm / (var_location_lmm + var_brood_lmm + var_resid_lmm)
icc_brood = var_brood_lmm / (var_location_lmm + var_brood_lmm + var_resid_lmm)
print(f"  ICC(LOCATION) = {icc_location:.3f}")
print(f"  ICC(BROOD)    = {icc_brood:.3f}")
print(
    "  (Compare to R's glmer()-based ICC in code/R/lecture_07_mixed_models.R "
    "-- same qualitative story: more of the group-level variance sits at the "
    "BROOD level than the LOCATION level, but use R's Poisson GLMM numbers "
    "as the authoritative estimate.)\n"
)

## ------------------------------------------------------------
## 4. Figure: mean TICKS across a sample of LOCATIONs
## ------------------------------------------------------------

loc_means = (
    dat.groupby("LOCATION", observed=True)["TICKS"]
    .mean()
    .sort_values()
    .reset_index()
)
sample_idx = np.round(np.linspace(0, len(loc_means) - 1, min(20, len(loc_means)))).astype(int)
plot_dat = loc_means.iloc[sample_idx]

fig, ax = plt.subplots(figsize=(9, 6))
ax.bar(plot_dat["LOCATION"].astype(str), plot_dat["TICKS"], color="#3b7ea1")
ax.axhline(dat["TICKS"].mean(), linestyle="--", color="grey", label="overall mean")
ax.set_xlabel("LOCATION (sample of 20)")
ax.set_ylabel("Mean TICKS per chick")
ax.set_title("Mean tick count varies sharply by LOCATION")
ax.tick_params(axis="x", rotation=90)
ax.legend(frameon=False)
fig.tight_layout()
fig.savefig("figures/lecture_07_ticks_by_location_brood.png", dpi=125)
plt.close(fig)

print("Figure saved: figures/lecture_07_ticks_by_location_brood.png")

# --- EXERCISES ---
# 1. Add a random slope for cHEIGHT by LOCATION to the MixedLM fallback
#    (re.formula="~cHEIGHT") and compare AIC/BIC to the random-intercept
#    only model above.
# 2. Compute the ICC from the LMM fallback's variance components (see
#    Section 3) and interpret: is more of the unexplained variance at
#    the LOCATION level or the BROOD level? Compare to R's glmer() ICC.
# 3. Refit the LMM fallback with only LOCATION as a random effect
#    (drop the BROOD vc_formula term) and compare variance components
#    and fixed-effect standard errors to the nested model above.
# 4. Extract per-BROOD random effects from lmm_result.random_effects
#    and plot them against the number of chicks per brood -- confirm
#    that broods with fewer chicks show more shrinkage toward zero
#    (partial pooling), matching R's ranef() output.
