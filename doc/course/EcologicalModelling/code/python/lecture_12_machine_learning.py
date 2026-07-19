"""
Lecture 12 -- Machine Learning
Ecological Modelling with R, Python, and Julia

Dataset:
    data/dune_species.csv (20 sites x 30 plant species abundance, wide
                            format, first column "site")
    data/dune_env.csv     (site, A1, Moisture, Management, Use, Manure)
    Jongman, ter Braak & van Tongeren -- Dutch dune meadow vegetation survey.

Task: predict Management regime (4 classes: BF = biological farming,
      HF = hobby farming, NM = nature conservation, SF = standard farming)
      from the plant species community matrix alone -- an ecological
      "predict site type from community composition" classification task,
      the kind of many-predictor, unknown-functional-form, prediction-
      focused problem where machine learning is preferred over a
      classical GLM.

Methods:
    1. Random Forest classifier (sklearn.ensemble.RandomForestClassifier)
       -- bagged decision trees, out-of-bag (OOB) score, variable
       importance (mean decrease in impurity).
    2. 5-fold cross-validation (sklearn.model_selection.cross_val_score)
       of the random forest to estimate out-of-sample accuracy
       independently of the OOB estimate.
    3. Gradient Boosted Trees (sklearn.ensemble.GradientBoostingClassifier)
       on the same 4-class task.
    4. Confusion matrices (sklearn.metrics.confusion_matrix) and variable
       importance from both models; bar plot of the top species from the
       random forest, saved to figures/lecture_12_variable_importance.png.

Honest caveat: with only 20 sites, 5-fold CV means ~4 sites per test
fold -- accuracy estimates here are noisy and illustrate the *method*,
not a claim of a reliable operational classifier.

Assumes working directory = repository root, i.e. run as:
    python3 code/python/lecture_12_machine_learning.py
"""

import os

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.model_selection import cross_val_score, StratifiedKFold, KFold
from sklearn.metrics import confusion_matrix, accuracy_score

RNG = np.random.RandomState(12)
os.makedirs("figures", exist_ok=True)

## ------------------------------------------------------------
## 0. Load and join species matrix with Management labels
## ------------------------------------------------------------
dune_sp = pd.read_csv("data/dune_species.csv")
dune_env = pd.read_csv("data/dune_env.csv")

dat = dune_env[["site", "Management"]].merge(dune_sp, on="site")
dat = dat.drop(columns=["site"])

species_cols = [c for c in dat.columns if c != "Management"]
X = dat[species_cols].values
y = dat["Management"].values

print(f"Sites: {X.shape[0]}  Species predictors: {X.shape[1]}")
print("Management class counts:")
print(dat["Management"].value_counts())

## ------------------------------------------------------------
## 1. Random Forest classifier
## ------------------------------------------------------------
rf = RandomForestClassifier(
    n_estimators=500,
    max_features="sqrt",
    oob_score=True,
    random_state=12,
)
rf.fit(X, y)

print("\n--- Random Forest ---")
print(f"OOB accuracy: {rf.oob_score_:.3f}")

rf_pred_train = rf.predict(X)
cm_train = confusion_matrix(y, rf_pred_train, labels=rf.classes_)
print("Training confusion matrix (for illustration -- see CV below for an\n"
      "honest out-of-sample estimate):")
print(pd.DataFrame(cm_train, index=rf.classes_, columns=rf.classes_))

## ------------------------------------------------------------
## 2. 5-fold cross-validation of the random forest
##    (an out-of-sample accuracy estimate that does NOT rely on OOB,
##     to teach the general CV concept explicitly)
## ------------------------------------------------------------
cv = KFold(n_splits=5, shuffle=True, random_state=12)
rf_cv_scores = cross_val_score(
    RandomForestClassifier(n_estimators=500, max_features="sqrt",
                            random_state=12),
    X, y, cv=cv, scoring="accuracy",
)

