# Lecture 14 -- Population Modeling
# Structured (stage-based) matrix population models: Leslie/Lefkovitch
# matrices, projection, the dominant eigenvalue (lambda), the stable stage
# distribution, and elasticity analysis.
#
# SYSTEM: loggerhead sea turtle (Caretta caretta) stage-structured population,
# after Crouse, Crowder & Caswell (1987) "A stage-based population model for
# loggerhead sea turtles and implications for conservation," Ecology 68(5),
# 1412-1423.
#
# ---------------------------------------------------------------------------
# HONEST DATA PROVENANCE -- READ THIS BEFORE USING THESE NUMBERS FOR ANYTHING
# ---------------------------------------------------------------------------
# The 5x5 matrix below is a RECONSTRUCTION, not a transcription. It was built
# from memory to be representative of the stage structure, survival/growth
# regime, and qualitative conclusions of Crouse, Crowder & Caswell (1987) --
# a population dominated by low hatchling survival, increasing survival
# through larger juvenile/subadult stages, high adult survival, modest adult
# fecundity discounted by egg/hatchling mortality, and a resulting lambda
# slightly below 1 (a declining population under status-quo, pre-Turtle-
# Excluder-Device bycatch levels). The specific numeric entries are NOT
# claimed to match the published matrix. For the exact published values,
# consult the original paper: Crouse, Crowder & Caswell (1987), Ecology
# 68(5):1412-1423 (or Caswell's "Matrix Population Models" textbook, which
# reproduces it as a worked example).
# ---------------------------------------------------------------------------

if (!dir.exists("figures")) dir.create("figures", recursive = TRUE)

# --- 1. THE STAGE-STRUCTURED (LEFKOVITCH) PROJECTION MATRIX ----------------
# Stages: 1 Eggs/Hatchlings, 2 Small juveniles (pelagic), 3 Large juveniles
# (benthic), 4 Subadults, 5 Adults (breeding females).
#
# Off-diagonal subdiagonal entries = stasis (Pi) is on the diagonal, growth
# into the next stage (Gi) is on the subdiagonal below it -- standard
# Lefkovitch form for a stage-classified (not strictly age-classified)
# population, appropriate for sea turtles because growth rate to maturity
# varies substantially among individuals.
#
# Row 1 = fecundity contributions (eggs produced, already discounted to
# hatchlings) from subadults (small) and adults (larger, the main breeders).

stage_names <- c("Eggs/Hatchlings", "Small Juv", "Large Juv", "Subadult", "Adult")

A <- matrix(c(
  0.000, 0.000, 0.000, 1.000, 3.200,   # row 1: hatchling production
  0.675, 0.643, 0.000, 0.000, 0.000,   # row 2: egg->small juv survival; small juv stasis
  0.000, 0.107, 0.656, 0.000, 0.000,   # row 3: small->large juv growth; large juv stasis
  0.000, 0.000, 0.094, 0.667, 0.000,   # row 4: large juv->subadult growth; subadult stasis
  0.000, 0.000, 0.000, 0.133, 0.800    # row 5: subadult->adult growth; adult stasis
), nrow = 5, ncol = 5, byrow = TRUE,
   dimnames = list(stage_names, stage_names))

cat("Projection matrix A (Lefkovitch form, columns = stage at t, rows = stage at t+1):\n")
print(round(A, 3))

# --- 2. DOMINANT EIGENVALUE (lambda) AND STABLE STAGE DISTRIBUTION ---------
ev <- eigen(A)
dom_idx <- which.max(Re(ev$values))
lambda <- Re(ev$values[dom_idx])

# Right eigenvector for lambda = stable stage distribution once normalized
w <- Re(ev$vectors[, dom_idx])
w <- w / sum(w)
names(w) <- stage_names

cat(sprintf("\nDominant eigenvalue (asymptotic population growth rate) lambda = %.4f\n", lambda))
if (lambda < 1) {
  cat("  -> lambda < 1: population is projected to DECLINE at status-quo rates.\n")
} else {
  cat("  -> lambda >= 1: population is projected to grow or stay stable.\n")
}
cat("\nStable stage distribution (proportion of individuals in each stage once\n")
cat("the population settles into its long-run structure):\n")
print(round(w, 4))

# --- 3. PROJECT THE POPULATION FORWARD ~30 YEARS ----------------------------
n_years <- 30
# Arbitrary starting stage vector -- e.g. a small founder population skewed
# toward juveniles, as might be observed in a beach/in-water survey.
n0 <- c(`Eggs/Hatchlings` = 5000, `Small Juv` = 1200, `Large Juv` = 600,
        `Subadult` = 200, `Adult` = 100)

