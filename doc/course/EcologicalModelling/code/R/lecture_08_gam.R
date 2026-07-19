# ============================================================
# Lecture 8 -- Generalized Additive Models
# Ecological Modelling with R, Python, and Julia
#
# Dataset:
#   data/mite_species.csv (70 sites x 35 oribatid mite species, wide format,
#                           first column "site")
#   data/mite_env.csv     (site, SubsDens, WatrCont, Substrate, Shrub,
#                           Topo, x, y)
#   Borcard & Legendre (1994), Ecology 75: 1682-1692 -- Lac Cromwell
#   Sphagnum peatland, oribatid mite community and environmental data.
#   A classic dataset in the vegan/ade4 teaching literature.
#
# Response: species richness per site (count of species with abundance > 0)
#
# Methods:
#   1. Linear model:  richness ~ WatrCont           (lm, from Lecture 5)
#   2. Gaussian GAM:  richness ~ s(WatrCont)          (mgcv::gam)
#   3. Poisson GAM:   richness ~ s(WatrCont), family = poisson
#   4. AIC comparison of the linear model vs. the Gaussian GAM
#   5. Plot of the fitted smooth (with confidence band) overlaid with the
#      linear fit, saved to figures/lecture_08_gam_smooth.png
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_08_gam.R
# ============================================================

suppressMessages(library(mgcv))

dir.create("figures", showWarnings = FALSE)

## ------------------------------------------------------------
## 0. Build the dataset: richness per site + environmental covariates
## ------------------------------------------------------------
mite_sp  <- read.csv("data/mite_species.csv", stringsAsFactors = FALSE)
mite_env <- read.csv("data/mite_env.csv", stringsAsFactors = FALSE)

sp_mat   <- as.matrix(mite_sp[, setdiff(names(mite_sp), "site")])
richness <- rowSums(sp_mat > 0)

mite <- data.frame(
  site      = mite_sp$site,
  richness  = richness,
  WatrCont  = mite_env$WatrCont,
  SubsDens  = mite_env$SubsDens
)

cat("=== Lecture 8: Generalized Additive Models (R) ===\n\n")
cat("--- Species richness summary ---\n")
print(summary(mite$richness))
cat("\n--- WatrCont (water content, %) summary ---\n")
print(summary(mite$WatrCont))
cat("\n")

## ------------------------------------------------------------
## 1. Linear model (Lecture 5 style): richness ~ WatrCont
##    A single straight line -- does it capture the shape of the response?
## ------------------------------------------------------------
lm_fit <- lm(richness ~ WatrCont, data = mite)
cat("--- Linear model: richness ~ WatrCont ---\n")
print(summary(lm_fit))

## ------------------------------------------------------------
## 2. Gaussian GAM: richness ~ s(WatrCont)
##    Replace the linear term beta*WatrCont with a smooth function
##    f(WatrCont) built from a penalized regression spline basis.
##    Smoothing parameter chosen by the default GCV criterion, which lets
##    the penalty land anywhere between "dead straight" (EDF = 1) and
##    "as wiggly as the basis dimension k allows" (EDF up to k - 1).
## ------------------------------------------------------------
gam_fit <- gam(richness ~ s(WatrCont), data = mite)
cat("\n--- Gaussian GAM: richness ~ s(WatrCont) (GCV smoothing) ---\n")
print(summary(gam_fit))

cat("\nEffective degrees of freedom (EDF) of s(WatrCont):",
    round(summary(gam_fit)$edf, 2), "\n")
cat("(EDF = 1 would mean the smooth IS a straight line -- a linear model\n")
cat(" is the special case of a GAM where the penalty shrinks the smooth\n")
cat(" all the way down to EDF = 1. Here EDF is a little above 1, so the\n")
cat(" penalty is keeping only a small, real amount of extra curvature.)\n\n")

## Illustration: fitting the same smooth with method = "ML" penalizes the
## wiggliness more aggressively on this dataset and shrinks the smooth all
## the way to EDF = 1 -- at which point the GAM's fitted values become
## numerically identical to the plain linear model. This is the cleanest
## possible demonstration that "LM" is a special case of "GAM".
gam_fit_ml <- gam(richness ~ s(WatrCont), data = mite, method = "ML")
cat("--- Same smooth, method = \"ML\": EDF shrinks to",
    round(summary(gam_fit_ml)$edf, 2), "---\n")
