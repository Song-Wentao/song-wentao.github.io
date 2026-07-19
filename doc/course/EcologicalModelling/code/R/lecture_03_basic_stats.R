# =============================================================================
# Lecture 3: Basic Statistical Analysis (R)
# Ecological Modelling with R, Python, and Julia
#
# Datasets:
#   mite_env.csv  -- Borcard & Legendre (1994), Ecology 75(4), oribatid mites
#   varechem.csv  -- Vare, Ohtonen & Oksanen (1995), J. Vegetation Science
#
# Convention used all semester:
#   - Run scripts with the working directory set to the repository root
#     (i.e. the folder that contains data/, code/, figures/, exercises/).
#   - Read inputs from   data/<file>.csv
#   - Write figures to   figures/lecture_NN_<slug>.png
# =============================================================================

mite <- read.csv("data/mite_env.csv", stringsAsFactors = FALSE)
mite$Substrate <- factor(mite$Substrate)

cat("=== Lecture 3: Basic Statistical Analysis (R) ===\n\n")

# ---- 1. Descriptive statistics: mean / sd / CV ------------------------------
cv <- function(x) sd(x) / mean(x) * 100

cat("--- Descriptive statistics (mite_env.csv) ---\n")
for (v in c("WatrCont", "SubsDens")) {
  x <- mite[[v]]
  cat(sprintf(
    "%-10s: mean = %8.2f  median = %8.2f  sd = %8.2f  CV = %6.1f%%\n",
    v, mean(x), median(x), sd(x), cv(x)
  ))
}
cat("\n")
# Ecological note: counts, cover, and biomass are frequently right-skewed
# (many small values, a few large ones) -> mean > median, CV often > 50-100%.
# Always inspect the distribution (histogram/boxplot) before assuming normality.

# ---- 2. Two-sample t-test: WatrCont between two Substrate groups ------------
# Compare "Sphagn1" vs "Litter" as an illustrative two-group comparison.
sub_a <- mite$WatrCont[mite$Substrate == "Sphagn1"]
sub_b <- mite$WatrCont[mite$Substrate == "Litter"]

t_res <- t.test(sub_a, sub_b)
cat("--- Two-sample t-test: WatrCont, Sphagn1 vs Litter ---\n")
cat(sprintf("t = %.3f, df = %.1f, p-value = %.4f\n",
            t_res$statistic, t_res$parameter, t_res$p.value))
cat(sprintf("Mean Sphagn1 = %.2f, Mean Litter = %.2f\n\n",
            mean(sub_a), mean(sub_b)))

# ---- 3. One-way ANOVA: WatrCont ~ Substrate (all levels) --------------------
aov_fit <- aov(WatrCont ~ Substrate, data = mite)
aov_summary <- summary(aov_fit)
cat("--- One-way ANOVA: WatrCont ~ Substrate ---\n")
print(aov_summary)

f_stat  <- aov_summary[[1]]["Substrate", "F value"]
p_val   <- aov_summary[[1]]["Substrate", "Pr(>F)"]
ss_sub  <- aov_summary[[1]]["Substrate", "Sum Sq"]
ss_tot  <- sum(aov_summary[[1]][, "Sum Sq"])
eta_sq  <- ss_sub / ss_tot
r_sq    <- summary.lm(aov_fit)$r.squared

cat(sprintf("\nF = %.3f, p-value = %.5f\n", f_stat, p_val))
cat(sprintf("eta-squared = %.3f, R^2 (equivalent for one-way ANOVA) = %.3f\n\n",
            eta_sq, r_sq))

# ---- 4. Post-hoc: Tukey HSD --------------------------------------------------
cat("--- Tukey HSD post-hoc comparisons ---\n")
tukey_res <- TukeyHSD(aov_fit)
print(tukey_res)
cat("\n")

# ---- 5. Correlation matrix: soil chemistry (varechem.csv) -------------------
varechem <- read.csv("data/varechem.csv", stringsAsFactors = FALSE)
chem_vars <- c("N", "P", "K", "Ca", "Mg", "pH")
chem_sub  <- varechem[, chem_vars]

cor_pearson <- cor(chem_sub, method = "pearson")
cat("--- Pearson correlation matrix (N, P, K, Ca, Mg, pH) ---\n")
print(round(cor_pearson, 3))
cat("\n")

cor_spearman <- cor(chem_sub, method = "spearman")
cat("--- Spearman correlation matrix (N, P, K, Ca, Mg, pH) ---\n")
print(round(cor_spearman, 3))
cat("\n")

# Single-pair example with a test statistic and p-value
pear_np <- cor.test(varechem$N, varechem$P, method = "pearson")
cat(sprintf("cor.test(N, P) Pearson: r = %.3f, p-value = %.4f\n\n",
            pear_np$estimate, pear_np$p.value))

# ---- 6. Chi-square test of independence: Shrub x Topo -----------------------
shrub_topo_tab <- table(mite$Shrub, mite$Topo)
cat("--- Contingency table: Shrub x Topo ---\n")
print(shrub_topo_tab)

chi_res <- chisq.test(shrub_topo_tab)
cat(sprintf("\nChi-square = %.3f, df = %d, p-value = %.4f\n\n",
            chi_res$statistic, chi_res$parameter, chi_res$p.value))

# ---- 7. Figure: boxplot of WatrCont by Substrate -----------------------------
dir.create("figures", showWarnings = FALSE)

png("figures/lecture_03_watercontent_by_substrate.png",
    width = 1000, height = 700, res = 130)
par(mar = c(8, 4, 4, 1))
boxplot(
  WatrCont ~ Substrate, data = mite,
  las = 2, xlab = "", ylab = "Water content (WatrCont, g/L substrate)",
  main = "Water content by substrate type\nLac Cromwell (Borcard & Legendre 1994)",
  col = "#8FBFDB"
)
dev.off()

cat("Saved figures/lecture_03_watercontent_by_substrate.png\n")

# =============================================================================
# --- EXERCISES ---
# TODO 1: Run a two-sample t-test comparing SubsDens (substrate density)
#         between two Substrate groups of your choice (e.g. "Litter" vs
#         "Barepeat"). Report t, df, and p-value.
# TODO 2: Run a one-way ANOVA of SubsDens ~ Substrate across all Substrate
#         levels. Follow up with a Tukey HSD test -- which pairs differ
#         significantly?
# TODO 3: Compute the Pearson and Spearman correlation between Humdepth and
#         pH in varechem.csv. Do the two correlation coefficients agree?
# TODO 4: Build a contingency table of Shrub x Substrate from mite_env.csv
#         and run a chi-square test of independence. Interpret the result.
# =============================================================================
