# ============================================================
# Lecture 16 -- Spatial Modeling (course finale)
# Ecological Modelling with R, Python, and Julia
#
# Datasets:
#   data/mite_env.csv            (SubsDens, WatrCont, Substrate, Shrub,
#                                  Topo, x, y for 70 oribatid mite cores,
#                                  Lac Cromwell -- Borcard & Legendre 1994,
#                                  Ecology)
#   data/bei_points.csv          (x, y of 3604 individually mapped
#                                  Beilschmiedia pendula trees)
#   data/bei_covariates_grid.csv (x, y, elev, grad -- a fine regular grid
#                                  of elevation/slope-gradient covariates)
#   Barro Colorado Island 50-ha forest census: Condit, Hubbell & Foster
#   (2002), Science -- the standard teaching dataset for spatial
#   point-process modeling (Baddeley, Rubak & Turner, "Spatial Point
#   Patterns: Methodology and Applications with R").
#
# Part 1: Spatial autocorrelation. Every model in Lectures 5-13 assumes
#         residuals are independent. Real ecological data collected in
#         space routinely violate that assumption (Lecture 13's SDM
#         residuals were a case in point). We quantify this directly with
#         Moran's I on the mite WatrCont data, using a k-nearest-neighbour
#         spatial weights matrix and a permutation test.
#
# Part 2: Spatial point process modeling. Rather than treating space as a
#         nuisance to correct for, here the point LOCATIONS themselves are
#         the response. We fit an inhomogeneous Poisson point process to
#         the BEI tree locations as a function of elevation and gradient
#         -- the statistically formal version of Lecture 13's ad hoc
#         presence-background SDM.
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_16_spatial_modeling.R
# ============================================================

suppressMessages(library(spatstat))

set.seed(16)
dir.create("figures", showWarnings = FALSE)

## ============================================================
## PART 1 -- Moran's I on mite WatrCont (spatial autocorrelation)
## ============================================================

mite_env <- read.csv("data/mite_env.csv", stringsAsFactors = FALSE)
cat("Mite cores:", nrow(mite_env), "\n")
cat("x range:", range(mite_env$x), "  y range:", range(mite_env$y), "\n\n")

## ------------------------------------------------------------
## 1. Build a k-nearest-neighbour spatial weights matrix (k = 5)
##    Hand-rolled: for irregularly spaced points, k-NN weights are
##    simple and robust (no distance-band tuning needed). We build a
##    full n x n row-standardized weights matrix W, where W[i, j] =
##    1/k if j is one of i's k nearest neighbours, else 0.
## ------------------------------------------------------------
knn_weights <- function(coords, k) {
  n <- nrow(coords)
  d <- as.matrix(dist(coords))
  diag(d) <- Inf
  W <- matrix(0, n, n)
  for (i in seq_len(n)) {
    nn <- order(d[i, ])[seq_len(k)]
    W[i, nn] <- 1 / k          # row-standardized: each row sums to 1
  }
  W
}

k <- 5
coords <- as.matrix(mite_env[, c("x", "y")])
W <- knn_weights(coords, k)

## ------------------------------------------------------------
## 2. Moran's I, hand-rolled:
##      I = (n / S0) * sum_ij( w_ij * (x_i - xbar) * (x_j - xbar) )
##              / sum_i( (x_i - xbar)^2 )
##    where S0 = sum of all weights (here S0 = n, since W is
##    row-standardized: every row sums to 1).
## ------------------------------------------------------------
morans_i <- function(x, W) {
  n <- length(x)
  xbar <- mean(x)
  dev <- x - xbar
  S0 <- sum(W)
  num <- sum(W * outer(dev, dev))
  den <- sum(dev^2)
  (n / S0) * (num / den)
}

watr <- mite_env$WatrCont
I_obs <- morans_i(watr, W)
cat(sprintf("Observed Moran's I for WatrCont (k=%d NN weights): %.4f\n", k, I_obs))

## Expected value under no spatial autocorrelation, for reference
n <- nrow(mite_env)
I_expected <- -1 / (n - 1)
cat(sprintf("Expected I under no autocorrelation: %.4f\n", I_expected))

## ------------------------------------------------------------
## 3. Permutation test: shuffle WatrCont across sites (breaking any
##    spatial structure while preserving the value distribution and
##    the fixed spatial weights), recompute I each time, and see how
##    extreme the observed I is relative to this null distribution.
## ------------------------------------------------------------
n_perm <- 999
I_perm <- numeric(n_perm)
for (p in seq_len(n_perm)) {
  I_perm[p] <- morans_i(sample(watr), W)
}

