"""
Lecture 9 -- Bayesian Hierarchical Models
Ecological Modelling with R, Python, and Julia

Dataset:
    data/grouseticks.csv  (Elston, Moss, Boulinier, Arrowsmith &
                           Lambin 2001, Parasitology 122:563-569)

    403 red grouse chicks, TICKS (tick count) measured on each chick.
    Chicks are nested within BROOD (118 broods), and broods are
    nested within LOCATION (63 locations). HEIGHT/cHEIGHT is altitude
    (centered). YEAR is 95/96/97.

Continuity with Lecture 7:
    Lecture 7 fit the frequentist Poisson GLMM in R
        glmer(TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD), family=poisson)
    which already does PARTIAL POOLING implicitly (BLUPs for small
    broods shrink toward the population mean). This lecture builds the
    SAME model structure fully Bayesian with PyMC: the shrinkage
    becomes explicit posterior distributions for every LOCATION and
    BROOD effect, and uncertainty propagates correctly through every
    level of the model, including the variance components.

Model (Poisson, log link):
    log(E[TICKS]) = Intercept + YEAR + cHEIGHT
                    + u_LOCATION[loc] + u_BROOD[brood]
    u_LOCATION ~ Normal(0, sigma_location)
    u_BROOD    ~ Normal(0, sigma_brood)        (nested within LOCATION)

Priors (weakly informative, ecologically sensible defaults on the log
scale):
    Intercept, YEAR, cHEIGHT coefficients ~ Normal(0, 5)
    sigma_location, sigma_brood           ~ HalfCauchy(2)
        (half-Cauchy on variance-component SDs is a standard weakly
        informative default alongside Exponential(1); we use it here
        to show the alternative discussed in lecture)

Sampling kept modest (draws=500, tune=500, chains=2) via NUTS so this
completes in a sandboxed environment without a large time budget. As
with the R fit, this is not enough for a publication-grade analysis --
in practice use more draws/tune and check diagnostics carefully.

Assumes working directory = repository root, i.e. run as:
    python3 code/python/lecture_09_bayesian_hierarchical.py
"""

import os

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

import pymc as pm
import arviz as az

RNG_SEED = 42

os.makedirs("figures", exist_ok=True)

print("=== Lecture 9: Bayesian Hierarchical Models (Python / PyMC) ===\n")

## ------------------------------------------------------------
## 1. Load data, build integer codes for grouping factors
## ------------------------------------------------------------

dat = pd.read_csv("data/grouseticks.csv")
dat["BROOD"] = dat["BROOD"].astype(str)
dat["LOCATION"] = dat["LOCATION"].astype(str)
dat["YEAR"] = dat["YEAR"].astype(str)

print(f"n chicks:    {len(dat)}")
print(f"n broods:    {dat['BROOD'].nunique()}")
print(f"n locations: {dat['LOCATION'].nunique()}\n")

# Integer codes for LOCATION (0..n_loc-1)
loc_levels = sorted(dat["LOCATION"].unique(), key=lambda x: int(x))
loc_idx_map = {lvl: i for i, lvl in enumerate(loc_levels)}
loc_idx = dat["LOCATION"].map(loc_idx_map).to_numpy()
n_loc = len(loc_levels)

# Integer codes for BROOD, nested within LOCATION: BROOD ids are
# globally unique in this dataset (as noted in Lecture 7), so a
# simple global BROOD index plus a brood -> location lookup captures
# the nesting exactly.
brood_levels = sorted(dat["BROOD"].unique(), key=lambda x: int(x))
brood_idx_map = {lvl: i for i, lvl in enumerate(brood_levels)}
brood_idx = dat["BROOD"].map(brood_idx_map).to_numpy()
n_brood = len(brood_levels)

# For each brood, which location does it belong to (for structure only;
# not needed directly in the likelihood since brood_idx already
# uniquely identifies rows, but useful for later plotting/exercises)
brood_to_loc = (
    dat.drop_duplicates("BROOD")
    .assign(brood_i=lambda d: d["BROOD"].map(brood_idx_map),
            loc_i=lambda d: d["LOCATION"].map(loc_idx_map))
    .set_index("brood_i")["loc_i"]
    .sort_index()
    .to_numpy()
)

