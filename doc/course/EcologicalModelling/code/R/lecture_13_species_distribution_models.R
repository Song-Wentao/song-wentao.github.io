# ============================================================
# Lecture 13 -- Species Distribution / Niche Models
# Ecological Modelling with R, Python, and Julia
#
# Dataset:
#   data/bei_points.csv          (x, y coordinates of 3604 individually
#                                  mapped Beilschmiedia pendula trees)
#   data/bei_covariates_grid.csv (x, y, elev, grad -- a fine regular grid
#                                  of elevation and slope-gradient
#                                  covariates across the same plot)
#   Barro Colorado Island 50-ha forest census: Condit, Hubbell & Foster
#   (2002), Science; Hubbell et al. (1999), Science. One of the most-cited
#   real datasets in spatial/community ecology, and the standard teaching
#   example for spatial point-process / SDM-style modeling (e.g. Baddeley,
#   Rubak & Turner, "Spatial Point Patterns").
#
# Task: we only have tree LOCATIONS, not surveyed absences -- the classic
#       presence-only / presence-background SDM data problem. We generate
#       random background points across the plot, build a presence (1)
#       vs. background (0) classification dataset with elev/grad
#       covariates, and fit a logistic regression SDM and a Random Forest
#       SDM (reusing Lecture 12's toolkit), compare them by AUC, and
#       produce a habitat-suitability map.
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_13_species_distribution_models.R
# ============================================================

suppressMessages(library(randomForest))
suppressMessages(library(FNN))     # fast nearest-neighbour lookup
suppressMessages(library(pROC))    # AUC

set.seed(13)
dir.create("figures", showWarnings = FALSE)

## ------------------------------------------------------------
## 0. Load data
## ------------------------------------------------------------
pts  <- read.csv("data/bei_points.csv", stringsAsFactors = FALSE)
grid <- read.csv("data/bei_covariates_grid.csv", stringsAsFactors = FALSE)

cat("Tree locations:", nrow(pts), "\n")
cat("Covariate grid cells:", nrow(grid), "\n")
cat("Plot extent: x in [", min(grid$x), ",", max(grid$x),
    "]  y in [", min(grid$y), ",", max(grid$y), "]\n")

## ------------------------------------------------------------
## 1. Nearest-neighbour join: extract elev/grad at each tree location
##    from the nearest grid cell (grid is regular but tree coordinates
##    are continuous, so we use a KD-tree nearest-neighbour lookup
##    rather than an exact merge).
## ------------------------------------------------------------
nn_presence <- FNN::get.knnx(
  data  = grid[, c("x", "y")],
  query = pts[, c("x", "y")],
  k = 1
)
pts$elev <- grid$elev[nn_presence$nn.index[, 1]]
pts$grad <- grid$grad[nn_presence$nn.index[, 1]]

## ------------------------------------------------------------
## 2. Background (pseudo-absence) points
##    Standard presence-background workaround: sample random points
##    across the study area to contrast against presence locations.
##    We sample 2x as many background points as presences, directly
##    from the covariate grid's coordinate range, with a fixed seed.
## ------------------------------------------------------------
n_presence  <- nrow(pts)
n_background <- 2 * n_presence

bg_x <- runif(n_background, min(grid$x), max(grid$x))
bg_y <- runif(n_background, min(grid$y), max(grid$y))

nn_bg <- FNN::get.knnx(
  data  = grid[, c("x", "y")],
  query = cbind(x = bg_x, y = bg_y),
  k = 1
)
background <- data.frame(
  x = bg_x, y = bg_y,
  elev = grid$elev[nn_bg$nn.index[, 1]],
  grad = grid$grad[nn_bg$nn.index[, 1]]
)

## ------------------------------------------------------------
## 3. Build the presence (1) / background (0) classification dataset
## ------------------------------------------------------------
dat <- rbind(
  data.frame(presence = 1L, x = pts$x, y = pts$y,
             elev = pts$elev, grad = pts$grad),
  data.frame(presence = 0L, x = background$x, y = background$y,
             elev = background$elev, grad = background$grad)
)
dat$presence <- factor(dat$presence, levels = c(0, 1))

cat("\nPresence-background dataset:\n")
cat("  Presence points:  ", sum(dat$presence == 1), "\n")
cat("  Background points:", sum(dat$presence == 0), "\n")

## Train/test split for honest AUC estimation
n <- nrow(dat)
train_idx <- sample(seq_len(n), size = floor(0.75 * n))
train_dat <- dat[train_idx, ]
test_dat  <- dat[-train_idx, ]

## ------------------------------------------------------------
## 4. Logistic regression SDM: presence ~ elev + grad
## ------------------------------------------------------------
glm_fit <- glm(presence ~ elev + grad, data = train_dat, family = binomial)

cat("\n--- Logistic Regression SDM ---\n")
print(summary(glm_fit))
cat(sprintf("AIC: %.1f\n", AIC(glm_fit)))

glm_pred_test <- predict(glm_fit, newdata = test_dat, type = "response")
glm_roc <- pROC::roc(test_dat$presence, glm_pred_test, quiet = TRUE,
                      levels = c("0", "1"), direction = "<")
glm_auc <- as.numeric(pROC::auc(glm_roc))
glm_acc <- mean((glm_pred_test > 0.5) == (test_dat$presence == "1"))
cat(sprintf("Held-out test AUC (GLM): %.3f\n", glm_auc))
cat(sprintf("Held-out test accuracy (GLM, 0.5 cutoff): %.3f\n", glm_acc))

