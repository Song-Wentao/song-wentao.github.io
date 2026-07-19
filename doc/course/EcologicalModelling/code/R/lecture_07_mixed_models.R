# ============================================================
# Lecture 7 -- Mixed-Effects Models
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
#   This is THE canonical real dataset for teaching GLMMs with
#   nested random effects in ecology -- used by Elston et al. (2001)
#   themselves to demonstrate overdispersion/non-independence, and
#   subsequently by Zuur et al. (2009, "Mixed Effects Models and
#   Extensions in Ecology with R") and Bolker et al. (2009, TREE,
#   "Generalized linear mixed models: a practical guide for ecology
#   and evolution") as the worked GLMM example.
#
# Motivation (picking up from Lecture 6):
#   Chicks from the same BROOD share a mother, a nest, and a
#   microhabitat; broods from the same LOCATION share climate and
#   tick exposure. Treating all 403 chicks as independent
#   observations (as a plain GLM would) is PSEUDOREPLICATION -- it
#   understates uncertainty and can bias standard errors. Mixed
#   models add random effects for BROOD and LOCATION to account for
#   this non-independence.
#
# Models fit:
#   1. LMM intuition:  lmer(log1p(TICKS) ~ YEAR + cHEIGHT + (1|LOCATION/BROOD))
#   2. Poisson GLMM (nested):  glmer(TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD), family=poisson)
#   3. Poisson GLMM (crossed, for comparison): (1|LOCATION) + (1|BROOD)
#   4. ICC (variance partition coefficient) from variance components
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_07_mixed_models.R
# ============================================================

dir.create("figures", showWarnings = FALSE)

suppressMessages(library(lme4))

## ------------------------------------------------------------
## 1. Load data, set factor types
## ------------------------------------------------------------

dat <- read.csv("data/grouseticks.csv", stringsAsFactors = FALSE)

dat$BROOD    <- factor(dat$BROOD)
dat$LOCATION <- factor(dat$LOCATION)
dat$YEAR     <- factor(dat$YEAR)

cat("=== Lecture 7: Mixed-Effects Models (R) ===\n\n")
cat("n chicks:   ", nrow(dat), "\n")
cat("n broods:   ", nlevels(dat$BROOD), "\n")
cat("n locations:", nlevels(dat$LOCATION), "\n")
cat("TICKS range:", range(dat$TICKS), " mean:", round(mean(dat$TICKS), 2), "\n\n")

## Quick illustration of non-independence: mean TICKS varies a lot
## brood-to-brood and location-to-location -- this is exactly the
## structure a random effect is meant to soak up.
brood_means <- aggregate(TICKS ~ BROOD, data = dat, FUN = mean)
cat("Spread of brood-level mean TICKS: range",
    round(range(brood_means$TICKS), 2), " sd", round(sd(brood_means$TICKS), 2), "\n\n")

## ------------------------------------------------------------
## 2. LMM intuition: log1p(TICKS) as a (roughly) Gaussian response
##    -- a stepping stone before jumping to the Poisson GLMM
## ------------------------------------------------------------

dat$logTICKS <- log1p(dat$TICKS)

fit_lmm <- lmer(logTICKS ~ YEAR + cHEIGHT + (1 | LOCATION/BROOD), data = dat)

cat("--- LMM (Gaussian, log1p(TICKS)):",
    "logTICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD) ---\n")
print(summary(fit_lmm))
cat("\n")

## ------------------------------------------------------------
## 3. Poisson GLMM, nested random effects (the "right" model)
##    (1 | LOCATION/BROOD) expands to (1|LOCATION) + (1|LOCATION:BROOD)
##    -- appropriate because BROOD ids are only meaningful within a
##    LOCATION (brood 501 at location A is not "the same brood" as
##    an unrelated brood that happens to share a number elsewhere;
##    here BROOD codes are in fact unique across LOCATIONs already,
##    so nested and crossed notation give numerically identical fits
##    -- see Section 4).
## ------------------------------------------------------------

fit_glmm_nested <- glmer(
  TICKS ~ YEAR + cHEIGHT + (1 | LOCATION/BROOD),
  data = dat, family = poisson
)