# Design matrix for fixed effects: Intercept + YEAR96 + YEAR97 + cHEIGHT
# (standardized, for sampler stability -- see numerical note below)
year_dummies = pd.get_dummies(dat["YEAR"], drop_first=True)  # YEAR96, YEAR97
year_dummies = year_dummies.reindex(columns=["96", "97"], fill_value=0)
year96 = year_dummies["96"].to_numpy(dtype=float)
year97 = year_dummies["97"].to_numpy(dtype=float)

cheight_mean = dat["cHEIGHT"].mean()
cheight_sd = dat["cHEIGHT"].std()
cheight_s = ((dat["cHEIGHT"] - cheight_mean) / cheight_sd).to_numpy()

y = dat["TICKS"].to_numpy()

## ------------------------------------------------------------
## Numerical note (mirrors the R script): cHEIGHT ranges roughly
## -59 to +71 on its native scale. Standardizing it before building
## the model keeps NUTS well-behaved; the coefficient is converted
## back to the original scale below for comparison with Lecture 7.
## ------------------------------------------------------------

## ------------------------------------------------------------
## 2. Build the hierarchical Poisson model in PyMC
## ------------------------------------------------------------

with pm.Model() as hier_model:

    # Weakly informative priors on fixed effects (log scale)
    intercept = pm.Normal("Intercept", mu=0, sigma=5)
    b_year96 = pm.Normal("YEAR96", mu=0, sigma=5)
    b_year97 = pm.Normal("YEAR97", mu=0, sigma=5)
    b_cheight = pm.Normal("cHEIGHT_s", mu=0, sigma=5)

    # Weakly informative half-Cauchy priors on variance-component SDs
    sigma_loc = pm.HalfCauchy("sigma_LOCATION", beta=2)
    sigma_brood = pm.HalfCauchy("sigma_BROOD", beta=2)

    # Non-centered parameterization for better NUTS geometry
    z_loc = pm.Normal("z_LOCATION", mu=0, sigma=1, shape=n_loc)
    u_loc = pm.Deterministic("u_LOCATION", z_loc * sigma_loc)

    z_brood = pm.Normal("z_BROOD", mu=0, sigma=1, shape=n_brood)
    u_brood = pm.Deterministic("u_BROOD", z_brood * sigma_brood)

    eta = (
        intercept
        + b_year96 * year96
        + b_year97 * year97
        + b_cheight * cheight_s
        + u_loc[loc_idx]
        + u_brood[brood_idx]
    )
    mu = pm.math.exp(eta)

    obs = pm.Poisson("TICKS", mu=mu, observed=y)

    print("--- Sampling with NUTS (draws=500, tune=500, chains=2) ---")
    idata = pm.sample(
        draws=500,
        tune=500,
        chains=2,
        cores=1,
        random_seed=RNG_SEED,
        target_accept=0.9,
        progressbar=False,
    )

## ------------------------------------------------------------
## 3. Posterior summary and diagnostics (arviz)
## ------------------------------------------------------------

fixed_params = ["Intercept", "YEAR96", "YEAR97", "cHEIGHT_s",
                 "sigma_LOCATION", "sigma_BROOD"]

summary = az.summary(idata, var_names=fixed_params, hdi_prob=0.95)
print("\n--- Posterior summary (fixed effects + variance components) ---")
print(summary)

rhat_all = az.rhat(idata, var_names=fixed_params)
ess_all = az.ess(idata, var_names=fixed_params)
print("\nMax R-hat among fixed effects/variance components:",
      float(max(rhat_all[p].values.max() for p in fixed_params)))

## ------------------------------------------------------------
## 4. Compare to Lecture 7's frequentist glmer point estimates
##    (hard-coded from Lecture 7's fitted model; re-derive with
##    glmer(TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD), family=poisson)
##    in R to confirm)
## ------------------------------------------------------------

