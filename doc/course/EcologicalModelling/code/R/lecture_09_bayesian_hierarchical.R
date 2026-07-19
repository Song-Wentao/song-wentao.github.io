# ============================================================
# Lecture 9 -- Bayesian Hierarchical Models
# Ecological Modelling with R, Python, and Julia
#
# Dataset:
#   data/grouseticks.csv  (Elston, Moss, Boulinier, Arrowsmith &
#                          Lambin 2001, Parasitology 122:563-569)
#
#   403 red grouse chicks, TICKS (tick count) measured on each chick.
#   Chicks are nested within BROOD (118 broods), and broods are
#   nested within LOCATION (63 locations). HEIGHT/cHEIGHT is altitude
#   (centered). YEAR is 95/96/97.
#
# Continuity with Lecture 7:
#   Lecture 7 fit the frequentist Poisson GLMM
#     glmer(TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD), family=poisson)
#   and ended by noting that glmer's random effects already do
#   PARTIAL POOLING / shrinkage -- BLUPs for small broods are pulled
#   toward the population mean. This lecture fits the SAME model
#   structure fully Bayesian: the shrinkage becomes explicit
#   (posteriors for each LOCATION/BROOD effect), and uncertainty
#   propagates correctly through every level, including the variance
#   components themselves (which glmer treats as point estimates).
#
# Model:
#   TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD), family = poisson()
#
#   Priors (weakly informative, ecologically sensible defaults on the
#   log scale):
#     Intercept, YEAR, cHEIGHT coefficients ~ Normal(0, 5)
#     SD(LOCATION), SD(BROOD:LOCATION)      ~ default rstanarm
#                                              half-Cauchy-like decov()
#                                              prior (weakly informative,
#                                              analogous to Exponential(1)
#                                              /half-Cauchy choices
#                                              discussed in lecture)
#
# Backend note:
#   brms::brm() (which compiles a fresh Stan model via rstan/StanHeaders)
#   was tried first, as specified. In this sandboxed environment,
#   on-the-fly Stan compilation fails with "Boost not found" even
#   though the BH package is installed -- a known brittleness of
#   compiling Stan models on demand. rstanarm::stan_glmer() uses
#   Stan models that ship PRE-COMPILED with the package, so it sidesteps
#   compilation entirely and is used here instead; it fits exactly the
#   same Bayesian nested Poisson GLMM. (If brms compiles successfully
#   in your own environment, the call is a drop-in swap:
#   brm(TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD), data=dat,
#       family=poisson(), prior=c(set_prior("normal(0,5)", class="b"),
#       set_prior("normal(0,5)", class="Intercept"),
#       set_prior("exponential(1)", class="sd")),
#       chains=2, iter=1000, cores=1).)
#
# Numerical note on cHEIGHT:
#   cHEIGHT ranges roughly -59 to +71 on its native scale. Feeding
#   this directly into stan_glmer's default sampler (short warmup,
#   default step size) caused the chains to get stuck (near-zero
#   effective sample size, wildly inflated/absurd coefficients) --
#   a classic HMC pathology on badly-scaled predictors. Standardizing
#   cHEIGHT (z-score) before fitting fixes this cleanly; the
#   standardized coefficient is converted back to the original
#   cHEIGHT scale below for direct comparison with Lecture 7.
#
# Sampling kept modest (2 chains, 2000 iterations incl. 1000 warmup)
# so the script completes in a sandboxed environment without a large
# time budget (~25-30 seconds here). This is NOT enough for a
# publication-grade fit -- in practice run 4 chains x 2000+
# post-warmup iterations and check diagnostics before trusting the
# result.
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_09_bayesian_hierarchical.R
# ============================================================

dir.create("figures", showWarnings = FALSE)

suppressMessages(library(rstanarm))
options(mc.cores = 2)

## ------------------------------------------------------------
## 1. Load data, set factor types, standardize cHEIGHT for sampling
## ------------------------------------------------------------

