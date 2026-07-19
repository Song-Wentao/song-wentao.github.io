"""
Lecture 14 -- Population Modeling
Structured (stage-based) matrix population models: Leslie/Lefkovitch
matrices, projection, the dominant eigenvalue (lambda), the stable stage
distribution, and elasticity analysis.

SYSTEM: loggerhead sea turtle (Caretta caretta) stage-structured population,
after Crouse, Crowder & Caswell (1987) "A stage-based population model for
loggerhead sea turtles and implications for conservation," Ecology 68(5),
1412-1423.

---------------------------------------------------------------------------
HONEST DATA PROVENANCE -- READ THIS BEFORE USING THESE NUMBERS FOR ANYTHING
---------------------------------------------------------------------------
The 5x5 matrix below is a RECONSTRUCTION, not a transcription. It was built
from memory to be representative of the stage structure, survival/growth
regime, and qualitative conclusions of Crouse, Crowder & Caswell (1987) --
a population dominated by low hatchling survival, increasing survival
through larger juvenile/subadult stages, high adult survival, modest adult
fecundity discounted by egg/hatchling mortality, and a resulting lambda
slightly below 1 (a declining population under status-quo, pre-Turtle-
Excluder-Device bycatch levels). The specific numeric entries are NOT
claimed to match the published matrix. For the exact published values,
consult the original paper: Crouse, Crowder & Caswell (1987), Ecology
68(5):1412-1423 (or Caswell's "Matrix Population Models" textbook, which
reproduces it as a worked example).
---------------------------------------------------------------------------
"""

import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

os.makedirs("figures", exist_ok=True)

# --- 1. THE STAGE-STRUCTURED (LEFKOVITCH) PROJECTION MATRIX ----------------
# Stages: 1 Eggs/Hatchlings, 2 Small juveniles (pelagic), 3 Large juveniles
# (benthic), 4 Subadults, 5 Adults (breeding females).
#
# Stasis (Pi) on the diagonal, growth into the next stage (Gi) on the
# subdiagonal below it -- standard Lefkovitch form for a stage-classified
# (not strictly age-classified) population, appropriate for sea turtles
# because growth rate to maturity varies substantially among individuals.
#
# Row 0 = fecundity contributions (eggs produced, already discounted to
# hatchlings) from subadults (small) and adults (larger, the main breeders).

stage_names = ["Eggs/Hatchlings", "Small Juv", "Large Juv", "Subadult", "Adult"]

A = np.array([
    [0.000, 0.000, 0.000, 1.000, 3.200],   # row 0: hatchling production
    [0.675, 0.643, 0.000, 0.000, 0.000],   # row 1: egg->small juv survival; small juv stasis
    [0.000, 0.107, 0.656, 0.000, 0.000],   # row 2: small->large juv growth; large juv stasis
    [0.000, 0.000, 0.094, 0.667, 0.000],   # row 3: large juv->subadult growth; subadult stasis
    [0.000, 0.000, 0.000, 0.133, 0.800],   # row 4: subadult->adult growth; adult stasis
])

print("Projection matrix A (Lefkovitch form, columns = stage at t, rows = stage at t+1):")
print(pd.DataFrame(A, index=stage_names, columns=stage_names).round(3))

# --- 2. DOMINANT EIGENVALUE (lambda) AND STABLE STAGE DISTRIBUTION ---------
eigvals, eigvecs = np.linalg.eig(A)
dom_idx = np.argmax(np.real(eigvals))
lam = np.real(eigvals[dom_idx])

w = np.real(eigvecs[:, dom_idx])
w = w / w.sum()

print(f"\nDominant eigenvalue (asymptotic population growth rate) lambda = {lam:.4f}")
if lam < 1:
    print("  -> lambda < 1: population is projected to DECLINE at status-quo rates.")
else:
    print("  -> lambda >= 1: population is projected to grow or stay stable.")

print("\nStable stage distribution (proportion of individuals in each stage once")
print("the population settles into its long-run structure):")
print(pd.Series(w, index=stage_names).round(4))

# --- 3. PROJECT THE POPULATION FORWARD ~30 YEARS ----------------------------
n_years = 30
# Arbitrary starting stage vector -- e.g. a small founder population skewed
# toward juveniles, as might be observed in a beach/in-water survey.
n0 = np.array([5000, 1200, 600, 200, 100], dtype=float)

n_mat = np.zeros((5, n_years + 1))
n_mat[:, 0] = n0
for t in range(n_years):
    n_mat[:, t + 1] = A @ n_mat[:, t]

total_n = n_mat.sum(axis=0)
print(f"\nTotal population size: year 0 = {total_n[0]:.0f}, year {n_years} = "
      f"{total_n[-1]:.0f} (ratio = {total_n[-1] / total_n[0]:.3f})")