## ------------------------------------------------------------
## 5. Random Forest SDM (reusing Lecture 12's toolkit)
## ------------------------------------------------------------
rf_fit <- randomForest(
  presence ~ elev + grad, data = train_dat,
  ntree = 500, importance = TRUE
)

cat("\n--- Random Forest SDM ---\n")
print(rf_fit)
cat("\nVariable importance:\n")
print(importance(rf_fit))

rf_pred_test <- predict(rf_fit, newdata = test_dat, type = "prob")[, "1"]
rf_roc <- pROC::roc(test_dat$presence, rf_pred_test, quiet = TRUE,
                     levels = c("0", "1"), direction = "<")
rf_auc <- as.numeric(pROC::auc(rf_roc))
rf_pred_class <- predict(rf_fit, newdata = test_dat, type = "response")
rf_acc <- mean(rf_pred_class == test_dat$presence)
cat(sprintf("\nHeld-out test AUC (Random Forest): %.3f\n", rf_auc))
cat(sprintf("Held-out test accuracy (Random Forest): %.3f\n", rf_acc))

cat("\n--- GLM vs. Random Forest, held-out AUC ---\n")
cat(sprintf("  Logistic regression: %.3f\n", glm_auc))
cat(sprintf("  Random forest:       %.3f\n", rf_auc))

## ------------------------------------------------------------
## 6. Partial dependence on elevation (grad held at its median)
##    -- what did the GLM/RF learn about Beilschmiedia's elevation
##    preference on BCI?
## ------------------------------------------------------------
elev_seq <- seq(min(grid$elev), max(grid$elev), length.out = 100)
pd_dat <- data.frame(elev = elev_seq, grad = median(dat$grad))

pd_dat$glm_suitability <- predict(glm_fit, newdata = pd_dat, type = "response")
pd_dat$rf_suitability  <- predict(rf_fit, newdata = pd_dat, type = "prob")[, "1"]

cat("\n--- Partial dependence on elevation (grad held at median) ---\n")
cat("Elevation range in data:", round(range(dat$elev), 1), "\n")
peak_elev_glm <- pd_dat$elev[which.max(pd_dat$glm_suitability)]
peak_elev_rf  <- pd_dat$elev[which.max(pd_dat$rf_suitability)]
cat(sprintf("GLM: suitability is monotonic (no interior optimum by construction);\n"))
cat(sprintf("     max predicted suitability at elev = %.1f m\n", peak_elev_glm))
cat(sprintf("RF:  max predicted suitability at elev = %.1f m\n", peak_elev_rf))

## ------------------------------------------------------------
## 7. Predict suitability across the full covariate grid and map it
##    (Random Forest prediction shown here -- the same idea applies to
##    the GLM; both models predict a probability for every grid cell.)
## ------------------------------------------------------------
grid$suitability_rf  <- predict(rf_fit, newdata = grid, type = "prob")[, "1"]
grid$suitability_glm <- predict(glm_fit, newdata = grid, type = "response")

cat("\nSuitability grid summary (Random Forest):\n")
print(summary(grid$suitability_rf))

if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)
  p <- ggplot(grid, aes(x = x, y = y, fill = suitability_rf)) +
    geom_raster() +
    scale_fill_viridis_c(name = "Predicted\nsuitability") +
    coord_equal() +
    labs(
      title = "Beilschmiedia pendula habitat suitability (Random Forest SDM)",
      subtitle = "Barro Colorado Island 50-ha plot -- presence-background model",
      x = "x (m)", y = "y (m)"
    ) +
    theme_minimal()
  ggsave("figures/lecture_13_suitability_map.png", p, width = 10, height = 5.2,
         dpi = 130)
} else {
  png("figures/lecture_13_suitability_map.png", width = 1200, height = 650,
      res = 130)
  par(mar = c(4, 4, 3, 5))
  nx <- length(unique(grid$x)); ny <- length(unique(grid$y))
  mat <- matrix(grid$suitability_rf, nrow = nx, ncol = ny)
  image(sort(unique(grid$x)), sort(unique(grid$y)), mat,
        col = hcl.colors(50, "viridis"), xlab = "x (m)", ylab = "y (m)",
        main = "Beilschmiedia pendula habitat suitability (Random Forest SDM)")
  dev.off()
}

cat("\nFigure saved to figures/lecture_13_suitability_map.png\n")

# --- EXERCISES ---
# TODO 1: Resample background points at 2x and 4x the presence count
#         used here (n_background <- 2 * n_presence). Refit the GLM each
#         time and compare the elev/grad coefficients and their standard
#         errors -- how sensitive is the logistic regression to the
#         number of background points?
# TODO 2: Add an elev^2 term (poly(elev, 2, raw = TRUE) or I(elev^2)) to
#         the GLM to allow an interior elevation optimum rather than a
#         monotonic response. Compare AIC to the linear-elevation model
#         and re-plot the partial dependence curve.
# TODO 3: Using the SAME train/test split object (train_idx/test_dat
#         above), compare RF vs. GLM AUC and accuracy on a few different
#         random seeds for the split. How much does the "winner" change
#         seed to seed?
# TODO 4: The train/test split here is a simple random split of
#         presence+background points, which does NOT account for spatial
#         autocorrelation (nearby points are not independent). Try a
#         spatial block split instead (e.g. split the plot into a left
#         half [x < 500] for training and right half [x >= 500] for
#         testing) and compare AUC to the random-split estimate above --
#         is the spatially honest AUC higher or lower, and why?