p_value <- (sum(I_perm >= I_obs) + 1) / (n_perm + 1)
cat(sprintf("Permutation-based p-value (%d permutations, one-sided): %.4f\n",
            n_perm, p_value))
cat(sprintf("Null distribution: mean = %.4f, SD = %.4f\n",
            mean(I_perm), sd(I_perm)))

if (p_value < 0.05) {
  cat("--> Significant POSITIVE spatial autocorrelation in WatrCont:\n")
  cat("    nearby cores have more similar water content than expected by\n")
  cat("    chance. The independence assumption behind ordinary GLM/GAM\n")
  cat("    standard errors is violated for this variable.\n")
}

## ------------------------------------------------------------
## 4. Moran scatterplot: WatrCont vs. its spatially lagged value
##    (the weighted average of each site's k nearest neighbours).
##    The slope of the regression line IS (approximately) Moran's I.
## ------------------------------------------------------------
lagged_watr <- as.numeric(W %*% watr)

moran_lm <- lm(lagged_watr ~ watr)
cat(sprintf("\nMoran scatterplot regression slope: %.4f (compare to I = %.4f)\n",
            coef(moran_lm)[2], I_obs))

png("figures/lecture_16_moran_scatterplot.png", width = 900, height = 800, res = 130)
par(mar = c(4.2, 4.5, 3, 1.5))
plot(watr, lagged_watr, pch = 19, col = adjustcolor("#2c7fb8", 0.7),
     xlab = "WatrCont (site i)", ylab = "Spatially lagged WatrCont (mean of k=5 NN)",
     main = sprintf("Moran Scatterplot -- WatrCont (Moran's I = %.3f, p = %.3f)",
                     I_obs, p_value))
abline(h = mean(lagged_watr), v = mean(watr), lty = 3, col = "grey50")
abline(moran_lm, col = "firebrick", lwd = 2)
legend("topleft", legend = sprintf("slope ~ Moran's I = %.3f", I_obs),
       lty = 1, col = "firebrick", lwd = 2, bty = "n")
dev.off()
cat("Figure saved to figures/lecture_16_moran_scatterplot.png\n")

## ------------------------------------------------------------
## 5. What to do about it: two complementary fixes tied back to
##    earlier lectures.
##    (a) A spatial regression term (e.g. a simultaneous autoregressive
##        or conditional autoregressive error term, spdep::errorsarlm)
##        explicitly models the residual correlation structure.
##    (b) A GAM with a 2-D smooth s(x, y) (Lecture 8) absorbs whatever
##        smooth spatial surface is left over -- much simpler to fit
##        and often enough to remove most of the autocorrelation.
##    We illustrate (b) here since mgcv is already central to the course.
## ------------------------------------------------------------
if (requireNamespace("mgcv", quietly = TRUE)) {
  suppressMessages(library(mgcv))
  gam_spatial <- gam(WatrCont ~ s(x, y), data = mite_env)
  cat("\n--- GAM with 2-D spatial smooth: WatrCont ~ s(x, y) ---\n")
  print(summary(gam_spatial))
  resid_gam <- residuals(gam_spatial)
  I_resid <- morans_i(resid_gam, W)
  cat(sprintf("\nMoran's I of the s(x,y) GAM residuals: %.4f\n", I_resid))
  cat(sprintf("(vs. Moran's I of the raw data: %.4f) -- the spatial smooth\n", I_obs))
  cat("has absorbed most of the spatial structure.\n")
}

## ============================================================
## PART 2 -- Inhomogeneous Poisson point process (BEI trees)
## ============================================================

cat("\n\n============================================================\n")
cat("PART 2: Spatial point process model -- BEI Beilschmiedia trees\n")
cat("============================================================\n\n")

pts  <- read.csv("data/bei_points.csv", stringsAsFactors = FALSE)
grid <- read.csv("data/bei_covariates_grid.csv", stringsAsFactors = FALSE)

cat("Tree locations:", nrow(pts), "\n")
cat("Covariate grid cells:", nrow(grid), "\n")

## ------------------------------------------------------------
## 1. Build spatstat image (im) objects for elev and grad from the
##    regular covariate grid, and a ppp (planar point pattern) object
##    for the tree locations, over the same observation window.
## ------------------------------------------------------------
xs <- sort(unique(grid$x))
ys <- sort(unique(grid$y))
nx <- length(xs)
ny <- length(ys)

