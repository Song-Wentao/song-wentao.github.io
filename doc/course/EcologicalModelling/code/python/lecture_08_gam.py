"""
Lecture 8 -- Generalized Additive Models
Ecological Modelling with R, Python, and Julia

Dataset:
    data/mite_species.csv (70 sites x 35 oribatid mite species, wide format,
                            first column "site")
    data/mite_env.csv     (site, SubsDens, WatrCont, Substrate, Shrub,
                            Topo, x, y)
    Borcard & Legendre (1994), Ecology 75: 1682-1692 -- Lac Cromwell
    Sphagnum peatland, oribatid mite community and environmental data.

Response: species richness per site (count of species with abundance > 0)

Methods:
    1. Linear model:  richness ~ WatrCont            (statsmodels OLS)
    2. Gaussian GAM:  richness ~ s(WatrCont)          (pygam LinearGAM)
    3. Poisson GAM:   richness ~ s(WatrCont)          (pygam PoissonGAM)
    4. AIC comparison of the linear model vs. the Gaussian GAM
    5. Plot of the fitted smooth (with confidence band) overlaid with the
       linear fit, saved to figures/lecture_08_gam_smooth.png

We try pygam first (the closest Python equivalent to mgcv -- a proper
penalized smooth-term GAM library). If pygam is unavailable, we fall back
to statsmodels.gam.api.GLMGam with a B-spline basis, which is a real,
supported statsmodels API for the same idea (a penalized spline term
inside a GLM), clearly marked below.

Assumes working directory = repository root, i.e. run as:
    python3 code/python/lecture_08_gam.py
"""

import os

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import statsmodels.api as sm

os.makedirs("figures", exist_ok=True)

try:
    from pygam import LinearGAM, PoissonGAM, s as pygam_s
    HAVE_PYGAM = True
except ImportError:
    HAVE_PYGAM = False

print("=== Lecture 8: Generalized Additive Models (Python) ===\n")

# ------------------------------------------------------------
# 0. Build the dataset: richness per site + environmental covariates
# ------------------------------------------------------------
mite_sp = pd.read_csv("data/mite_species.csv")
mite_env = pd.read_csv("data/mite_env.csv")

sp_mat = mite_sp.drop(columns=["site"]).to_numpy(float)
richness = (sp_mat > 0).sum(axis=1)

mite = pd.DataFrame({
    "site": mite_sp["site"],
    "richness": richness,
    "WatrCont": mite_env["WatrCont"].to_numpy(float),
    "SubsDens": mite_env["SubsDens"].to_numpy(float),
})

print("--- Species richness summary ---")
print(mite["richness"].describe())
print("\n--- WatrCont (water content, %) summary ---")
print(mite["WatrCont"].describe())
print()

X = mite["WatrCont"].to_numpy().reshape(-1, 1)
y = mite["richness"].to_numpy()

# ------------------------------------------------------------
# 1. Linear model (Lecture 5 style): richness ~ WatrCont
# ------------------------------------------------------------
X_sm = sm.add_constant(mite["WatrCont"])
lm_fit = sm.OLS(y, X_sm).fit()
print("--- Linear model: richness ~ WatrCont ---")
print(lm_fit.summary())
lm_aic = lm_fit.aic

# ------------------------------------------------------------
# 2 & 3. Gaussian and Poisson GAMs
# ------------------------------------------------------------
if HAVE_PYGAM:
    print("\n(Using pygam -- the closest Python equivalent to mgcv)\n")

    # Gaussian GAM, smoothing parameter (lambda) chosen by grid search
    # (pygam's analogue of mgcv's automatic GCV/REML smoothing selection).
    gam_fit = LinearGAM(pygam_s(0)).gridsearch(X, y, progress=False)
    print("--- Gaussian GAM: richness ~ s(WatrCont) ---")
    print(gam_fit.summary())

    gam_edf = gam_fit.statistics_["edof"]
    gam_aic = gam_fit.statistics_["AIC"]
    print(f"\nEffective degrees of freedom (EDF) of s(WatrCont): {gam_edf:.2f}")
    print("(EDF = 1 would mean the smooth IS a straight line -- a linear")
    print(" model is the special case of a GAM where the penalty shrinks")
    print(" the smooth all the way down to EDF = 1. pygam's grid search")
    print(" lands on a somewhat larger EDF than mgcv's default GCV in R --")
    print(" a normal amount of cross-package variation in smoothing choice,")
    print(" but both agree the curvature beyond linear is modest.)\n")

    # Demonstrate the "GAM generalizes LM" special case directly: force a
    # very large lambda (heavy penalty) and watch EDF collapse toward its
    # floor. pygam's cubic P-spline penalty has a 2-dimensional unpenalized
    # null space (constant + linear trend), so as lambda -> infinity the
    # smooth's EDF bottoms out near 2 rather than mgcv's 1 (mgcv centers
    # the smooth and reports EDF for the *deviation from* the intercept,
    # so its floor is 1); either way, the fitted curve itself becomes a
    # straight line -- the point mgcv's EDF = 1 case makes directly.
    gam_fit_stiff = LinearGAM(pygam_s(0, lam=1e8)).fit(X, y)
    print("--- Same smooth, heavily penalized (lam = 1e8): EDF shrinks to "
          f"{gam_fit_stiff.statistics_['edof']:.2f} (its floor) ---")
    print("(At the penalty floor the fitted curve is visually a straight")
    print(" line -- a heavily-penalized GAM IS essentially a linear model.)\n")

    print("--- AIC comparison: LM vs. GAM ---")
    print(f"Linear model AIC: {lm_aic:.2f}")
    print(f"GAM AIC:          {gam_aic:.2f}")
    print(f"Difference (LM - GAM): {lm_aic - gam_aic:.2f} "
          "(positive favors the GAM)\n")

    # Poisson GAM: richness ~ s(WatrCont), connecting back to Lecture 6's
    # count-model motivation (Poisson family instead of Gaussian).
    gam_pois = PoissonGAM(pygam_s(0)).gridsearch(X, y, progress=False)
    print("--- Poisson GAM: richness ~ s(WatrCont), family = poisson ---")
    print(gam_pois.summary())
    pois_edf = gam_pois.statistics_["edof"]
    pois_aic = gam_pois.statistics_["AIC"]
    print(f"\nPoisson GAM EDF: {pois_edf:.2f}, AIC: {pois_aic:.2f}")
    print("(Not directly comparable to the Gaussian AIC above -- different")
    print(" response distributions -- but comparable to other Poisson models.)\n")

    # Predictions on a grid for the figure
    grid = np.linspace(mite["WatrCont"].min(), mite["WatrCont"].max(), 200).reshape(-1, 1)
    gam_pred = gam_fit.predict(grid)
    gam_ci = gam_fit.confidence_intervals(grid, width=0.95)
    lm_pred = lm_fit.predict(sm.add_constant(grid.flatten(), has_constant="add"))

