# ============================================================
# Lecture 5 -- Linear Models
# Ecological Modelling with R, Python, and Julia
#
# Dataset:
#   data/mite_species.csv + data/mite_env.csv  (Borcard & Legendre 1994,
#                                                Ecology -- oribatid mite
#                                                community, Lac Cromwell
#                                                peat moss, 70 sites)
#
# Response:
#   richness = number of species with nonzero abundance at each site
#
# Models:
#   1. Simple LM:   richness ~ WatrCont
#   2. Multiple LM: richness ~ WatrCont + SubsDens + Substrate
#   3. Four classic diagnostic plots for the multiple LM
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_05_linear_models.R
# ============================================================

dir.create("figures", showWarnings = FALSE)

## ------------------------------------------------------------
## 1. Load and join data, compute richness
## ------------------------------------------------------------

species <- read.csv("data/mite_species.csv", stringsAsFactors = FALSE)
env <- read.csv("data/mite_env.csv", stringsAsFactors = FALSE)

sp_cols <- setdiff(names(species), "site")
richness <- rowSums(species[, sp_cols] > 0)

dat <- merge(env, data.frame(site = species$site, richness = richness),
             by = "site")
dat$Substrate <- factor(dat$Substrate)

cat("=== Lecture 5: Linear Models (R) ===\n\n")
cat("n sites:", nrow(dat), "\n")
cat("richness range:", range(dat$richness), "\n\n")

## ------------------------------------------------------------
## 2. Simple linear regression: richness ~ WatrCont
## ------------------------------------------------------------

fit_simple <- lm(richness ~ WatrCont, data = dat)

cat("--- Simple LM: richness ~ WatrCont ---\n")
print(summary(fit_simple))
cat("\n")

## ------------------------------------------------------------
## 3. Multiple linear regression: richness ~ WatrCont + SubsDens + Substrate
## ------------------------------------------------------------

fit_multi <- lm(richness ~ WatrCont + SubsDens + Substrate, data = dat)

cat("--- Multiple LM: richness ~ WatrCont + SubsDens + Substrate ---\n")
print(summary(fit_multi))
cat("\n")

cat("--- ANOVA table for the multiple LM ---\n")
print(anova(fit_multi))
cat("\n")

cat("R-squared comparison:\n")
cat(sprintf("  simple model:   R2 = %.3f, adj R2 = %.3f\n",
            summary(fit_simple)$r.squared, summary(fit_simple)$adj.r.squared))
cat(sprintf("  multiple model: R2 = %.3f, adj R2 = %.3f\n",
            summary(fit_multi)$r.squared, summary(fit_multi)$adj.r.squared))
cat("\n")

## ------------------------------------------------------------
## 4. Diagnostic plots for the multiple LM
##    residuals vs fitted | Q-Q | scale-location | residuals vs leverage
## ------------------------------------------------------------

png("figures/lecture_05_diagnostics.png", width = 900, height = 900, res = 125)
par(mfrow = c(2, 2))
plot(fit_multi)
dev.off()

cat("Saved figures/lecture_05_diagnostics.png\n")

cat("\n=== Done ===\n")

# --- EXERCISES ---
# TODO 1: Fit richness ~ SubsDens alone. Compare its R2 (and adjusted R2) to
#         the richness ~ WatrCont simple model above. Which single predictor
#         explains more variation in richness?
# TODO 2: Fit richness ~ Substrate alone (Substrate as the only predictor).
#         Interpret the coefficients -- what do they represent relative to
#         the reference level? Use anova() to test whether Substrate
#         explains a significant amount of variation.
# TODO 3: Add an interaction term: richness ~ WatrCont * Substrate. Does the
#         slope of richness on WatrCont differ meaningfully across substrate
#         types? Use anova(fit_multi, fit_interaction) to compare.
# TODO 4: Fit richness ~ WatrCont using only sites with SubsDens > 60 (an
#         extreme subset) and inspect the four diagnostic plots. Which
#         assumption looks most violated, and what would you do about it?
