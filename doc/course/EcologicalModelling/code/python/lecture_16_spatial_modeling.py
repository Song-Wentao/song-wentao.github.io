"""
Lecture 16 -- Spatial Modeling (course finale)
Ecological Modelling with R, Python, and Julia

Datasets:
  data/mite_env.csv            (SubsDens, WatrCont, Substrate, Shrub,
                                 Topo, x, y for 70 oribatid mite cores,
                                 Lac Cromwell -- Borcard & Legendre 1994,
                                 Ecology)
  data/bei_points.csv          (x, y of 3604 individually mapped
                                 Beilschmiedia pendula trees)
  data/bei_covariates_grid.csv (x, y, elev, grad -- a fine regular grid
                                 of elevation/slope-gradient covariates)
  Barro Colorado Island 50-ha forest census: Condit, Hubbell & Foster
  (2002), Science.

Part 1: Spatial autocorrelation. Every model in Lectures 5-13 assumes
        independent residuals. We quantify how badly that assumption is
        violated for mite WatrCont using Moran's I on a k-nearest-
        neighbour spatial weights matrix, with esda (PySAL) and a
        permutation test, cross-checked against a hand-rolled version of
        the exact same statistic.

Part 2: Spatial point process modeling. The BEI tree locations are
        binned into a coarse grid and modeled with a discretized Poisson
        GLM -- a piecewise-constant approximation to an inhomogeneous
        Poisson point process, and the direct extension of Lecture 13's
        presence-background SDM into a formal point-process framework.

Assumes working directory = repository root, i.e. run as:
  python3 code/python/lecture_16_spatial_modeling.py
"""

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import statsmodels.api as sm
import statsmodels.formula.api as smf

from libpysal.weights import KNN
from esda.moran import Moran

np.random.seed(16)

# ============================================================
# PART 1 -- Moran's I on mite WatrCont (spatial autocorrelation)
# ============================================================

mite_env = pd.read_csv("data/mite_env.csv")
print(f"Mite cores: {len(mite_env)}")
print(f"x range: {mite_env.x.min()} - {mite_env.x.max()}  "
      f"y range: {mite_env.y.min()} - {mite_env.y.max()}\n")

coords = mite_env[["x", "y"]].values
watr = mite_env["WatrCont"].values

# ------------------------------------------------------------
# 1. k-nearest-neighbour spatial weights (k = 5), row-standardized,
#    via libpysal -- the standard PySAL weights object.
# ------------------------------------------------------------
k = 5
w = KNN.from_array(coords, k=k)
w.transform = "r"  # row-standardize: each row's weights sum to 1

# ------------------------------------------------------------
# 2. Moran's I via esda (PySAL), with a permutation-based p-value
#    (esda's default: 999 conditional permutations).
# ------------------------------------------------------------
mi = Moran(watr, w, permutations=999)
print(f"Observed Moran's I for WatrCont (k={k} NN weights, esda): {mi.I:.4f}")
print(f"Expected I under no autocorrelation: {mi.EI:.4f}")
print(f"Permutation-based p-value (999 permutations): {mi.p_sim:.4f}")
print(f"Null distribution (permutations): mean = {np.mean(mi.sim):.4f}, "
      f"SD = {np.std(mi.sim):.4f}")

if mi.p_sim < 0.05:
    print("--> Significant POSITIVE spatial autocorrelation in WatrCont:")
    print("    nearby cores have more similar water content than expected")
    print("    by chance. The independence assumption behind ordinary")
    print("    GLM/GAM standard errors is violated for this variable.\n")

# ------------------------------------------------------------
# 2b. Hand-rolled cross-check of the exact same statistic, using
#     scipy.spatial.cKDTree for the k-NN lookup -- a great cross-
#     language teaching moment: this should match esda's mi.I closely
#     (esda's internal row-standardized W is built the same way).
# ------------------------------------------------------------
from scipy.spatial import cKDTree


