# generate_crossbill_data.R
#
# Generates a SIMULATED single-season occupancy dataset for Lecture 11.
#
# HONESTY NOTE (see also lecture slides "Data provenance" slide):
# This sandbox has no general internet access (only pypi.org/apt mirrors are
# reachable), so the real "crossbill" repeat-visit survey data bundled with
# the R package `unmarked` (data(crossbill), from the Swiss breeding bird
# survey MHB, Schmid, Zbinden & Keller 2004, Swiss Ornithological Institute)
# could not be downloaded. Instead we SIMULATE a dataset with the same
# design (site-level elevation covariate, 3 repeat visits, visit-level date
# covariate) and with occupancy/detection probabilities calibrated to the
# ranges reported for this survey system in:
#   - Schmid, Zbinden & Keller (2004), Swiss Ornithological Institute MHB report
#   - Royle & Kery (2007) Ecology 88(7):1813-1823, "A Bayesian state-space
#     formulation of dynamic occupancy models" (willow tit / crossbill system)
#   - Kery & Royle (2016), "Applied Hierarchical Modeling in Ecology" Vol 1,
#     Chapter 10 (uses the same crossbill dataset for occu() examples)
# Occupancy probability psi ranges ~0.3-0.6 depending on elevation;
# detection probability p ranges ~0.4-0.7 depending on survey date.
# The modeling code in the lecture is IDENTICAL to what you would run on
# the real data via data(crossbill) in `unmarked`.
#
# Fixed seed -> fully reproducible.

set.seed(11042004)  # nod to Schmid/Zbinden/Keller 2004

n_site <- 200
n_visit <- 3

# Site-level covariate: elevation (m), standardized like in Kery & Royle examples
elevation_raw <- runif(n_site, 500, 2250)
elevation_z <- as.numeric(scale(elevation_raw))

# True occupancy probability model: psi ~ elevation (quadratic-ish hump,
# crossbills favor mid-to-high conifer forest elevations), calibrated so
# mean psi across sites is in the 0.3-0.6 range as reported in the source
# studies.
beta0 <- -0.3   # intercept on logit scale
beta1 <- 0.9    # linear elevation effect
psi <- plogis(beta0 + beta1 * elevation_z)

# True occupancy state z_i
z <- rbinom(n_site, 1, psi)

# Visit-level covariate: survey date (day of season, standardized)
date_raw <- matrix(runif(n_site * n_visit, 1, 60), nrow = n_site, ncol = n_visit)
date_z <- matrix(as.numeric(scale(as.vector(date_raw))), nrow = n_site, ncol = n_visit)

# Detection probability model: p ~ date (detectability declines somewhat
# later in season as singing activity drops), calibrated to 0.4-0.7 range
alpha0 <- 0.4    # intercept on logit scale -> p ~ 0.6 at avg date
alpha1 <- -0.35  # date effect
p_mat <- plogis(alpha0 + alpha1 * date_z)

# Observation process: y_ij ~ Bernoulli(z_i * p_ij)
det_mat <- matrix(NA_integer_, nrow = n_site, ncol = n_visit)
for (i in 1:n_site) {
  for (j in 1:n_visit) {
    det_mat[i, j] <- rbinom(1, 1, z[i] * p_mat[i, j])
  }
}

# Introduce a few missing visits (realistic field-survey missingness, ~3%)
miss_idx <- sample(seq_len(n_site * n_visit), size = round(0.03 * n_site * n_visit))
det_vec <- as.vector(det_mat)
date_vec <- as.vector(date_raw)
det_vec[miss_idx] <- NA
date_vec[miss_idx] <- NA
det_mat <- matrix(det_vec, nrow = n_site, ncol = n_visit)
date_raw <- matrix(date_vec, nrow = n_site, ncol = n_visit)

df <- data.frame(
  site = 1:n_site,
  elevation = round(elevation_raw, 1),
  det1 = det_mat[, 1], det2 = det_mat[, 2], det3 = det_mat[, 3],
  date1 = round(date_raw[, 1], 1), date2 = round(date_raw[, 2], 1), date3 = round(date_raw[, 3], 1)
)

dir.create("data", showWarnings = FALSE)
write.csv(df, "data/crossbill_occupancy_sim.csv", row.names = FALSE)

cat(sprintf("Wrote data/crossbill_occupancy_sim.csv: %d sites, %d visits\n", n_site, n_visit))
cat(sprintf("True mean psi (simulation target): %.3f\n", mean(psi)))
cat(sprintf("Realized true occupancy (mean z): %.3f\n", mean(z)))
