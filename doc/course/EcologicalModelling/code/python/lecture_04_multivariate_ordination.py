"""
Lecture 4: Multivariate and Ordination Methods (Python)
Ecological Modelling with R, Python, and Julia

Datasets:
  data/varechem.csv + data/varespec.csv   (Vare, Ohtonen & Oksanen 1995,
                                            J. Vegetation Science -- reindeer
                                            grazing effects on lichen pastures)
  data/dune_species.csv + data/dune_env.csv (Jongman, ter Braak & van Tongeren,
                                            Dutch dune meadow vegetation survey)

Methods:
  1. PCA on soil chemistry (varechem)          -- sklearn.decomposition.PCA
  2. NMDS on dune community data (Bray-Curtis)  -- sklearn.manifold.MDS(metric=False)
  3. PERMANOVA: does Management explain dune community composition?
     -- skbio.stats.distance.permanova if available, else a hand-rolled
        permutation test on pseudo-F (kept in the script either way so
        students can see how the test statistic is built from scratch).
  4. Hierarchical clustering (average linkage) -- scipy.cluster.hierarchy

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
from scipy.spatial.distance import pdist, squareform
from scipy.cluster.hierarchy import linkage, dendrogram
from sklearn.decomposition import PCA
from sklearn.manifold import MDS
from sklearn.preprocessing import StandardScaler

os.makedirs("figures", exist_ok=True)

print("=== Lecture 4: Multivariate & Ordination (Python) ===\n")

# ---- 1. PCA on soil chemistry -------------------------------------------------
# Why standardize: N, P, K, ... are on wildly different scales (mg/kg vs pH
# units), so raw covariance PCA would be dominated by whichever variable has
# the largest variance.
varechem = pd.read_csv("data/varechem.csv")
chem = varechem.drop(columns=["site"])

chem_scaled = StandardScaler().fit_transform(chem)
pca = PCA()
scores = pca.fit_transform(chem_scaled)

print("--- PCA on varechem (soil chemistry, 24 sites x 14 variables) ---")
var_explained = pca.explained_variance_ratio_ * 100
print("Variance explained by PC1-PC4:", np.round(var_explained[:4], 1))

pc1_loadings = pd.Series(pca.components_[0], index=chem.columns).sort_values()
print("\nPC1 loadings (variable contributions):")
print(pc1_loadings.round(3))

# ---- 2. NMDS on dune community data (Bray-Curtis) ------------------------------
# NMDS does not assume linear relationships between species and axes, which is
# why it (not PCA) is the workhorse ordination method for community abundance
# data with many zeros and nonlinear turnover.
dune_species = pd.read_csv("data/dune_species.csv")
dune_env = pd.read_csv("data/dune_env.csv")

assert list(dune_species["site"]) == list(dune_env["site"])

sp_mat = dune_species.drop(columns=["site"]).to_numpy(dtype=float)
sites = dune_species["site"].astype(str).to_numpy()

bc_condensed = pdist(sp_mat, metric="braycurtis")
bc_square = squareform(bc_condensed)

nmds = MDS(
    n_components=2,
    metric=False,
    dissimilarity="precomputed",
    n_init=20,
    max_iter=500,
    random_state=42,
    normalized_stress=True,
    init="random",
)
nmds_scores = nmds.fit_transform(bc_square)

print("\n--- NMDS on dune_species (Bray-Curtis, k = 2) ---")
print(f"Stress: {nmds.stress_:.4f} "
      "-- rule of thumb: <0.10 excellent, <0.20 usable, >0.20 risky")

# Ordination plot colored by Management
mgmt = dune_env["Management"].astype(str)
palette = {"BF": "#2E6E8E", "HF": "#C0562B", "NM": "#3F8F5C", "SF": "#8E5AA8"}

fig, ax = plt.subplots(figsize=(7.6, 6.2), dpi=125)
for level, color in palette.items():
    mask = (mgmt == level).to_numpy()
    ax.scatter(nmds_scores[mask, 0], nmds_scores[mask, 1],
               color=color, s=70, edgecolor="white", label=level, zorder=3)
for x, y, s in zip(nmds_scores[:, 0], nmds_scores[:, 1], sites):
    ax.annotate(s, (x, y), textcoords="offset points", xytext=(4, 4), fontsize=7)
ax.set_xlabel("NMDS1")
ax.set_ylabel("NMDS2")
ax.set_title("NMDS of Dune Meadow Vegetation (Bray-Curtis)")
ax.legend(title="Management", frameon=False)
ax.axhline(0, color="grey", linewidth=0.5, zorder=1)
ax.axvline(0, color="grey", linewidth=0.5, zorder=1)
fig.tight_layout()
fig.savefig("figures/lecture_04_dune_nmds.png")
plt.close(fig)
print("Saved figures/lecture_04_dune_nmds.png")

# ---- 3. PERMANOVA: does Management explain community composition? -------------
# PERMANOVA partitions variance in the dissimilarity matrix by permuting group
# labels; it is the multivariate analogue of ANOVA when the response is a
# distance matrix rather than a single variable.

def permanova_by_hand(dist_square, groups, n_perm=999, seed=42):
    """Hand-rolled PERMANOVA (pseudo-F + permutation p-value).

    dist_square: n x n distance matrix (numpy array)
    groups: array-like of group labels, length n
    """
    groups = np.asarray(groups)
    n = dist_square.shape[0]
    ss_total = (dist_square ** 2).sum() / (2 * n)

    def pseudo_f(g):
        ss_within = 0.0
        for lvl in np.unique(g):
            idx = np.where(g == lvl)[0]
            n_i = len(idx)
            sub = dist_square[np.ix_(idx, idx)]
            ss_within += (sub ** 2).sum() / (2 * n_i)
        ss_among = ss_total - ss_within
        a = len(np.unique(g))
        df_among, df_within = a - 1, n - a
        return (ss_among / df_among) / (ss_within / df_within), ss_among, ss_within

    f_obs, ss_among, ss_within = pseudo_f(groups)

    rng = np.random.default_rng(seed)
    f_perm = np.empty(n_perm)
    for i in range(n_perm):
        perm_groups = rng.permutation(groups)
        f_perm[i], _, _ = pseudo_f(perm_groups)

    p_value = (np.sum(f_perm >= f_obs) + 1) / (n_perm + 1)
    r2 = ss_among / ss_total
    return {"pseudo_F": f_obs, "R2": r2, "p_value": p_value, "n_perm": n_perm}

used_skbio = False
try:
    from skbio.stats.distance import permanova, DistanceMatrix

    dm = DistanceMatrix(bc_square, ids=sites)
    result = permanova(dm, mgmt.to_numpy(), permutations=999)
    used_skbio = True
    print("\n--- PERMANOVA (skbio): bray-curtis distance ~ Management (999 permutations) ---")
    print(result)
    pseudo_f, p_value = result["test statistic"], result["p-value"]
except Exception as exc:  # pragma: no cover - fallback path
    print(f"\nskbio permanova unavailable ({exc}); using hand-rolled permutation test.")

if not used_skbio:
    res = permanova_by_hand(bc_square, mgmt.to_numpy(), n_perm=999, seed=42)
    print("\n--- PERMANOVA (hand-rolled): bray-curtis distance ~ Management (999 permutations) ---")
    print(f"pseudo-F = {res['pseudo_F']:.4f}, R2 = {res['R2']:.4f}, "
          f"p = {res['p_value']:.4f} (n_perm = {res['n_perm']})")

# Also always print the hand-rolled version for teaching purposes / cross-check,
# even when skbio succeeded.
res_manual = permanova_by_hand(bc_square, mgmt.to_numpy(), n_perm=999, seed=42)
print("\n[cross-check] hand-rolled pseudo-F = {:.4f}, R2 = {:.4f}, p = {:.4f}".format(
    res_manual["pseudo_F"], res_manual["R2"], res_manual["p_value"]))

# ---- 4. Hierarchical clustering (average linkage) -------------------------------
# Complementary, exploratory view of the same Bray-Curtis dissimilarity matrix.
Z = linkage(bc_condensed, method="average")

fig, ax = plt.subplots(figsize=(9.5, 5.5), dpi=125)
dendrogram(Z, labels=sites, ax=ax, leaf_rotation=90, leaf_font_size=8)
ax.set_title("Average-linkage clustering of dune sites (Bray-Curtis)")
ax.set_ylabel("Bray-Curtis distance")
fig.tight_layout()
fig.savefig("figures/lecture_04_dune_hclust.png")
plt.close(fig)
print("\nSaved figures/lecture_04_dune_hclust.png")

print("\n=== Done ===")

# --- EXERCISES ---
# TODO 1: Run PCA on a subset of varechem variables (e.g. N, P, K, Ca, Mg, pH
#         only). Compare PC1 loadings and % variance explained to the
#         full-variable PCA above. Which variables dominate PC1?
# TODO 2: Refit the PERMANOVA using Moisture instead of Management. Is the
#         pseudo-F larger or smaller than for Management? What does that imply?
# TODO 3: Re-run MDS with n_components=3 instead of 2. Does stress drop
#         substantially? Is the extra dimension worth the loss of a simple
#         2-D plot?
# TODO 4: Cut the hierarchical clustering dendrogram into 4 groups
#         (scipy.cluster.hierarchy.fcluster(Z, t=4, criterion="maxclust")) and
#         cross-tabulate against dune_env["Management"] with pd.crosstab(). Do
#         the cluster groups line up with the management categories?
