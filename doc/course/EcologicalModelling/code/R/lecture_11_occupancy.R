# =============================================================================
# Lecture 11 -- Occupancy and N-mixture Models
# Ecological Modelling with R, Python, and Julia
# =============================================================================
#
# DATA PROVENANCE (read this first):
# data/crossbill_occupancy_sim.csv is SIMULATED, not raw field data. This
# sandbox has no general internet access (only pypi.org and the apt mirror
# are reachable) so the real "crossbill" repeat-visit dataset bundled with
# the R package `unmarked` (data(crossbill); Swiss breeding bird survey MHB,
# Schmid, Zbinden & Keller 2004, Swiss Ornithological Institute) could not be
# downloaded. The simulation (code/R/generate_crossbill_data.R, seed
# 11042004) reproduces the same design -- 200 sites, 3 repeat visits, a
# site-level elevation covariate on occupancy (psi), a visit-level date
# covariate on detection (p) -- with probabilities calibrated to the ranges
# reported in Schmid, Zbinden & Keller (2004) and Royle & Kery (2007,
# Ecology 88(7):1813-1823): psi ~ 0.3-0.6, p ~ 0.4-0.7. The modeling code
# below is IDENTICAL in structure to what you would run on the real
# `data(crossbill)` object.
#
# unmarked AVAILABILITY: attempted `install.packages("unmarked")` from CRAN
# and `apt-get install r-cran-unmarked` in this environment -- both failed
# (no general network access; package not in the apt mirror). The canonical
# `unmarked::occu()` call is shown below as a comment for reference/use on a
# machine with internet access. The code that actually RUNS in this script
# is a hand-rolled maximum-likelihood fit via optim(), using the same
# closed-form marginal likelihood that occu() maximizes internally. This
# keeps R, Python, and Julia comparably rigorous in this offline sandbox.
# =============================================================================

set.seed(11042004)

df <- read.csv("data/crossbill_occupancy_sim.csv")
n_site  <- nrow(df)
det_cols  <- c("det1", "det2", "det3")
date_cols <- c("date1", "date2", "date3")
n_visit <- length(det_cols)

Y    <- as.matrix(df[, det_cols])
DATE <- as.matrix(df[, date_cols])
ELEV <- df$elevation

# Standardize covariates (as in the simulation / as recommended practice)
elev_z <- as.numeric(scale(ELEV))
date_z <- matrix(as.numeric(scale(as.vector(DATE))), nrow = n_site, ncol = n_visit)

# -----------------------------------------------------------------------
# 1. Naive occupancy: proportion of sites with >=1 detection across visits
# -----------------------------------------------------------------------
any_detect <- apply(Y, 1, function(row) any(row == 1, na.rm = TRUE))
naive_occupancy <- mean(any_detect)
cat(sprintf("Naive occupancy (proportion of sites with >=1 detection): %.3f\n", naive_occupancy))

# -----------------------------------------------------------------------
# 2. Single-season occupancy model: psi ~ elevation, p ~ date
#    Fit via unmarked (reference code, not run here -- package unavailable):
#
#    library(unmarked)
#    umf <- unmarkedFrameOccu(
#      y = Y,
#      siteCovs = data.frame(elevation = elev_z),
#      obsCovs  = list(date = date_z)
#    )
#    fm <- occu(~ date ~ elevation, data = umf)
#    summary(fm)
#    psi_hat <- predict(fm, type = "state")$Predicted
#
#    Below: hand-rolled MLE of the same model via optim(), maximizing the
#    marginal likelihood with the true occupancy state z_i integrated out:
#
#    L_i = psi_i * prod_j p_ij^{y_ij} (1-p_ij)^{1-y_ij}          if any y_ij==1
#        = psi_i * prod_j (1-p_ij) + (1 - psi_i)                  if all y_ij==0
#
#    (missing visits, NA, are simply dropped from the product for that site)
# -----------------------------------------------------------------------