cat("--- Poisson GLMM (nested): TICKS ~ YEAR + cHEIGHT + (1|LOCATION/BROOD) ---\n")
print(summary(fit_glmm_nested))
cat("\n")

## Fixed effects table on its own
cat("Fixed effects (log scale):\n")
print(round(fixef(fit_glmm_nested), 3))
cat("\nFixed effects (rate ratio scale, exp of coefficients):\n")
print(round(exp(fixef(fit_glmm_nested)), 3))
cat("\n")

## Variance components
vc_nested <- as.data.frame(VarCorr(fit_glmm_nested))
cat("Variance components (nested model):\n")
print(vc_nested[, c("grp", "vcov", "sdcor")])
cat("\n")

## ------------------------------------------------------------
## 4. Poisson GLMM, crossed random effects, for comparison
##    (1|LOCATION) + (1|BROOD) treats BROOD as crossed with LOCATION
##    rather than nested inside it. Because every BROOD code in this
##    dataset in fact belongs to exactly one LOCATION (BROOD is
##    already a globally unique id, not re-used across locations),
##    the crossed and nested specifications are mathematically
##    equivalent here and should return (near-)identical variance
##    components and log-likelihoods. This equivalence would break
##    down -- and (1|LOCATION/BROOD) or the explicit
##    (1|LOCATION) + (1|LOCATION:BROOD) form would be REQUIRED --
##    if BROOD ids were re-used across different locations.
## ------------------------------------------------------------

fit_glmm_crossed <- glmer(
  TICKS ~ YEAR + cHEIGHT + (1 | LOCATION) + (1 | BROOD),
  data = dat, family = poisson
)

cat("--- Poisson GLMM (crossed): TICKS ~ YEAR + cHEIGHT + (1|LOCATION) + (1|BROOD) ---\n")
print(summary(fit_glmm_crossed))
cat("\n")

vc_crossed <- as.data.frame(VarCorr(fit_glmm_crossed))
cat("Variance components (crossed model):\n")
print(vc_crossed[, c("grp", "vcov", "sdcor")])
cat("\n")

cat("logLik nested: ", round(as.numeric(logLik(fit_glmm_nested)), 3),
    "  logLik crossed:", round(as.numeric(logLik(fit_glmm_crossed)), 3), "\n")
cat("AIC nested:    ", round(AIC(fit_glmm_nested), 2),
    "  AIC crossed:   ", round(AIC(fit_glmm_crossed), 2), "\n")
cat("(Near-identical, as expected: BROOD ids are unique across LOCATIONs,\n",
    "so nested and crossed notation describe the same grouping structure here.)\n\n")

## ------------------------------------------------------------
## 5. Intraclass correlation / variance partition coefficient
##    On the latent (log) scale: how much of the random-effect
##    variance sits at LOCATION vs BROOD (within LOCATION)?
## ------------------------------------------------------------

var_location <- vc_nested$vcov[vc_nested$grp == "LOCATION"]
var_brood    <- vc_nested$vcov[vc_nested$grp == "BROOD:LOCATION"]

## For a Poisson GLMM with log link, the residual (observation-level)
## variance on the latent scale is commonly approximated as the
## "distribution-specific" variance for a log link, trigamma(1) is
## used for NB; for Poisson, a simple and widely used rough
## approximation adds log(1/mean(mu) + 1) (Nakagawa & Schielzeth 2013)
## or, more simply still, uses pi^2/3 for a rough logit-style
## approximation. We report the simplest, most transparent version:
## the proportion of *random-effect* variance attributable to each
## grouping level (ignoring residual variance), which is the
## conventional first pass for nested count GLMMs.

icc_location_of_total_re <- var_location / (var_location + var_brood)
icc_brood_of_total_re    <- var_brood / (var_location + var_brood)

cat("--- ICC (share of random-effect variance) ---\n")
cat(sprintf("  Var(LOCATION) = %.4f\n", var_location))
cat(sprintf("  Var(BROOD within LOCATION) = %.4f\n", var_brood))
cat(sprintf("  Share of RE variance at LOCATION level: %.1f%%\n",
            100 * icc_location_of_total_re))
