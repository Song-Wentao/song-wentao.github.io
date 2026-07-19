# ============================================================
# Lecture 6 -- Generalized Linear Models
# Ecological Modelling with R, Python, and Julia
#
# Dataset:
#   data/grouseticks.csv (Elston, Moss, Boulinier, Arrowsmith & Lambin 2001,
#                          Parasitology 122: 563-569 -- "Analysis of
#                          aggregation, a worked example: numbers of ticks
#                          on red grouse chicks.")
#   One of the most widely taught real GLMM datasets in ecology -- used as
#   the worked example in Zuur et al. (2009) and Bolker et al. (2009, TREE).
#
# Columns:
#   INDEX    chick ID
#   TICKS    tick count per chick (response)
#   BROOD    factor, 118 levels (chick's brood of origin)
#   HEIGHT   altitude in metres
#   YEAR     factor, 95/96/97
#   LOCATION factor, 63 levels
#   cHEIGHT  HEIGHT, mean-centered
#
# Methods:
#   1. Poisson GLM:      TICKS ~ YEAR + cHEIGHT, log link -- glm(family = poisson)
#   2. Overdispersion check: residual deviance / residual df
#   3. Negative-binomial GLM (fixes overdispersion) -- MASS::glm.nb()
#   4. Binomial GLM (toy presence/absence recoding) -- glm(family = binomial)
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_06_glm.R
# ============================================================

suppressMessages(library(MASS))

dir.create("figures", showWarnings = FALSE)

ticks <- read.csv("data/grouseticks.csv", stringsAsFactors = FALSE)
ticks$YEAR     <- factor(ticks$YEAR)
ticks$BROOD    <- factor(ticks$BROOD)
ticks$LOCATION <- factor(ticks$LOCATION)

cat("=== Lecture 6: Generalized Linear Models (R) ===\n\n")

## ------------------------------------------------------------
## 0. Why a linear model fails here
## ------------------------------------------------------------
cat("--- TICKS distribution ---\n")
print(summary(ticks$TICKS))
cat("Proportion of chicks with zero ticks:",
    round(mean(ticks$TICKS == 0), 3), "\n")
cat("Variance / mean of TICKS:",
    round(var(ticks$TICKS) / mean(ticks$TICKS), 1),
    "(>> 1 already hints at overdispersion relative to Poisson)\n\n")

## ------------------------------------------------------------
## 1. Poisson GLM -- TICKS ~ YEAR + cHEIGHT, log link
## ------------------------------------------------------------
pois_fit <- glm(TICKS ~ YEAR + cHEIGHT, family = poisson(link = "log"),
                 data = ticks)
cat("--- Poisson GLM: TICKS ~ YEAR + cHEIGHT ---\n")
print(summary(pois_fit))

## Coefficients on the link (log) scale vs. the response (rate ratio) scale
cat("\nCoefficients on the log-link scale:\n")
print(round(coef(pois_fit), 4))
cat("\nExponentiated coefficients (rate ratios on the response scale):\n")
print(round(exp(coef(pois_fit)), 4))

## ------------------------------------------------------------
## 2. Overdispersion check: residual deviance / residual df
##    Ratio >> 1 signals overdispersion (variance > mean, more than
##    Poisson allows).
## ------------------------------------------------------------
disp_ratio <- deviance(pois_fit) / df.residual(pois_fit)
cat("\n--- Overdispersion check ---\n")
cat("Residual deviance:", round(deviance(pois_fit), 1),
    "on", df.residual(pois_fit), "df\n")
cat("Dispersion ratio (deviance / df):", round(disp_ratio, 2), "\n")
if (disp_ratio > 1.5) {
  cat("--> Ratio is well above 1: the Poisson model is overdispersed.\n")
  cat("    This matches the paper's own point: tick counts are strongly\n")
  cat("    aggregated (clumped), not Poisson-distributed.\n\n")
} else {
  cat("--> Ratio is close to 1: no strong evidence of overdispersion.\n\n")
}

## ------------------------------------------------------------
## 3. Negative-binomial GLM -- fixes overdispersion by adding a
##    dispersion parameter (theta) that lets variance exceed the mean.
## ------------------------------------------------------------
nb_fit <- glm.nb(TICKS ~ YEAR + cHEIGHT, data = ticks)
cat("--- Negative-binomial GLM: TICKS ~ YEAR + cHEIGHT ---\n")
print(summary(nb_fit))
cat("\nEstimated theta (dispersion parameter):", round(nb_fit$theta, 3), "\n")

cat("\n--- AIC comparison: Poisson vs. Negative-Binomial ---\n")
cat("Poisson AIC:            ", round(AIC(pois_fit), 1), "\n")
cat("Negative-Binomial AIC:  ", round(AIC(nb_fit), 1), "\n")
cat("Difference (Poisson - NB):", round(AIC(pois_fit) - AIC(nb_fit), 1),
    "(large positive value favors the negative-binomial model)\n\n")

## ------------------------------------------------------------
## 4. Binomial GLM (logistic regression) -- toy example:
##    recode TICKS as presence/absence and model with cHEIGHT.
## ------------------------------------------------------------
ticks$present <- as.integer(ticks$TICKS > 0)
cat("--- Binomial GLM: present (TICKS > 0) ~ cHEIGHT ---\n")
bin_fit <- glm(present ~ cHEIGHT, family = binomial(link = "logit"),
                data = ticks)
print(summary(bin_fit))

cat("\nOdds ratio for cHEIGHT (exp(coef)):",
    round(exp(coef(bin_fit)["cHEIGHT"]), 4), "\n")

## Predicted probability of tick presence at a couple of cHEIGHT values
new_h <- data.frame(cHEIGHT = c(-50, 0, 50))
pred_p <- predict(bin_fit, newdata = new_h, type = "response")
cat("\nPredicted P(present) at cHEIGHT = -50, 0, 50:\n")
print(round(setNames(pred_p, new_h$cHEIGHT), 3))

## ------------------------------------------------------------
## 5. Figure: TICKS by YEAR
## ------------------------------------------------------------
png("figures/lecture_06_tick_counts_by_year.png", width = 900, height = 650, res = 120)
set.seed(42)
plot(jitter(as.integer(ticks$YEAR), amount = 0.15),
     log1p(ticks$TICKS),
     xaxt = "n", xlab = "Year", ylab = "log1p(TICKS)",
     main = "Tick counts per chick by year (log1p scale)",
     pch = 16, col = adjustcolor("steelblue", alpha.f = 0.4))
axis(1, at = 1:length(levels(ticks$YEAR)), labels = levels(ticks$YEAR))
boxplot(log1p(TICKS) ~ YEAR, data = ticks, add = TRUE,
        col = adjustcolor("white", alpha.f = 0), border = "black",
        outline = FALSE, boxwex = 0.3)
dev.off()
cat("\nSaved figures/lecture_06_tick_counts_by_year.png\n")

# --- EXERCISES ---
# TODO 1: Fit a Poisson GLM using HEIGHT instead of cHEIGHT and compare the
#         coefficient estimates and intercept interpretation to the cHEIGHT
#         model fit above.
# TODO 2: Fit the negative-binomial GLM (already done above as nb_fit) and
#         compare its AIC to the Poisson model's AIC; report which model
#         the data prefer and why.
# TODO 3: Fit a binomial GLM for tick presence/absence ~ cHEIGHT (already
#         done above as bin_fit); report the odds ratio for cHEIGHT and
#         interpret its sign and magnitude.
# TODO 4: See exercises/lecture_06_exercises.md for the full exercise set.