elev_mat <- matrix(NA_real_, nrow = ny, ncol = nx)
grad_mat <- matrix(NA_real_, nrow = ny, ncol = nx)
idx_x <- match(grid$x, xs)
idx_y <- match(grid$y, ys)
for (i in seq_len(nrow(grid))) {
  elev_mat[idx_y[i], idx_x[i]] <- grid$elev[i]
  grad_mat[idx_y[i], idx_x[i]] <- grid$grad[i]
}
elev_im <- im(elev_mat, xcol = xs, yrow = ys)
grad_im <- im(grad_mat, xcol = xs, yrow = ys)

W_obs <- owin(xrange = range(xs), yrange = range(ys))
pp <- ppp(pts$x, pts$y, window = W_obs)

cat("\nPoint pattern summary:\n")
print(pp)

## ------------------------------------------------------------
## 2. Fit inhomogeneous Poisson point process models: intensity as a
##    log-linear function of elevation and gradient.
##    lambda(u) = exp(beta0 + beta1*elev(u) + beta2*grad(u))
## ------------------------------------------------------------
ppm_null  <- ppm(pp ~ 1)                                   # homogeneous CSR
ppm_elev  <- ppm(pp ~ elev, data = list(elev = elev_im))
ppm_full  <- ppm(pp ~ elev + grad, data = list(elev = elev_im, grad = grad_im))

cat("\n--- Homogeneous Poisson (CSR) ---\n")
print(ppm_null)
cat("\n--- Inhomogeneous PPM: ~ elev ---\n")
print(ppm_elev)
cat("\n--- Inhomogeneous PPM: ~ elev + grad ---\n")
print(ppm_full)

cat("\n--- Model comparison (AIC) ---\n")
aic_tab <- data.frame(
  model = c("Homogeneous (CSR)", "~ elev", "~ elev + grad"),
  AIC   = c(AIC(ppm_null), AIC(ppm_elev), AIC(ppm_full))
)
print(aic_tab)
cat(sprintf("\nBest model by AIC: %s\n", aic_tab$model[which.min(aic_tab$AIC)]))

## Likelihood ratio test: does grad add anything beyond elev alone?
lrt <- anova(ppm_elev, ppm_full, test = "LRT")
cat("\n--- Likelihood ratio test: elev+grad vs. elev alone ---\n")
print(lrt)

## ------------------------------------------------------------
## 3. Discretized-grid cross-check: bin the plot into a coarse grid,
##    count trees per cell, and fit an equivalent Poisson GLM with a
##    log(cell area) offset. This is the exact same statistical model
##    as ppm() with a piecewise-constant intensity approximation --
##    and it's the version we replicate in Python and Julia for
##    cross-language parity.
## ------------------------------------------------------------
n_bins_x <- 25
n_bins_y <- 10
x_breaks <- seq(min(xs), max(xs), length.out = n_bins_x + 1)
y_breaks <- seq(min(ys), max(ys), length.out = n_bins_y + 1)
cell_area <- (x_breaks[2] - x_breaks[1]) * (y_breaks[2] - y_breaks[1])

pts$bin_x <- cut(pts$x, breaks = x_breaks, include.lowest = TRUE, labels = FALSE)
pts$bin_y <- cut(pts$y, breaks = y_breaks, include.lowest = TRUE, labels = FALSE)

grid$bin_x <- cut(grid$x, breaks = x_breaks, include.lowest = TRUE, labels = FALSE)
grid$bin_y <- cut(grid$y, breaks = y_breaks, include.lowest = TRUE, labels = FALSE)

cell_cov <- aggregate(cbind(elev, grad) ~ bin_x + bin_y, data = grid, FUN = mean)

counts <- as.data.frame(table(bin_x = pts$bin_x, bin_y = pts$bin_y))
counts$bin_x <- as.integer(as.character(counts$bin_x))
counts$bin_y <- as.integer(as.character(counts$bin_y))

cell_dat <- merge(cell_cov, counts, by = c("bin_x", "bin_y"), all.x = TRUE)
cell_dat$Freq[is.na(cell_dat$Freq)] <- 0
cell_dat$cell_area <- cell_area
cell_dat$cell_x <- (x_breaks[cell_dat$bin_x] + x_breaks[cell_dat$bin_x + 1]) / 2
cell_dat$cell_y <- (y_breaks[cell_dat$bin_y] + y_breaks[cell_dat$bin_y + 1]) / 2

cat(sprintf("\nDiscretized grid: %d x %d = %d cells, cell size %.1f x %.1f m\n",
            n_bins_x, n_bins_y, nrow(cell_dat),
            x_breaks[2] - x_breaks[1], y_breaks[2] - y_breaks[1]))