dat <- read.csv("data/grouseticks.csv", stringsAsFactors = FALSE)

dat$BROOD    <- factor(dat$BROOD)
dat$LOCATION <- factor(dat$LOCATION)
dat$YEAR     <- factor(dat$YEAR)

cHEIGHT_mean <- mean(dat$cHEIGHT)
cHEIGHT_sd   <- sd(dat$cHEIGHT)
dat$cHEIGHT_s <- (dat$cHEIGHT - cHEIGHT_mean) / cHEIGHT_sd

cat("=== Lecture 9: Bayesian Hierarchical Models (R / rstanarm) ===\n\n")
cat("n chicks:   ", nrow(dat), "\n")
cat("n broods:   ", nlevels(dat$BROOD), "\n")
cat("n locations:", nlevels(dat$LOCATION), "\n\n")

## ------------------------------------------------------------
## 2. Fit: Bayesian nested Poisson hierarchical model
##    TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD)
##    -- rstanarm expands (1|LOCATION/BROOD) to
##       (1|LOCATION) + (1|LOCATION:BROOD), same as glmer in Lecture 7
## ------------------------------------------------------------

set.seed(42)
t0 <- Sys.time()

fit_bayes <- stan_glmer(
  TICKS ~ YEAR + cHEIGHT_s + (1 | LOCATION/BROOD),
  data    = dat,
  family  = poisson(),
  prior            = normal(0, 5),   # weakly informative: coefficients
  prior_intercept  = normal(0, 5),   #   +-5 on the log scale already
                                      #   spans an ~e^5-fold (~150x) effect
  chains  = 2,
  iter    = 2000,
  warmup  = 1000,
  seed    = 42,
  refresh = 0
)

cat(sprintf("\nSampling time: %.1f seconds\n\n", as.numeric(Sys.time() - t0, units = "secs")))

## ------------------------------------------------------------
## 3. Posterior summary
## ------------------------------------------------------------

cat("--- Posterior summary (stan_glmer fit) ---\n")
print(summary(fit_bayes, digits = 3))
cat("\n")

fe <- fixef(fit_bayes)
cat("Fixed effects (posterior median, standardized cHEIGHT scale):\n")
print(round(fe, 3))
cat("\n")

## Convert the standardized cHEIGHT coefficient back to the original
## (per-metre altitude) scale for comparison with Lecture 7
cHEIGHT_orig_scale <- fe["cHEIGHT_s"] / cHEIGHT_sd
cat(sprintf("cHEIGHT coefficient, back-transformed to original scale: %.4f\n\n",
            cHEIGHT_orig_scale))

## R-hat / ESS for the fixed effects
s <- summary(fit_bayes)
fe_names <- c("(Intercept)", "YEAR96", "YEAR97", "cHEIGHT_s")
cat("R-hat and effective sample size (fixed effects):\n")
print(round(s[fe_names, c("Rhat", "n_eff")], 3))
cat("\n")

re_var <- as.data.frame(VarCorr(fit_bayes))
cat("Random-effect SDs (posterior point estimate, LOCATION / BROOD:LOCATION):\n")
print(re_var[, c("grp", "sdcor")])
cat("\n")

## ------------------------------------------------------------
## 4. Compare to Lecture 7's frequentist glmer point estimates
##    (values hard-coded from Lecture 7's fitted model so this
##    script does not need lme4 as a dependency; re-derive with
##    glmer(TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD), family=poisson)
##    on the same data to confirm)
## ------------------------------------------------------------

glmer_est <- c(
  "Intercept" = 0.467,
  "YEAR96"    = 1.166,
  "YEAR97"    = -0.978,
  "cHEIGHT"   = -0.024
)
bayes_est <- c(
  fe["(Intercept)"], fe["YEAR96"], fe["YEAR97"], as.numeric(cHEIGHT_orig_scale)
)
names(bayes_est) <- names(glmer_est)

