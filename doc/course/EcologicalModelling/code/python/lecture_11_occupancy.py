"""
Lecture 11 -- Occupancy and N-mixture Models
Ecological Modelling with R, Python, and Julia
==============================================================================

DATA PROVENANCE (read this first):
data/crossbill_occupancy_sim.csv is SIMULATED, not raw field data. This
sandbox has no general internet access (only pypi.org and the apt mirror are
reachable) so the real "crossbill" repeat-visit dataset bundled with the R
package `unmarked` (data(crossbill); Swiss breeding bird survey MHB, Schmid,
Zbinden & Keller 2004, Swiss Ornithological Institute) could not be
downloaded. The simulation (code/R/generate_crossbill_data.R, seed
11042004) reproduces the same design -- 200 sites, 3 repeat visits, a
site-level elevation covariate on occupancy (psi), a visit-level date
covariate on detection (p) -- with probabilities calibrated to the ranges
reported in Schmid, Zbinden & Keller (2004) and Royle & Kery (2007, Ecology
88(7):1813-1823): psi ~ 0.3-0.6, p ~ 0.4-0.7.

PYTHON PACKAGE NOTE: there is no mature, actively-maintained Python package
for single-season occupancy modeling comparable to R's `unmarked` (some
partial wrappers exist but are not standard/robust). This script therefore
implements the marginal likelihood BY HAND and maximizes it with
scipy.optimize.minimize -- a real and pedagogically valuable approach: the
closed-form marginal likelihood for a single-season occupancy model
integrates out the unknown true occupancy state z_i:

    L_i = psi_i * prod_j p_ij^{y_ij} (1-p_ij)^{1-y_ij}      if any y_ij == 1
        = psi_i * prod_j (1-p_ij) + (1 - psi_i)               if all y_ij == 0

(missing visits, NaN, are dropped from the product for that site). This is
exactly the likelihood that R's unmarked::occu() maximizes internally.
==============================================================================
"""

import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import expit as plogis
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

np.random.seed(11042004)

df = pd.read_csv("data/crossbill_occupancy_sim.csv")

det_cols = ["det1", "det2", "det3"]
date_cols = ["date1", "date2", "date3"]

Y = df[det_cols].to_numpy(dtype=float)      # NaN allowed
DATE = df[date_cols].to_numpy(dtype=float)
ELEV = df["elevation"].to_numpy(dtype=float)

n_site, n_visit = Y.shape

elev_z = (ELEV - np.nanmean(ELEV)) / np.nanstd(ELEV, ddof=1)
date_z = (DATE - np.nanmean(DATE)) / np.nanstd(DATE, ddof=1)

# -----------------------------------------------------------------------
# 1. Naive occupancy: proportion of sites with >=1 detection across visits
# -----------------------------------------------------------------------
any_detect = np.nanmax(np.where(np.isnan(Y), 0, Y), axis=1) >= 1
naive_occupancy = any_detect.mean()
print(f"Naive occupancy (proportion of sites with >=1 detection): {naive_occupancy:.3f}")


# -----------------------------------------------------------------------
# 2. Single-season occupancy model: psi ~ elevation, p ~ date
#    Hand-rolled marginal-likelihood MLE (see module docstring for formula).
# -----------------------------------------------------------------------
def neg_log_lik(par, Y, elev_z, date_z):
    b0, b1, a0, a1 = par
    psi = plogis(b0 + b1 * elev_z)
    n, J = Y.shape
    ll = 0.0
    for i in range(n):
        obs = ~np.isnan(Y[i, :])
        if not np.any(obs):
            continue
        p_ij = plogis(a0 + a1 * date_z[i, obs])
        y_ij = Y[i, obs]
        if np.any(y_ij == 1):
            lik = psi[i] * np.prod(p_ij**y_ij * (1 - p_ij) ** (1 - y_ij))
        else:
            lik = psi[i] * np.prod(1 - p_ij) + (1 - psi[i])
        ll += np.log(max(lik, 1e-12))
    return -ll


start = np.zeros(4)
result = minimize(
    neg_log_lik, start, args=(Y, elev_z, date_z), method="BFGS",
    options={"gtol": 1e-8, "maxiter": 1000},
)

coef_hat = result.x
# Approximate standard errors from the inverse Hessian (BFGS returns hess_inv)
se_hat = np.sqrt(np.diag(result.hess_inv))

param_names = ["psi_intercept", "psi_elevation", "p_intercept", "p_date"]
print("\nMLE coefficients (logit scale):")
for name, est, se in zip(param_names, coef_hat, se_hat):
    print(f"  {name:15s} estimate={est: .4f}  se={se:.4f}")

psi_hat_site = plogis(coef_hat[0] + coef_hat[1] * elev_z)
model_occupancy = psi_hat_site.mean()

print(f"\nModel-estimated occupancy (mean psi_hat across sites): {model_occupancy:.3f}")
print(f"Naive occupancy                                       : {naive_occupancy:.3f}")
print(f"Correction for imperfect detection (model - naive)    : +{model_occupancy - naive_occupancy:.3f}")

# -----------------------------------------------------------------------
# 3. Figure: naive vs model-estimated occupancy, and psi_hat vs elevation
# -----------------------------------------------------------------------
fig, axes = plt.subplots(1, 2, figsize=(11, 5))

axes[0].bar(
    ["Naive\n(>=1 detection)", "Model-estimated\n(psi, detection-corrected)"],
    [naive_occupancy, model_occupancy],
    color=["#a6a6a6", "#2c7fb8"],
)
axes[0].set_ylim(0, 1)
axes[0].set_ylabel("Occupancy proportion")
axes[0].set_title("Naive vs Model-Estimated Occupancy")
for x, v in enumerate([naive_occupancy, model_occupancy]):
    axes[0].text(x, v + 0.03, f"{v:.2f}", ha="center")

order = np.argsort(elev_z)
axes[1].plot(ELEV[order], psi_hat_site[order], lw=2, color="#2c7fb8")
axes[1].set_xlabel("Elevation (m)")
axes[1].set_ylabel(r"$\hat{\psi}$")
axes[1].set_title(r"Estimated $\psi$ vs Elevation")
axes[1].set_ylim(0, 1)
axes[1].scatter(ELEV, np.full_like(ELEV, 0.0), marker="|", color="gray", alpha=0.4)

plt.tight_layout()
import os
os.makedirs("figures", exist_ok=True)
plt.savefig("figures/lecture_11_naive_vs_estimated_occupancy.png", dpi=130)
print("\nSaved figures/lecture_11_naive_vs_estimated_occupancy.png")

# =============================================================================
# --- EXERCISES ---
# See exercises/lecture_11_exercises.md. TODOs to implement here:
# 1. TODO: Re-simulate the dataset (or subset detection columns) at lower and
#    higher true detection probability (e.g. modify alpha0 in
#    generate_crossbill_data.R) and recompute naive vs model-estimated
#    occupancy for each; compare how the gap changes.
# 2. TODO: Add a quadratic elevation term to psi (b0 + b1*elev_z + b2*elev_z**2)
#    in neg_log_lik and re-fit with scipy.optimize.minimize; compare AIC
#    (2*k - 2*logLik) to the linear model.
# 3. TODO: Refit using only det_cols[:2] / date_cols[:2] (drop the third
#    visit) and compare coefficient estimates and standard errors to the
#    3-visit fit -- what happens to identifiability/precision?
# 4. TODO: Simulate a single-visit-only dataset (J=1) and show empirically
#    that psi and p become non-identifiable (try fitting neg_log_lik on it).
# =============================================================================