neg_log_lik <- function(par, Y, elev_z, date_z) {
  b0 <- par[1]; b1 <- par[2]   # occupancy (psi) coefficients
  a0 <- par[3]; a1 <- par[4]   # detection (p) coefficients

  psi <- plogis(b0 + b1 * elev_z)
  n <- nrow(Y); J <- ncol(Y)
  ll <- numeric(n)

  for (i in 1:n) {
    obs <- !is.na(Y[i, ])
    if (!any(obs)) { ll[i] <- 0; next }  # no data at this site: drop (contributes 0 to log-lik)
    p_ij <- plogis(a0 + a1 * date_z[i, obs])
    y_ij <- Y[i, obs]

    if (any(y_ij == 1)) {
      lik <- psi[i] * prod(p_ij^y_ij * (1 - p_ij)^(1 - y_ij))
    } else {
      lik <- psi[i] * prod(1 - p_ij) + (1 - psi[i])
    }
    ll[i] <- log(max(lik, 1e-12))
  }
  -sum(ll)
}

start <- c(b0 = 0, b1 = 0, a0 = 0, a1 = 0)
fit <- optim(start, neg_log_lik, Y = Y, elev_z = elev_z, date_z = date_z,
             method = "BFGS", hessian = TRUE)

coef_hat <- fit$par
se_hat <- sqrt(diag(solve(fit$hessian)))

cat("\nMLE coefficients (logit scale):\n")
res_tab <- data.frame(
  param = c("psi_intercept", "psi_elevation", "p_intercept", "p_date"),
  estimate = round(coef_hat, 4),
  se = round(se_hat, 4)
)
print(res_tab)

# Model-estimated occupancy: mean of predicted psi_i across all sites
psi_hat_site <- plogis(coef_hat[1] + coef_hat[2] * elev_z)
model_occupancy <- mean(psi_hat_site)

cat(sprintf("\nModel-estimated occupancy (mean psi_hat across sites): %.3f\n", model_occupancy))
cat(sprintf("Naive occupancy                                       : %.3f\n", naive_occupancy))
cat(sprintf("Correction for imperfect detection (model - naive)    : +%.3f\n",
            model_occupancy - naive_occupancy))

# -----------------------------------------------------------------------
# 3. Figure: naive vs model-estimated occupancy, and psi_hat vs elevation
# -----------------------------------------------------------------------
dir.create("figures", showWarnings = FALSE)
png("figures/lecture_11_naive_vs_estimated_occupancy.png", width = 1400, height = 700, res = 130)
par(mfrow = c(1, 2), mar = c(5, 5, 3, 1))

bp <- barplot(c(naive_occupancy, model_occupancy),
              names.arg = c("Naive\n(>=1 detection)", "Model-estimated\n(psi, detection-corrected)"),
              col = c("#a6a6a6", "#2c7fb8"), ylim = c(0, 1),
              ylab = "Occupancy proportion",
              main = "Naive vs Model-Estimated Occupancy")
text(bp, c(naive_occupancy, model_occupancy) + 0.04,
     labels = sprintf("%.2f", c(naive_occupancy, model_occupancy)))

ord <- order(elev_z)
plot(ELEV[ord], psi_hat_site[ord], type = "l", lwd = 2, col = "#2c7fb8",
     xlab = "Elevation (m)", ylab = expression(hat(psi)),
     main = expression(paste("Estimated ", psi, " vs Elevation")), ylim = c(0, 1))
rug(ELEV)
dev.off()

cat("\nSaved figures/lecture_11_naive_vs_estimated_occupancy.png\n")

# =============================================================================
# --- EXERCISES ---
# See exercises/lecture_11_exercises.md. TODOs to implement here:
# 1. TODO: Re-simulate the dataset (or subset detection columns) at lower and
#    higher true detection probability (e.g. modify alpha0 in
#    generate_crossbill_data.R) and recompute naive vs model-estimated
#    occupancy for each; compare how the gap changes.
# 2. TODO: Add a quadratic elevation term to psi (b0 + b1*elev_z + b2*elev_z^2)
#    in neg_log_lik and re-fit with optim(); compare AIC (2*k - 2*logLik) to
#    the linear model.
# 3. TODO: Refit using only det_cols[1:2] / date_cols[1:2] (drop the third
#    visit) and compare coefficient estimates and standard errors to the
#    3-visit fit -- what happens to identifiability/precision?
# 4. TODO: Simulate a single-visit-only dataset (J=1) and show empirically
#    that psi and p become non-identifiable (try fitting neg_log_lik on it).
# =============================================================================