print("\n--- 5-fold CV (Random Forest) ---")
print("Per-fold accuracy:", np.round(rf_cv_scores, 3))
print(f"Mean CV accuracy: {rf_cv_scores.mean():.3f} "
      f"(SD {rf_cv_scores.std():.3f})")
print("NOTE: with 20 sites split 5 ways, each test fold has only ~4 sites --")
print("      these accuracy numbers are illustrative of the method, not a")
print("      precise, low-variance estimate.")

## ------------------------------------------------------------
## 3. Gradient Boosted Trees on the same task
## ------------------------------------------------------------
gbm = GradientBoostingClassifier(
    n_estimators=100,
    max_depth=1,
    learning_rate=0.1,
    random_state=12,
)
gbm.fit(X, y)

gbm_cv_scores = cross_val_score(
    GradientBoostingClassifier(n_estimators=100, max_depth=1,
                                learning_rate=0.1, random_state=12),
    X, y, cv=cv, scoring="accuracy",
)

print("\n--- Gradient Boosted Trees ---")
print("Per-fold accuracy:", np.round(gbm_cv_scores, 3))
print(f"Mean CV accuracy (GBM): {gbm_cv_scores.mean():.3f} "
      f"(SD {gbm_cv_scores.std():.3f})")

gbm_pred_train = gbm.predict(X)
cm_gbm_train = confusion_matrix(y, gbm_pred_train, labels=gbm.classes_)
print("\nTraining confusion matrix (GBM, for illustration only):")
print(pd.DataFrame(cm_gbm_train, index=gbm.classes_, columns=gbm.classes_))

## ------------------------------------------------------------
## 4. Variable (species) importance
## ------------------------------------------------------------
rf_importance = pd.Series(rf.feature_importances_, index=species_cols)
rf_importance = rf_importance.sort_values(ascending=False)

print("\nTop 8 species by Random Forest importance (mean decrease impurity):")
print(rf_importance.head(8))

gbm_importance = pd.Series(gbm.feature_importances_, index=species_cols)
gbm_importance = gbm_importance.sort_values(ascending=False)

print("\nTop 8 species by GBM importance:")
print(gbm_importance.head(8))

## ------------------------------------------------------------
## 5. Plot: top species by Random Forest importance
## ------------------------------------------------------------
top10 = rf_importance.head(10).sort_values()

fig, ax = plt.subplots(figsize=(8, 6))
ax.barh(top10.index, top10.values, color="#2b8cbe")
ax.set_xlabel("Mean Decrease in Impurity (Gini importance)")
ax.set_title("Random Forest Variable Importance\n"
              "(dune species, predicting Management)")
fig.tight_layout()
fig.savefig("figures/lecture_12_variable_importance.png", dpi=120)
plt.close(fig)

print("\nFigure saved to figures/lecture_12_variable_importance.png")

# --- EXERCISES ---
# TODO 1: Refit the random forest with a grid of n_estimators (e.g. 100,
#         500, 1500) and max_features (e.g. 2, 5, 10, "sqrt", 29) values.
#         Plot rf.oob_score_ vs. n_estimators for each max_features and
#         report which combination maximizes OOB accuracy.
# TODO 2: Compare Random Forest vs. GBM out-of-sample accuracy using the
#         SAME cv splitter object (`cv` above) so the comparison is
#         apples-to-apples rather than each model using its own random
#         split.
# TODO 3: Plot and interpret the top-5 most important species for
#         classifying Management -- look up what each species indicates
#         ecologically (e.g. nutrient tolerance, grazing tolerance) and
#         discuss whether the importance ranking matches ecological
#         intuition about the four Management regimes.
# TODO 4: Repeat the random forest and CV analysis on the BCI dataset
#         (data/BCI_species.csv, data/BCI_env.csv) using
#         RandomForestRegressor to predict a continuous environmental
#         variable from tree species composition. Compare R-squared
#         (from cross_val_score with scoring="r2") to what a linear
#         model achieves on the same data.