cmp <- data.frame(
  parameter     = names(glmer_est),
  glmer_L7      = as.numeric(glmer_est),
  bayes_L9_mean = round(as.numeric(bayes_est), 3)
)
cat("--- Lecture 7 (glmer) vs Lecture 9 (Bayesian posterior median) ---\n")
print(cmp)
cat("\nSame model structure, two philosophies -- point estimates are close.\n\n")

## ------------------------------------------------------------
## 5. Convergence diagnostics
## ------------------------------------------------------------

rhats <- s[, "Rhat"]
cat("Range of R-hat across all parameters:", round(range(rhats, na.rm = TRUE), 4), "\n")
cat("Any R-hat > 1.05?", any(rhats > 1.05, na.rm = TRUE), "\n\n")

## ------------------------------------------------------------
## 6. Figure: caterpillar plot of a sample of LOCATION-level
##    random-effect posterior estimates with credible intervals
## ------------------------------------------------------------

post <- as.matrix(fit_bayes)
loc_cols <- grep("^b\\[\\(Intercept\\) LOCATION:", colnames(post), value = TRUE)
loc_draws <- post[, loc_cols]
loc_ids <- sub("^b\\[\\(Intercept\\) LOCATION:([^]]+)\\]$", "\\1", loc_cols)

loc_summary <- data.frame(
  LOCATION = loc_ids,
  mean = apply(loc_draws, 2, mean),
  lo   = apply(loc_draws, 2, quantile, probs = 0.025),
  hi   = apply(loc_draws, 2, quantile, probs = 0.975)
)
loc_summary <- loc_summary[order(loc_summary$mean), ]

set.seed(42)
n_show <- min(20, nrow(loc_summary))
sample_idx <- round(seq(1, nrow(loc_summary), length.out = n_show))
plot_df <- loc_summary[sample_idx, ]

png("figures/lecture_09_posterior_LOCATION_effects.png",
    width = 1000, height = 800, res = 125)
par(mar = c(4.5, 6, 3, 1))
y_pos <- seq_len(nrow(plot_df))
plot(plot_df$mean, y_pos,
     xlim = range(c(plot_df$lo, plot_df$hi)),
     yaxt = "n", ylab = "", xlab = "Posterior LOCATION random effect (log scale)",
     main = "Bayesian posterior LOCATION effects\n(posterior mean + 95% credible interval)",
     pch = 19, col = "#3b7ea1")
segments(plot_df$lo, y_pos, plot_df$hi, y_pos, col = "#3b7ea1", lwd = 2)
axis(2, at = y_pos, labels = plot_df$LOCATION, las = 2, cex.axis = 0.8)
abline(v = 0, lty = 2, col = "grey40")
dev.off()

cat("Figure saved: figures/lecture_09_posterior_LOCATION_effects.png\n")


# --- EXERCISES ---
# 1. Change the prior on the LOCATION/BROOD random-effect SDs -- e.g.
#    swap rstanarm's default decov() prior for prior_covariance =
#    decov(regularization = 2, concentration = 1, shape = 1, scale = 0.5)
#    (a tighter prior pulling SDs toward smaller values), refit, and
#    compare the posterior SD estimates to the original fit.
# 2. Inspect summary(fit_bayes) in detail -- are there any parameters
#    with Rhat > 1.05 or n_eff < 400? Use bayesplot::mcmc_trace() on
#    as.array(fit_bayes) to view trace plots for the fixed effects.
# 3. Add a random slope for cHEIGHT_s by LOCATION, i.e.
#    TICKS ~ YEAR + cHEIGHT_s + (1 + cHEIGHT_s | LOCATION/BROOD),
#    refit, and compare to the random-intercept-only model with
#    loo(fit_bayes).
# 4. Compute and plot the 95% credible interval for the YEAR97 effect
#    exponentiated to the rate-ratio scale (exp of the posterior
#    draws in as.matrix(fit_bayes)[, "YEAR97"]), and compare its
#    width and interpretation to the 95% confidence interval
#    Lecture 7's glmer produced for the same coefficient.