def knn_weights(coords, k):
    n = coords.shape[0]
    tree = cKDTree(coords)
    # k+1 because the nearest neighbour of a point is itself (distance 0)
    _, idx = tree.query(coords, k=k + 1)
    W = np.zeros((n, n))
    for i in range(n):
        neighbours = idx[i, 1:]  # drop self
        W[i, neighbours] = 1.0 / k
    return W


def morans_i(x, W):
    n = len(x)
    xbar = x.mean()
    dev = x - xbar
    S0 = W.sum()
    num = np.sum(W * np.outer(dev, dev))
    den = np.sum(dev ** 2)
    return (n / S0) * (num / den)


W_hand = knn_weights(coords, k)
I_hand = morans_i(watr, W_hand)
print(f"Hand-rolled Moran's I (scipy cKDTree, same k={k}): {I_hand:.4f}")
print("(esda and the hand-rolled version should match closely -- both use")
print(" row-standardized k-NN weights and the same formula.)\n")

# ------------------------------------------------------------
# 3. Moran scatterplot: WatrCont vs. its spatially lagged value.
# ------------------------------------------------------------
lagged_watr = W_hand @ watr

slope, intercept = np.polyfit(watr, lagged_watr, 1)
print(f"Moran scatterplot regression slope: {slope:.4f} "
      f"(compare to I = {I_hand:.4f})")

fig, ax = plt.subplots(figsize=(7, 6.2))
ax.scatter(watr, lagged_watr, s=45, alpha=0.7, color="#2c7fb8", edgecolor="white")
ax.axhline(lagged_watr.mean(), color="grey", linestyle=":", linewidth=1)
ax.axvline(watr.mean(), color="grey", linestyle=":", linewidth=1)
xs = np.linspace(watr.min(), watr.max(), 100)
ax.plot(xs, intercept + slope * xs, color="firebrick", linewidth=2,
        label=f"slope ~ Moran's I = {I_hand:.3f}")
ax.set_xlabel("WatrCont (site i)")
ax.set_ylabel("Spatially lagged WatrCont (mean of k=5 NN)")
ax.set_title(f"Moran Scatterplot -- WatrCont (Moran's I = {mi.I:.3f}, "
             f"p = {mi.p_sim:.3f})")
ax.legend(loc="upper left", frameon=False)
fig.tight_layout()
fig.savefig("figures/lecture_16_moran_scatterplot.png", dpi=130)
plt.close(fig)
print("Figure saved to figures/lecture_16_moran_scatterplot.png\n")

# ------------------------------------------------------------
# 4. What to do about it: a GAM with a 2-D smooth s(x, y) (Lecture 8)
#    absorbs whatever smooth spatial surface is left over. statsmodels
#    does not have a native 2-D thin-plate smoother as simple as mgcv's
#    s(x, y), so we approximate it here with a low-order polynomial
#    surface in x and y (a "trend surface" model) -- conceptually the
#    same idea as a spatial smooth, just with a simpler basis.
# ------------------------------------------------------------
mite_env["x2"] = mite_env.x ** 2
mite_env["y2"] = mite_env.y ** 2
mite_env["xy"] = mite_env.x * mite_env.y
trend_fit = smf.ols("WatrCont ~ x + y + x2 + y2 + xy", data=mite_env).fit()
print("--- Trend-surface regression (polynomial stand-in for s(x,y)) ---")
print(trend_fit.summary().tables[1])

resid_trend = trend_fit.resid.values
I_resid = morans_i(resid_trend, W_hand)
print(f"\nMoran's I of the trend-surface residuals: {I_resid:.4f}")
print(f"(vs. Moran's I of the raw data: {I_hand:.4f}) -- modeling x, y")
print("directly absorbs a large share of the spatial structure.\n")

# ============================================================
# PART 2 -- Discretized inhomogeneous Poisson point process (BEI trees)
# ============================================================

print("\n" + "=" * 60)
print("PART 2: Spatial point process model -- BEI Beilschmiedia trees")
print("=" * 60 + "\n")

pts = pd.read_csv("data/bei_points.csv")
grid = pd.read_csv("data/bei_covariates_grid.csv")

print(f"Tree locations: {len(pts)}")
print(f"Covariate grid cells: {len(grid)}")