cat(sprintf("Mean tree count per cell: %.1f (min %d, max %d)\n",
            mean(cell_dat$Freq), min(cell_dat$Freq), max(cell_dat$Freq)))

glm_fit <- glm(Freq ~ elev + grad, data = cell_dat, family = poisson,
               offset = log(cell_area))
cat("\n--- Discretized Poisson GLM (cross-check on ppm) ---\n")
print(summary(glm_fit))
cat(sprintf("GLM AIC: %.1f  |  ppm(~elev+grad) AIC: %.1f\n",
            AIC(glm_fit), AIC(ppm_full)))
cat("(The two AICs are not on an identical scale -- ppm's is a Poisson\n")
cat(" process log-likelihood on continuous space, the GLM's is a\n")
cat(" binned Poisson-count log-likelihood -- but the fitted elev/grad\n")
cat(" coefficients should tell the same ecological story.)\n")

cell_dat$fitted_intensity <- fitted(glm_fit) / cell_dat$cell_area   # trees / m^2
cell_dat$observed_density <- cell_dat$Freq / cell_dat$cell_area

## ------------------------------------------------------------
## 4. Figure: observed tree density vs. fitted intensity surface
## ------------------------------------------------------------
png("figures/lecture_16_bei_intensity_surface.png", width = 1300, height = 620, res = 130)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 5))

nxb <- n_bins_x; nyb <- n_bins_y
obs_mat <- matrix(NA_real_, nrow = nxb, ncol = nyb)
fit_mat <- matrix(NA_real_, nrow = nxb, ncol = nyb)
for (i in seq_len(nrow(cell_dat))) {
  obs_mat[cell_dat$bin_x[i], cell_dat$bin_y[i]] <- cell_dat$observed_density[i]
  fit_mat[cell_dat$bin_x[i], cell_dat$bin_y[i]] <- cell_dat$fitted_intensity[i]
}
cell_x_ctr <- (x_breaks[-length(x_breaks)] + x_breaks[-1]) / 2
cell_y_ctr <- (y_breaks[-length(y_breaks)] + y_breaks[-1]) / 2

zlim <- range(c(obs_mat, fit_mat), na.rm = TRUE)
image(cell_x_ctr, cell_y_ctr, obs_mat, col = hcl.colors(50, "viridis"),
      zlim = zlim, xlab = "x (m)", ylab = "y (m)",
      main = "Observed tree density\n(trees / m^2)")
image(cell_x_ctr, cell_y_ctr, fit_mat, col = hcl.colors(50, "viridis"),
      zlim = zlim, xlab = "x (m)", ylab = "y (m)",
      main = "Fitted intensity\n(Poisson GLM ~ elev + grad)")
mtext("BEI 50-ha plot -- Beilschmiedia pendula, inhomogeneous point process",
      outer = FALSE, side = 3, line = -1.6, at = min(cell_x_ctr) - 250, cex = 0.9)
dev.off()
cat("\nFigure saved to figures/lecture_16_bei_intensity_surface.png\n")

cat("\nDone.\n")

# --- EXERCISES ---
# TODO 1: Recompute Moran's I for WatrCont using k = 3 and k = 10 nearest
#         neighbours instead of k = 5. Does the observed I, and its
#         permutation p-value, change much? What does that tell you about
#         the spatial scale at which water content is patchy at this site?
# TODO 2: Fit gam(WatrCont ~ s(x, y)) (already fit above as gam_spatial)
#         and produce a filled-contour or vis.gam() plot of the fitted
#         spatial surface. Where in the plot is water content highest?
#         Does that match any pattern you can see by colouring a
#         scatterplot of x, y by raw WatrCont?
# TODO 3: Refit the BEI point process with just ~ elev (ppm_elev above)
#         and compare its AIC to ~ elev + grad (ppm_full). Does gradient
#         add real explanatory power, or is elevation alone doing most of
#         the work? Cross-check your conclusion against the LRT above.
# TODO 4: The discretized Poisson GLM used 25 x 10 cells. Refit it with a
#         much coarser grid (e.g. 10 x 4) and a much finer grid (e.g.
#         50 x 20). How do the elev/grad coefficients and AIC change with
#         cell size? What are the tradeoffs of picking cells that are too
#         coarse vs. too fine for this kind of discretized approximation?
# TODO 5: Using the fitted ppm_full model, predict the intensity surface
#         with predict(ppm_full) and plot() it directly (spatstat's own
#         image method) -- compare this smooth, continuous-space surface
#         to the blocky discretized GLM surface saved in
#         figures/lecture_16_bei_intensity_surface.png. Which would you
#         trust more for identifying a specific hotspot location, and why?
