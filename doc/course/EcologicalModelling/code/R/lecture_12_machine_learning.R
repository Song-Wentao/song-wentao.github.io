# ============================================================
# Lecture 12 -- Machine Learning
# Ecological Modelling with R, Python, and Julia
#
# Dataset:
#   data/dune_species.csv (20 sites x 30 plant species abundance, wide
#                           format, first column "site")
#   data/dune_env.csv     (site, A1, Moisture, Management, Use, Manure)
#   Jongman, ter Braak & van Tongeren -- Dutch dune meadow vegetation survey.
#   A classic teaching dataset in the vegan/ade4 community-ecology literature.
#
# Task: predict Management regime (4 classes: BF = biological farming,
#       HF = hobby farming, NM = nature conservation, SF = standard
#       farming) from the plant species community matrix alone. This is a
#       genuinely ecological "predict site type from community
#       composition" classification problem -- exactly the kind of
#       many-predictor, unknown-functional-form, prediction-focused task
#       where machine learning earns its keep over a classical GLM.
#
# Methods:
#   1. Random Forest classifier (randomForest::randomForest) -- bagged
#      decision trees, out-of-bag (OOB) error, variable importance.
#   2. 5-fold cross-validation of the random forest to estimate
#      out-of-sample accuracy independently of the OOB estimate.
#   3. Gradient boosted trees on the same 4-class task, fit via
#      caret::train(method = "gbm") -- caret handles multiclass gbm
#      cleanly, which the bare gbm::gbm() multinomial interface does not
#      do as gracefully.
#   4. Variable (species) importance from both models, and a bar plot of
#      the top species from the random forest, saved to
#      figures/lecture_12_variable_importance.png.
#
# Honest caveat: with only 20 sites, 5-fold CV means ~4 sites per test
# fold -- accuracy estimates here are noisy and illustrate the *method*,
# not a claim of a reliable operational classifier.
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_12_machine_learning.R
# ============================================================

suppressMessages(library(randomForest))
suppressMessages(library(gbm))
suppressMessages(library(caret))

set.seed(12)
dir.create("figures", showWarnings = FALSE)

## ------------------------------------------------------------
## 0. Load and join species matrix with Management labels
## ------------------------------------------------------------
dune_sp  <- read.csv("data/dune_species.csv", stringsAsFactors = FALSE)
dune_env <- read.csv("data/dune_env.csv", stringsAsFactors = FALSE)

dat <- merge(dune_env[, c("site", "Management")], dune_sp, by = "site")
dat$Management <- factor(dat$Management)
dat$site <- NULL

cat("Sites:", nrow(dat), " Species predictors:", ncol(dat) - 1, "\n")
cat("Management class counts:\n")
print(table(dat$Management))

## ------------------------------------------------------------
## 1. Random Forest classifier
## ------------------------------------------------------------
rf_fit <- randomForest(
  Management ~ ., data = dat,
  ntree = 500, mtry = floor(sqrt(ncol(dat) - 1)),
  importance = TRUE
)

cat("\n--- Random Forest ---\n")
print(rf_fit)
cat("\nOOB confusion matrix:\n")
print(rf_fit$confusion)

oob_acc <- 1 - rf_fit$err.rate[nrow(rf_fit$err.rate), "OOB"]
cat(sprintf("\nOOB accuracy: %.3f\n", oob_acc))

## ------------------------------------------------------------
## 2. 5-fold cross-validation of the random forest
##    (an out-of-sample accuracy estimate that does NOT rely on OOB,
##     to teach the general CV concept explicitly)
## ------------------------------------------------------------
k <- 5
n <- nrow(dat)
folds <- sample(rep(1:k, length.out = n))

cv_acc <- numeric(k)
for (i in 1:k) {
  train_dat <- dat[folds != i, ]
  test_dat  <- dat[folds == i, ]
  fit_i <- randomForest(Management ~ ., data = train_dat,
                         ntree = 500,
                         mtry = floor(sqrt(ncol(dat) - 1)))
  pred_i <- predict(fit_i, newdata = test_dat)
  cv_acc[i] <- mean(pred_i == test_dat$Management)
}