# ------------------------------------------------------------
# 1. Bin the plot into a coarse regular grid (25 x 10 cells) and count
#    trees per cell -- a piecewise-constant approximation to a
#    continuous-space inhomogeneous Poisson process. Each cell's
#    covariates are the mean elev/grad of the fine grid cells it
#    contains.
# ------------------------------------------------------------
n_bins_x, n_bins_y = 25, 10
x_breaks = np.linspace(grid.x.min(), grid.x.max(), n_bins_x + 1)
y_breaks = np.linspace(grid.y.min(), grid.y.max(), n_bins_y + 1)
cell_area = (x_breaks[1] - x_breaks[0]) * (y_breaks[1] - y_breaks[0])

pts = pts.copy()
pts["bin_x"] = np.clip(np.digitize(pts.x, x_breaks) - 1, 0, n_bins_x - 1)
pts["bin_y"] = np.clip(np.digitize(pts.y, y_breaks) - 1, 0, n_bins_y - 1)

grid = grid.copy()
grid["bin_x"] = np.clip(np.digitize(grid.x, x_breaks) - 1, 0, n_bins_x - 1)
grid["bin_y"] = np.clip(np.digitize(grid.y, y_breaks) - 1, 0, n_bins_y - 1)

cell_cov = grid.groupby(["bin_x", "bin_y"])[["elev", "grad"]].mean().reset_index()
counts = (pts.groupby(["bin_x", "bin_y"]).size()
              .reset_index(name="count"))

cell_dat = cell_cov.merge(counts, on=["bin_x", "bin_y"], how="left")
cell_dat["count"] = cell_dat["count"].fillna(0).astype(int)
cell_dat["cell_area"] = cell_area
cell_dat["log_area"] = np.log(cell_area)

print(f"\nDiscretized grid: {n_bins_x} x {n_bins_y} = {len(cell_dat)} cells, "
      f"cell size {x_breaks[1]-x_breaks[0]:.1f} x {y_breaks[1]-y_breaks[0]:.1f} m")
print(f"Mean tree count per cell: {cell_dat['count'].mean():.1f} "
      f"(min {cell_dat['count'].min()}, max {cell_dat['count'].max()})")

# ------------------------------------------------------------
# 2. Fit Poisson GLMs of increasing complexity, with a log(cell area)
#    offset, and compare by AIC -- the discretized-grid equivalent of
#    R's spatstat::ppm(pp ~ 1), ppm(pp ~ elev), ppm(pp ~ elev + grad).
# ------------------------------------------------------------
glm_null = smf.glm("count ~ 1", data=cell_dat,
                    family=sm.families.Poisson(),
                    offset=cell_dat["log_area"]).fit()
glm_elev = smf.glm("count ~ elev", data=cell_dat,
                    family=sm.families.Poisson(),
                    offset=cell_dat["log_area"]).fit()
glm_full = smf.glm("count ~ elev + grad", data=cell_dat,
                    family=sm.families.Poisson(),
                    offset=cell_dat["log_area"]).fit()

print("\n--- Homogeneous Poisson (intercept-only) ---")
print(glm_null.summary().tables[1])
print("\n--- Inhomogeneous Poisson GLM: ~ elev ---")
print(glm_elev.summary().tables[1])
print("\n--- Inhomogeneous Poisson GLM: ~ elev + grad ---")
print(glm_full.summary().tables[1])

print("\n--- Model comparison (AIC) ---")
aic_tab = pd.DataFrame({
    "model": ["Homogeneous (intercept only)", "~ elev", "~ elev + grad"],
    "AIC": [glm_null.aic, glm_elev.aic, glm_full.aic],
})
print(aic_tab.to_string(index=False))
best = aic_tab.loc[aic_tab.AIC.idxmin(), "model"]
print(f"\nBest model by AIC: {best}")

# Likelihood ratio test: elev + grad vs elev alone
lr_stat = 2 * (glm_full.llf - glm_elev.llf)
from scipy.stats import chi2
lr_p = chi2.sf(lr_stat, df=1)
print(f"\nLikelihood ratio test (elev+grad vs. elev alone): "
      f"LR = {lr_stat:.2f}, df = 1, p = {lr_p:.4g}")