# --- 4. FIGURE: population trajectory over the 30-year projection ----------
fig, ax = plt.subplots(figsize=(9, 5.5))
ax.semilogy(range(n_years + 1), total_n, "o-", color="#8B2500")
ax.set_xlabel("Year")
ax.set_ylabel("Total population size (log scale)")
ax.set_title(f"Projected loggerhead population (lambda = {lam:.3f})")
ax.grid(True, which="both", alpha=0.3)
fig.tight_layout()
fig.savefig("figures/lecture_14_population_trajectory.png", dpi=130)
plt.close(fig)
print("\nFigure saved to figures/lecture_14_population_trajectory.png")

# --- 5. ELASTICITY ANALYSIS -------------------------------------------------
# Elasticity of lambda to entry a_ij: the proportional change in lambda per
# proportional change in a_ij, evaluated numerically by finite difference
# (perturb one entry at a time, recompute lambda, no analytical eigenvector
# shortcut -- simple and transparent).


def lambda_of(mat):
    vals = np.linalg.eigvals(mat)
    return np.real(vals[np.argmax(np.real(vals))])


lambda0 = lambda_of(A)
rel_step = 1e-4
E = np.zeros_like(A)

for i in range(5):
    for j in range(5):
        aij = A[i, j]
        if aij != 0:
            A_pert = A.copy()
            da = rel_step * aij
            A_pert[i, j] = aij + da
            lambda1 = lambda_of(A_pert)
            E[i, j] = (lambda1 - lambda0) / lambda0 / (da / aij)

print("\nElasticity matrix (all nonzero entries sum to ~1.0):")
print(pd.DataFrame(E, index=stage_names, columns=stage_names).round(4))
print(f"Sum of all elasticities (should be ~1): {E.sum():.4f}")

records = []
for i in range(5):
    for j in range(5):
        if A[i, j] != 0:
            records.append({
                "from": stage_names[i], "to": stage_names[j],
                "value": A[i, j], "elasticity": E[i, j],
            })
E_df = pd.DataFrame(records).sort_values("elasticity", ascending=False).reset_index(drop=True)

print("\nTop matrix entries ranked by elasticity:")
print(E_df)

fecundity_elasticity = E[0, :].sum()
juvenile_survival_elasticity = (
    E[1, 1] + E[2, 1] + E[2, 2] + E[3, 2] + E[3, 3]
)

print(f"\nTotal fecundity elasticity (row 0, egg production): {fecundity_elasticity:.4f}")
print(f"Total juvenile/subadult survival+growth elasticity: {juvenile_survival_elasticity:.4f}")
print("Interpretation: lambda is far more sensitive to juvenile/subadult survival")
print("than to fecundity -- this is the core Crouse/Crowder/Caswell (1987) result")
print("that redirected sea turtle conservation policy toward reducing bycatch")
print("mortality (Turtle Excluder Devices) rather than protecting nests alone.")

# --- EXERCISES ---
# TODO 1: Increase small-juvenile and large-juvenile survival (the stasis
#         entries A[1,1] and A[2,2], and the growth entries A[2,1], A[3,2])
#         by 10%, simulating widespread Turtle Excluder Device (TED)
#         adoption reducing bycatch mortality in shrimp trawls. Recompute
#         lambda. How much does lambda change relative to a 10% increase in
#         fecundity (A[0,4]) instead? Which intervention gets the population
#         closer to lambda = 1?
# TODO 2: Compute the stable stage distribution from the matrix as given.
#         Suppose a hypothetical beach/in-water survey instead observed
#         proportions roughly [0.10, 0.55, 0.20, 0.10, 0.05] across the five
#         stages. Compare this "observed" distribution to the stable stage
#         distribution -- is the real population closer to or farther from
#         its stable structure, and what would you expect to happen to total
#         population growth in the short term (transient dynamics) before it
#         settles toward the asymptotic lambda?
# TODO 3: Identify the single nonzero matrix entry with the highest
#         elasticity from the E_df table above. Is it a fecundity term, a
#         stasis (survival-in-place) term, or a growth (transition) term?
#         Explain in a sentence or two why a small proportional change in
#         that entry has an outsized effect on lambda.
# TODO 4: Re-run the 30-year projection starting from a population vector
#         weighted almost entirely toward adults (e.g. [100, 100, 100, 100,
#         5000]) instead of the juvenile-heavy starting vector used above.
#         Does the total population trajectory still converge to the same
#         asymptotic growth rate lambda? Plot both trajectories on the same
#         log-scale axes and describe what differs in the first few years
#         (transient dynamics) versus the long run.