else:
    # --- FALLBACK: statsmodels GLMGam with a B-spline basis ---
    # Real, supported statsmodels API: build a B-spline design matrix for
    # WatrCont with BSplines, then fit a penalized GLM (GLMGam) on it. This
    # is statsmodels' equivalent of a single-smooth-term GAM.
    print("\n(pygam unavailable -- falling back to statsmodels GLMGam + BSplines)\n")
    from statsmodels.gam.api import GLMGam, BSplines

    bs = BSplines(mite["WatrCont"].to_numpy(), df=[10], degree=[3])
    gam_fit = GLMGam(y, exog=np.ones((len(y), 1)), smoother=bs,
                      family=sm.families.Gaussian()).fit()
    print("--- Gaussian GAM (GLMGam + BSplines): richness ~ bs(WatrCont) ---")
    print(gam_fit.summary())
    gam_aic = gam_fit.aic

    gam_pois = GLMGam(y, exog=np.ones((len(y), 1)), smoother=bs,
                       family=sm.families.Poisson()).fit()
    print("\n--- Poisson GAM (GLMGam + BSplines): richness ~ bs(WatrCont) ---")
    print(gam_pois.summary())

    grid = np.linspace(mite["WatrCont"].min(), mite["WatrCont"].max(), 200)
    grid_bs = bs.transform(grid)
    gam_pred = gam_fit.predict(exog=np.ones((len(grid), 1)), exog_smooth=grid_bs)
    gam_ci = None
    lm_pred = lm_fit.predict(sm.add_constant(grid, has_constant="add"))
    grid = grid.reshape(-1, 1)

# ------------------------------------------------------------
# 5. Figure: fitted smooth (with confidence band) vs. the linear fit
# ------------------------------------------------------------
fig, ax = plt.subplots(figsize=(9, 6.3))
ax.scatter(mite["WatrCont"], mite["richness"], color="black", alpha=0.5,
           label="Observed sites")

if HAVE_PYGAM and gam_ci is not None:
    ax.fill_between(grid.flatten(), gam_ci[:, 0], gam_ci[:, 1],
                     color="#2E6E8E", alpha=0.2)
ax.plot(grid.flatten(), gam_pred, color="#2E6E8E", lw=2.5, label="GAM smooth (95% CI)")
ax.plot(grid.flatten(), lm_pred, color="#C0562B", lw=2, ls="--", label="Linear fit")

ax.set_xlabel("Water content (%)")
ax.set_ylabel("Species richness")
ax.set_title("Richness vs. water content: linear fit vs. GAM smooth")
ax.legend(frameon=False)
fig.tight_layout()
fig.savefig("figures/lecture_08_gam_smooth.png", dpi=150)
print("Saved figures/lecture_08_gam_smooth.png")

# --- EXERCISES ---
# TODO 1: Fit richness ~ s(SubsDens) (swap the X column for mite["SubsDens"])
#         and compare its EDF and shape to the s(WatrCont) smooth fit above.
# TODO 2: Fit a 2-D smooth over WatrCont and SubsDens jointly (pygam supports
#         LinearGAM(s(0) + s(1) + te(0, 1)) with a two-column X) and visualize
#         it as a contour or surface plot.
# TODO 3: Compare the Gaussian GAM (gam_fit) and Poisson GAM (gam_pois) fitted
#         above -- do their smooths look similar? Which is the more
#         appropriate distribution for a count response, and why?
# TODO 4: See exercises/lecture_08_exercises.md for the full exercise set.