cat("AIC (ML-smoothed GAM):", round(AIC(gam_fit_ml), 2),
    " vs. AIC (linear model):", round(AIC(lm_fit), 2),
    "-- identical, because the smooth has become a straight line.\n\n")

## ------------------------------------------------------------
## 3. AIC comparison: linear model vs. Gaussian GAM
## ------------------------------------------------------------
cat("--- AIC comparison: LM vs. GAM (GCV-smoothed) ---\n")
cat("Linear model AIC: ", round(AIC(lm_fit), 2), "\n")
cat("GAM AIC:          ", round(AIC(gam_fit), 2), "\n")
cat("Difference (LM - GAM):", round(AIC(lm_fit) - AIC(gam_fit), 2),
    "(positive favors the GAM, though the margin is small here --\n")
cat(" the extra curvature helps a little, it does not transform the fit)\n\n")

## ------------------------------------------------------------
## 4. Poisson GAM: richness ~ s(WatrCont), family = poisson
##    Richness is a count -- Lecture 6 motivated Poisson models for counts.
##    A Poisson GAM combines that count-aware family with a flexible smooth.
## ------------------------------------------------------------
gam_pois <- gam(richness ~ s(WatrCont), data = mite, family = poisson,
                 method = "REML")
cat("--- Poisson GAM: richness ~ s(WatrCont), family = poisson ---\n")
print(summary(gam_pois))
cat("\nPoisson GAM AIC:  ", round(AIC(gam_pois), 2), "\n")
cat("(Not directly comparable to the Gaussian AIC above -- different\n")
cat(" response distributions -- but comparable to other Poisson models.)\n\n")

## ------------------------------------------------------------
## 5. Figure: fitted smooth (with confidence band) vs. the linear fit
## ------------------------------------------------------------
wc_grid <- data.frame(WatrCont = seq(min(mite$WatrCont), max(mite$WatrCont),
                                       length.out = 200))

gam_pred <- predict(gam_fit, newdata = wc_grid, se.fit = TRUE)
wc_grid$gam_fit  <- gam_pred$fit
wc_grid$gam_lwr  <- gam_pred$fit - 1.96 * gam_pred$se.fit
wc_grid$gam_upr  <- gam_pred$fit + 1.96 * gam_pred$se.fit
wc_grid$lm_fit   <- predict(lm_fit, newdata = wc_grid)

png("figures/lecture_08_gam_smooth.png", width = 1000, height = 700, res = 120)
plot(mite$WatrCont, mite$richness,
     pch = 16, col = adjustcolor("black", alpha.f = 0.5),
     xlab = "Water content (%)", ylab = "Species richness",
     main = "Richness vs. water content: linear fit vs. GAM smooth")
polygon(c(wc_grid$WatrCont, rev(wc_grid$WatrCont)),
        c(wc_grid$gam_lwr, rev(wc_grid$gam_upr)),
        col = adjustcolor("#2E6E8E", alpha.f = 0.2), border = NA)
lines(wc_grid$WatrCont, wc_grid$gam_fit, col = "#2E6E8E", lwd = 2.5)
lines(wc_grid$WatrCont, wc_grid$lm_fit, col = "#C0562B", lwd = 2, lty = 2)
legend("topright", legend = c("GAM smooth (95% CI)", "Linear fit"),
       col = c("#2E6E8E", "#C0562B"), lwd = c(2.5, 2), lty = c(1, 2),
       bty = "n")
dev.off()
cat("Saved figures/lecture_08_gam_smooth.png\n")

# --- EXERCISES ---
# TODO 1: Fit richness ~ s(SubsDens) and compare its EDF and shape to the
#         s(WatrCont) smooth fit above -- is the SubsDens relationship as
#         curved, or closer to a straight line?
# TODO 2: Fit a 2-D smooth richness ~ s(WatrCont, SubsDens) (a tensor or
#         isotropic smooth surface) and visualize it with plot(gam_model,
#         scheme = 1) or vis.gam().
# TODO 3: Compare the Gaussian GAM (gam_fit) and Poisson GAM (gam_pois)
#         fitted above -- do their smooths look similar? Which is the more
#         appropriate distribution for a count response, and why?
# TODO 4: See exercises/lecture_08_exercises.md for the full exercise set.