cat("\n--- 5-fold CV (Random Forest) ---\n")
cat("Per-fold accuracy:", round(cv_acc, 3), "\n")
cat(sprintf("Mean CV accuracy: %.3f (SD %.3f)\n", mean(cv_acc), sd(cv_acc)))
cat("NOTE: with 20 sites split 5 ways, each test fold has only ~4 sites --\n")
cat("      these accuracy numbers are illustrative of the method, not a\n")
cat("      precise, low-variance estimate.\n")

## ------------------------------------------------------------
## 3. Gradient boosted trees (caret::train, method = "gbm")
##    caret handles multiclass gbm with its own internal CV for tuning.
## ------------------------------------------------------------
ctrl <- trainControl(method = "cv", number = 5, classProbs = FALSE)

gbm_fit <- train(
  Management ~ ., data = dat,
  method = "gbm",
  trControl = ctrl,
  verbose = FALSE,
  tuneGrid = expand.grid(
    n.trees = c(50, 100),
    interaction.depth = c(1, 2),
    shrinkage = 0.1,
    n.minobsinnode = 2
  )
)

cat("\n--- Gradient Boosted Trees (caret::gbm) ---\n")
print(gbm_fit)
cat(sprintf("\nBest CV accuracy (GBM): %.3f\n",
            max(gbm_fit$results$Accuracy)))

gbm_pred <- predict(gbm_fit, newdata = dat)
cat("\nTraining confusion matrix (GBM, for illustration only):\n")
print(table(Predicted = gbm_pred, Observed = dat$Management))

## ------------------------------------------------------------
## 4. Variable (species) importance
## ------------------------------------------------------------
rf_imp <- importance(rf_fit)
rf_imp_df <- data.frame(
  species = rownames(rf_imp),
  MeanDecreaseAccuracy = rf_imp[, "MeanDecreaseAccuracy"],
  MeanDecreaseGini = rf_imp[, "MeanDecreaseGini"]
)
rf_imp_df <- rf_imp_df[order(-rf_imp_df$MeanDecreaseGini), ]

cat("\nTop 8 species by Random Forest importance (Mean Decrease Gini):\n")
print(head(rf_imp_df, 8), row.names = FALSE)

gbm_imp <- summary(gbm_fit$finalModel, plotit = FALSE)
cat("\nTop 8 species by GBM relative influence:\n")
print(head(gbm_imp, 8), row.names = FALSE)

## ------------------------------------------------------------
## 5. Plot: top species by Random Forest importance
## ------------------------------------------------------------
top10 <- head(rf_imp_df, 10)
top10 <- top10[order(top10$MeanDecreaseGini), ]  # ascending for barplot

png("figures/lecture_12_variable_importance.png", width = 900, height = 650,
    res = 120)
par(mar = c(5, 8, 4, 2))
barplot(top10$MeanDecreaseGini, names.arg = top10$species, horiz = TRUE,
        las = 1, col = "#2b8cbe",
        xlab = "Mean Decrease in Gini Impurity",
        main = "Random Forest Variable Importance\n(dune species, predicting Management)")
dev.off()

cat("\nFigure saved to figures/lecture_12_variable_importance.png\n")

# --- EXERCISES ---
# TODO 1: Refit the random forest with a grid of ntree (e.g. 100, 500, 1500)
#         and mtry (e.g. 2, 5, 10, 29) values. Plot OOB error vs. ntree for
#         each mtry and report which combination minimizes OOB error.
# TODO 2: Compare Random Forest vs. GBM out-of-sample accuracy using the
#         SAME 5-fold CV splits (reuse the `folds` vector above) so the
#         comparison is apples-to-apples rather than each model using its
#         own random split.
# TODO 3: Plot and interpret the top-5 most important species for
#         classifying Management -- look up what each species indicates
#         ecologically (e.g. nutrient tolerance, grazing tolerance) and
#         discuss whether the importance ranking matches ecological
#         intuition about the four Management regimes.
# TODO 4: Repeat the random forest and CV analysis on the BCI dataset
#         (data/BCI_species.csv, data/BCI_env.csv) using a REGRESSION
#         random forest (randomForest with a numeric response) to predict
#         a continuous environmental variable from tree species
#         composition. Compare R-squared (from CV predictions) to what a
#         linear model achieves on the same data.
