"""
Lecture 13 -- Species Distribution / Niche Models
Ecological Modelling with R, Python, and Julia

Dataset:
    data/bei_points.csv          (x, y coordinates of 3604 individually
                                   mapped Beilschmiedia pendula trees)
    data/bei_covariates_grid.csv (x, y, elev, grad -- a fine regular grid
                                   of elevation and slope-gradient
                                   covariates across the same plot)
    Barro Colorado Island 50-ha forest census: Condit, Hubbell & Foster
    (2002), Science; Hubbell et al. (1999), Science. One of the most-cited
    real datasets in spatial/community ecology, and the standard teaching
    example for spatial point-process / SDM-style modeling.

Task: we only have tree LOCATIONS, not surveyed absences -- the classic
      presence-only / presence-background SDM data problem. We generate
      random background points across the plot, build a presence (1)
      vs. background (0) classification dataset with elev/grad
      covariates, and fit a logistic regression SDM and a Random Forest
      SDM (reusing Lecture 12's toolkit), compare them by AUC, and
      produce a habitat-suitability map.

Assumes working directory = repository root, i.e. run as:
    python3 code/python/lecture_13_species_distribution_models.py
"""

import os

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from scipy.spatial import cKDTree
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score, accuracy_score

RNG_SEED = 13
rng = np.random.RandomState(RNG_SEED)
os.makedirs("figures", exist_ok=True)

## ------------------------------------------------------------
## 0. Load data
## ------------------------------------------------------------
pts = pd.read_csv("data/bei_points.csv")
grid = pd.read_csv("data/bei_covariates_grid.csv")

print(f"Tree locations: {len(pts)}")
print(f"Covariate grid cells: {len(grid)}")
print(f"Plot extent: x in [{grid.x.min()}, {grid.x.max()}]  "
      f"y in [{grid.y.min()}, {grid.y.max()}]")

## ------------------------------------------------------------
## 1. Nearest-neighbour join: extract elev/grad at each tree location
##    from the nearest grid cell using a KD-tree (grid is regular but
##    tree coordinates are continuous).
## ------------------------------------------------------------
grid_tree = cKDTree(grid[["x", "y"]].values)

_, idx_presence = grid_tree.query(pts[["x", "y"]].values, k=1)
pts = pts.copy()
pts["elev"] = grid["elev"].values[idx_presence]
pts["grad"] = grid["grad"].values[idx_presence]

## ------------------------------------------------------------
## 2. Background (pseudo-absence) points
##    Standard presence-background workaround: sample random points
##    across the study area to contrast against presence locations.
##    We sample 2x as many background points as presences, directly
##    from the covariate grid's coordinate range, with a fixed seed.
## ------------------------------------------------------------
n_presence = len(pts)
n_background = 2 * n_presence

bg_x = rng.uniform(grid.x.min(), grid.x.max(), n_background)
bg_y = rng.uniform(grid.y.min(), grid.y.max(), n_background)

_, idx_bg = grid_tree.query(np.column_stack([bg_x, bg_y]), k=1)
background = pd.DataFrame({
    "x": bg_x, "y": bg_y,
    "elev": grid["elev"].values[idx_bg],
    "grad": grid["grad"].values[idx_bg],
})

## ------------------------------------------------------------
## 3. Build the presence (1) / background (0) classification dataset
## ------------------------------------------------------------
dat = pd.concat([
    pd.DataFrame({"presence": 1, "x": pts.x, "y": pts.y,
                  "elev": pts.elev, "grad": pts.grad}),
    pd.DataFrame({"presence": 0, "x": background.x, "y": background.y,
                  "elev": background.elev, "grad": background.grad}),
], ignore_index=True)

print("\nPresence-background dataset:")
print(f"  Presence points:   {(dat.presence == 1).sum()}")
print(f"  Background points: {(dat.presence == 0).sum()}")

X = dat[["elev", "grad"]].values
y = dat["presence"].values

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, random_state=RNG_SEED, stratify=y
)

## ------------------------------------------------------------
## 4. Logistic regression SDM: presence ~ elev + grad
## ------------------------------------------------------------
glm_fit = LogisticRegression()
glm_fit.fit(X_train, y_train)

print("\n--- Logistic Regression SDM ---")
print(f"Intercept: {glm_fit.intercept_[0]:.4f}")
print(f"Coefficients (elev, grad): {glm_fit.coef_[0]}")

glm_pred_test = glm_fit.predict_proba(X_test)[:, 1]
glm_auc = roc_auc_score(y_test, glm_pred_test)
glm_acc = accuracy_score(y_test, glm_pred_test > 0.5)
print(f"Held-out test AUC (GLM): {glm_auc:.3f}")
print(f"Held-out test accuracy (GLM, 0.5 cutoff): {glm_acc:.3f}")