cat(sprintf("  Share of RE variance at BROOD level:    %.1f%%\n",
            100 * icc_brood_of_total_re))

## A fuller ICC that also includes a Poisson-log-link residual-variance
## approximation (Nakagawa, Johnson & Schielzeth 2017): add
## log(1 + 1/exp(mean(eta))) as the distribution-specific variance.
mu_hat <- mean(predict(fit_glmm_nested, type = "link"))
var_resid_approx <- log(1 + 1 / exp(mu_hat))
var_total_approx <- var_location + var_brood + var_resid_approx

cat(sprintf(
  "\n  With Poisson-log residual variance approx (%.4f) included:\n",
  var_resid_approx))
cat(sprintf("  ICC(LOCATION) = %.3f   ICC(BROOD) = %.3f\n\n",
            var_location / var_total_approx, var_brood / var_total_approx))

## ------------------------------------------------------------
## 6. Shrinkage / partial pooling: compare raw brood means to the
##    model's BLUPs (best linear unbiased predictors) for a sample
##    of broods -- small/extreme broods get pulled toward the
##    population mean. This is the conceptual bridge to full
##    Bayesian hierarchical models in Lecture 9.
## ------------------------------------------------------------

brood_re <- ranef(fit_glmm_nested)$`BROOD:LOCATION`
cat("Random-effect (BLUP) range across broods (log scale):",
    round(range(brood_re[, 1]), 3), "\n")
cat("Broods with few chicks shrink further toward 0 than broods with many chicks.\n\n")

## ------------------------------------------------------------
## 7. Figure: mean TICKS across a sample of LOCATIONs, illustrating
##    between-location variance that the random effect is modeling
## ------------------------------------------------------------

loc_means <- aggregate(TICKS ~ LOCATION, data = dat, FUN = mean)
loc_means <- loc_means[order(loc_means$TICKS), ]

set.seed(42)
sample_locs <- loc_means$LOCATION[
  round(seq(1, nrow(loc_means), length.out = min(20, nrow(loc_means))))
]
plot_dat <- loc_means[loc_means$LOCATION %in% sample_locs, ]

png("figures/lecture_07_ticks_by_location_brood.png",
    width = 1000, height = 700, res = 125)
par(mar = c(7, 4.5, 3, 1))
bp <- barplot(plot_dat$TICKS, names.arg = plot_dat$LOCATION,
              las = 2, col = "#3b7ea1", border = NA,
              ylab = "Mean TICKS per chick",
              xlab = "", main = "Mean tick count varies sharply by LOCATION")
mtext("LOCATION (sample of 20)", side = 1, line = 5.5)
abline(h = mean(dat$TICKS), lty = 2, col = "grey30")
legend("topleft", legend = "overall mean", lty = 2, col = "grey30", bty = "n")
dev.off()

cat("Figure saved: figures/lecture_07_ticks_by_location_brood.png\n")

## ------------------------------------------------------------
## Convergence note
## ------------------------------------------------------------
## glmer() may print a "singular fit" or convergence warning for
## these models -- expected with modest group counts / small
## variance components, and does not indicate the analysis failed.
## Inspect isSingular() and the variance components before worrying.
cat("\nisSingular(fit_glmm_nested):", isSingular(fit_glmm_nested), "\n")


# --- EXERCISES ---
# 1. Add a random slope for cHEIGHT by LOCATION, i.e.
#    (1 + cHEIGHT | LOCATION/BROOD) or (cHEIGHT | LOCATION) + (1|BROOD),
#    and compare AIC to the random-intercept-only model above.
# 2. Compute the ICC from the variance components of fit_glmm_nested
#    by hand (see Section 5) and interpret: is more of the
#    unexplained variance at the LOCATION level or the BROOD level?
# 3. Refit with only LOCATION as a random effect (drop BROOD), i.e.
#    glmer(TICKS ~ YEAR + cHEIGHT + (1|LOCATION), family=poisson),
#    and compare AIC/BIC and fixed-effect standard errors to
#    fit_glmm_nested. What changes, and why?
# 4. Use ranef() to extract the BLUPs for BROOD and plot them against
#    the number of chicks per brood -- confirm that broods with fewer
#    chicks show more shrinkage toward zero (partial pooling).