cell_dat["fitted_intensity"] = glm_full.fittedvalues / cell_dat["cell_area"]
cell_dat["observed_density"] = cell_dat["count"] / cell_dat["cell_area"]

# ------------------------------------------------------------
# 3. Figure: observed tree density vs. fitted intensity surface
# ------------------------------------------------------------
obs_mat = np.full((n_bins_y, n_bins_x), np.nan)
fit_mat = np.full((n_bins_y, n_bins_x), np.nan)
for _, row in cell_dat.iterrows():
    obs_mat[int(row.bin_y), int(row.bin_x)] = row.observed_density
    fit_mat[int(row.bin_y), int(row.bin_x)] = row.fitted_intensity

vmin = min(np.nanmin(obs_mat), np.nanmin(fit_mat))
vmax = max(np.nanmax(obs_mat), np.nanmax(fit_mat))

fig, axes = plt.subplots(1, 2, figsize=(13, 5.4))
im0 = axes[0].imshow(obs_mat, origin="lower", cmap="viridis", vmin=vmin, vmax=vmax,
                      extent=[x_breaks[0], x_breaks[-1], y_breaks[0], y_breaks[-1]],
                      aspect="auto")
axes[0].set_title("Observed tree density\n(trees / m^2)")
axes[0].set_xlabel("x (m)")
axes[0].set_ylabel("y (m)")

im1 = axes[1].imshow(fit_mat, origin="lower", cmap="viridis", vmin=vmin, vmax=vmax,
                      extent=[x_breaks[0], x_breaks[-1], y_breaks[0], y_breaks[-1]],
                      aspect="auto")
axes[1].set_title("Fitted intensity\n(Poisson GLM ~ elev + grad)")
axes[1].set_xlabel("x (m)")
axes[1].set_ylabel("y (m)")

fig.colorbar(im1, ax=axes, shrink=0.85, label="trees / m^2")
fig.suptitle("BEI 50-ha plot -- Beilschmiedia pendula, "
             "inhomogeneous point process", y=1.02)
fig.savefig("figures/lecture_16_bei_intensity_surface.png", dpi=130,
            bbox_inches="tight")
plt.close(fig)
print("\nFigure saved to figures/lecture_16_bei_intensity_surface.png")

print("\nDone.")

# --- EXERCISES ---
# TODO 1: Recompute Moran's I for WatrCont using k = 3 and k = 10 nearest
#         neighbours instead of k = 5 (change `k` and rebuild `w`/
#         `W_hand`). Does the observed I, and its permutation p-value,
#         change much? What does that tell you about the spatial scale
#         at which water content is patchy at this site?
# TODO 2: Fit a richer spatial surface than the quadratic trend-surface
#         model above (e.g. add x**3, y**3, or x**2*y interaction terms,
#         or install pyGAM/mgcv-style smooths) and compare its residual
#         Moran's I to the quadratic version fit here. Does more spatial
#         flexibility keep removing autocorrelation, or does it plateau?
# TODO 3: Refit the BEI point process with just ~ elev (glm_elev above)
#         and compare its AIC to ~ elev + grad (glm_full). Does gradient
#         add real explanatory power, or is elevation alone doing most of
#         the work? Cross-check your conclusion against the LRT above.
# TODO 4: The discretized Poisson GLM used 25 x 10 cells. Refit it with a
#         much coarser grid (e.g. 10 x 4) and a much finer grid (e.g.
#         50 x 20). How do the elev/grad coefficients and AIC change with
#         cell size? What are the tradeoffs of picking cells that are too
#         coarse vs. too fine for this kind of discretized approximation?
# TODO 5: Using glm_full's fitted_intensity surface, identify the grid
#         cell with the single highest predicted tree intensity. Look up
#         its elev and grad values -- does the combination make
#         ecological sense for a species like Beilschmiedia pendula
#         (a shade-tolerant canopy tree), or does it look like an
#         extrapolation artifact from a sparsely sampled corner of
#         covariate space?