## ------------------------------------------------------------
## 5. Random Forest SDM (reusing Lecture 12's toolkit)
## ------------------------------------------------------------
rf_fit = RandomForestClassifier(
    n_estimators=500, max_features="sqrt", oob_score=True,
    random_state=RNG_SEED,
)
rf_fit.fit(X_train, y_train)

print("\n--- Random Forest SDM ---")
print(f"OOB accuracy: {rf_fit.oob_score_:.3f}")
print("Variable importance (elev, grad):", rf_fit.feature_importances_)

rf_pred_test = rf_fit.predict_proba(X_test)[:, 1]
rf_auc = roc_auc_score(y_test, rf_pred_test)
rf_acc = accuracy_score(y_test, rf_pred_test > 0.5)
print(f"Held-out test AUC (Random Forest): {rf_auc:.3f}")
print(f"Held-out test accuracy (Random Forest): {rf_acc:.3f}")

print("\n--- GLM vs. Random Forest, held-out AUC ---")
print(f"  Logistic regression: {glm_auc:.3f}")
print(f"  Random forest:       {rf_auc:.3f}")

## ------------------------------------------------------------
## 6. Partial dependence on elevation (grad held at its median)
##    -- what did the GLM/RF learn about Beilschmiedia's elevation
##    preference on BCI?
## ------------------------------------------------------------
elev_seq = np.linspace(grid.elev.min(), grid.elev.max(), 100)
grad_median = np.median(dat.grad)
pd_X = np.column_stack([elev_seq, np.full_like(elev_seq, grad_median)])

glm_suitability = glm_fit.predict_proba(pd_X)[:, 1]
rf_suitability = rf_fit.predict_proba(pd_X)[:, 1]

print("\n--- Partial dependence on elevation (grad held at median) ---")
print(f"Elevation range in data: {dat.elev.min():.1f} to {dat.elev.max():.1f}")
print("GLM: suitability is monotonic (no interior optimum by construction);")
print(f"     max predicted suitability at elev = {elev_seq[np.argmax(glm_suitability)]:.1f} m")
print(f"RF:  max predicted suitability at elev = {elev_seq[np.argmax(rf_suitability)]:.1f} m")

## ------------------------------------------------------------
## 7. Predict suitability across the full covariate grid and map it
##    (Random Forest prediction shown here -- the same idea applies to
##    the GLM; both models predict a probability for every grid cell.)
## ------------------------------------------------------------
grid_X = grid[["elev", "grad"]].values
grid["suitability_rf"] = rf_fit.predict_proba(grid_X)[:, 1]
grid["suitability_glm"] = glm_fit.predict_proba(grid_X)[:, 1]

print("\nSuitability grid summary (Random Forest):")
print(grid["suitability_rf"].describe())

fig, ax = plt.subplots(figsize=(10, 5.2))
sc = ax.scatter(grid.x, grid.y, c=grid.suitability_rf, cmap="viridis",
                 s=4, marker="s")
ax.set_xlabel("x (m)")
ax.set_ylabel("y (m)")
ax.set_title("Beilschmiedia pendula habitat suitability (Random Forest SDM)\n"
             "Barro Colorado Island 50-ha plot -- presence-background model")
ax.set_aspect("equal")
fig.colorbar(sc, ax=ax, label="Predicted suitability")
fig.tight_layout()
fig.savefig("figures/lecture_13_suitability_map.png", dpi=130)
plt.close(fig)

print("\nFigure saved to figures/lecture_13_suitability_map.png")

# --- EXERCISES ---
# TODO 1: Resample background points at 2x and 4x the presence count
#         used here (n_background = 2 * n_presence). Refit the logistic
#         regression each time and compare the elev/grad coefficients
#         (glm_fit.coef_) -- how sensitive is the model to the number of
#         background points?
# TODO 2: Add an elev**2 feature (np.column_stack([elev, elev**2, grad]))
#         to the logistic regression to allow an interior elevation
#         optimum rather than a monotonic response. Compare test AUC to
#         the linear-elevation model and re-plot the partial dependence
#         curve.
# TODO 3: Using the SAME train/test split (X_train/X_test/y_train/y_test
#         above), compare RF vs. GLM AUC and accuracy across a few
#         different random_state values for train_test_split. How much
#         does the "winner" change seed to seed?
# TODO 4: The train/test split here is a simple stratified random split
#         of presence+background points, which does NOT account for
#         spatial autocorrelation (nearby points are not independent).
#         Try a spatial block split instead (e.g. dat.x < 500 for
#         training, dat.x >= 500 for testing) and compare AUC to the
#         random-split estimate above -- is the spatially honest AUC
#         higher or lower, and why?