post_mean = idata.posterior.mean(dim=("chain", "draw"))

intercept_mean = float(post_mean["Intercept"])
year96_mean = float(post_mean["YEAR96"])
year97_mean = float(post_mean["YEAR97"])
cheight_s_mean = float(post_mean["cHEIGHT_s"])
cheight_orig_mean = cheight_s_mean / cheight_sd

glmer_est = {
    "Intercept": 0.467,
    "YEAR96": 1.166,
    "YEAR97": -0.978,
    "cHEIGHT": -0.024,
}
bayes_est = {
    "Intercept": intercept_mean,
    "YEAR96": year96_mean,
    "YEAR97": year97_mean,
    "cHEIGHT": cheight_orig_mean,
}

print("\n--- Lecture 7 (glmer) vs Lecture 9 (PyMC posterior mean) ---")
print(f"{'parameter':<12}{'glmer_L7':>12}{'bayes_L9':>12}")
for p in glmer_est:
    print(f"{p:<12}{glmer_est[p]:>12.3f}{bayes_est[p]:>12.3f}")
print("\nSame model structure, two philosophies -- point estimates are close.\n")

## ------------------------------------------------------------
## 5. Figure: caterpillar plot of a sample of LOCATION-level
##    random-effect posterior means with 95% credible intervals
## ------------------------------------------------------------

u_loc_draws = idata.posterior["u_LOCATION"].stack(sample=("chain", "draw")).values  # (n_loc, n_samples)
loc_mean = u_loc_draws.mean(axis=1)
loc_lo = np.quantile(u_loc_draws, 0.025, axis=1)
loc_hi = np.quantile(u_loc_draws, 0.975, axis=1)

order = np.argsort(loc_mean)
n_show = min(20, n_loc)
sample_pos = np.round(np.linspace(0, n_loc - 1, n_show)).astype(int)
show_idx = order[sample_pos]

fig, ax = plt.subplots(figsize=(8, 7))
y_pos = np.arange(len(show_idx))
ax.errorbar(
    loc_mean[show_idx], y_pos,
    xerr=[loc_mean[show_idx] - loc_lo[show_idx], loc_hi[show_idx] - loc_mean[show_idx]],
    fmt="o", color="#3b7ea1", ecolor="#3b7ea1", capsize=3,
)
ax.set_yticks(y_pos)
ax.set_yticklabels([loc_levels[i] for i in show_idx], fontsize=8)
ax.axvline(0, linestyle="--", color="grey")
ax.set_xlabel("Posterior LOCATION random effect (log scale)")
ax.set_title("Bayesian posterior LOCATION effects\n(posterior mean + 95% credible interval)")
fig.tight_layout()
fig.savefig("figures/lecture_09_posterior_LOCATION_effects.png", dpi=125)
plt.close(fig)

print("Figure saved: figures/lecture_09_posterior_LOCATION_effects.png")
print("\n=== Done ===")


# --- EXERCISES ---
# 1. Change the prior on sigma_LOCATION from HalfCauchy(beta=2) to a
#    tighter HalfCauchy(beta=0.5) or an Exponential(1), refit, and
#    compare the posterior mean and credible interval for
#    sigma_LOCATION to the original.
# 2. Inspect az.summary(idata) in full (all parameters) for r_hat and
#    ess_bulk -- are there any parameters with r_hat > 1.01 or
#    ess_bulk < 400? Use az.plot_trace(idata, var_names=fixed_params)
#    to view trace plots for the fixed effects.
# 3. Add a random slope for cHEIGHT_s by LOCATION (a second
#    non-centered Normal random effect multiplying cHEIGHT_s, added
#    to eta), refit, and compare to the random-intercept-only model
#    using az.compare() with LOO.
# 4. Compute and plot the 95% credible interval for the YEAR97 effect
#    exponentiated to the rate-ratio scale (exp of
#    idata.posterior["YEAR97"] draws), and compare its width and
#    interpretation to the 95% confidence interval Lecture 7's glmer
#    produced for the same coefficient.