n_mat <- matrix(0, nrow = 5, ncol = n_years + 1, dimnames = list(stage_names, 0:n_years))
n_mat[, 1] <- n0
for (t in 1:n_years) {
  n_mat[, t + 1] <- A %*% n_mat[, t]
}
total_n <- colSums(n_mat)

cat(sprintf("\nTotal population size: year 0 = %.0f, year %d = %.0f (ratio = %.3f)\n",
            total_n[1], n_years, total_n[n_years + 1], total_n[n_years + 1] / total_n[1]))

# --- 4. FIGURE: population trajectory over the 30-year projection ----------
png("figures/lecture_14_population_trajectory.png", width = 1100, height = 650, res = 130)
par(mar = c(4.5, 5, 3, 1))
plot(0:n_years, total_n, type = "o", pch = 16, log = "y",
     xlab = "Year", ylab = "Total population size (log scale)",
     main = sprintf("Projected loggerhead population (lambda = %.3f)", lambda),
     col = "#8B2500", las = 1)
grid(col = "grey85")
dev.off()
cat("\nFigure saved to figures/lecture_14_population_trajectory.png\n")

# --- 5. ELASTICITY ANALYSIS -------------------------------------------------
# Elasticity of lambda to entry a_ij: the proportional change in lambda per
# proportional change in a_ij, evaluated numerically by finite difference
# (perturb one entry at a time, recompute lambda, no analytical eigenvector
# shortcut -- simple and transparent).

lambda_of <- function(mat) {
  vals <- eigen(mat, only.values = TRUE)$values
  Re(vals[which.max(Re(vals))])
}

lambda0 <- lambda_of(A)
rel_step <- 1e-4
E <- matrix(0, nrow = 5, ncol = 5, dimnames = list(stage_names, stage_names))

for (i in 1:5) {
  for (j in 1:5) {
    aij <- A[i, j]
    if (aij != 0) {
      A_pert <- A
      da <- rel_step * aij
      A_pert[i, j] <- aij + da
      lambda1 <- lambda_of(A_pert)
      E[i, j] <- (lambda1 - lambda0) / lambda0 / (da / aij)
    }
  }
}

cat("\nElasticity matrix (rows sum with columns to ~1.0 across all nonzero entries):\n")
print(round(E, 4))
cat(sprintf("Sum of all elasticities (should be ~1): %.4f\n", sum(E)))

# Rank nonzero entries by elasticity
E_df <- data.frame(
  from = rep(stage_names, each = 5),
  to   = rep(stage_names, times = 5),
  value = as.vector(A),
  elasticity = as.vector(E)
)
E_df <- E_df[E_df$value != 0, ]
E_df <- E_df[order(-E_df$elasticity), ]
rownames(E_df) <- NULL

cat("\nTop matrix entries ranked by elasticity:\n")
print(E_df)

fecundity_elasticity <- sum(E[1, ])
juvenile_survival_elasticity <- E["Small Juv", "Small Juv"] + E["Large Juv", "Small Juv"] +
  E["Large Juv", "Large Juv"] + E["Subadult", "Large Juv"] + E["Subadult", "Subadult"]

cat(sprintf("\nTotal fecundity elasticity (row 1, egg production): %.4f\n", fecundity_elasticity))
cat(sprintf("Total juvenile/subadult survival+growth elasticity: %.4f\n", juvenile_survival_elasticity))
cat("Interpretation: lambda is far more sensitive to juvenile/subadult survival\n")
cat("than to fecundity -- this is the core Crouse/Crowder/Caswell (1987) result\n")
cat("that redirected sea turtle conservation policy toward reducing bycatch\n")
cat("mortality (Turtle Excluder Devices) rather than protecting nests alone.\n")

# --- EXERCISES ---
# TODO 1: Increase small-juvenile and large-juvenile survival (the stasis
#         entries A[2,2] and A[3,3], and the growth entries A[3,2], A[4,3])
#         by 10%, simulating widespread Turtle Excluder Device (TED)
#         adoption reducing bycatch mortality in shrimp trawls. Recompute
#         lambda. How much does lambda change relative to a 10% increase in
#         fecundity (A[1,5]) instead? Which intervention gets the population
#         closer to lambda = 1?
# TODO 2: Compute the stable stage distribution from the matrix as given.
#         Suppose a hypothetical beach/in-water survey instead observed
#         proportions roughly c(0.10, 0.55, 0.20, 0.10, 0.05) across the five
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
#         weighted almost entirely toward adults (e.g.
#         c(100, 100, 100, 100, 5000)) instead of the juvenile-heavy starting
#         vector used above. Does the total population trajectory still
#         converge to the same asymptotic growth rate lambda? Plot both
#         trajectories on the same log-scale axes and describe what
#         differs in the first few years (transient dynamics) versus the
#         long run.
