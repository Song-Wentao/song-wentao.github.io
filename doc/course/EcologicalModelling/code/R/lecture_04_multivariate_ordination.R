# ============================================================
# Lecture 4 -- Multivariate and Ordination Methods
# Ecological Modelling with R, Python, and Julia
#
# Datasets:
#   data/varechem.csv + data/varespec.csv   (Vare, Ohtonen & Oksanen 1995,
#                                             J. Vegetation Science -- reindeer
#                                             grazing effects on lichen pastures)
#   data/dune_species.csv + data/dune_env.csv (Jongman, ter Braak & van Tongeren,
#                                             Dutch dune meadow vegetation survey)
#
# Methods:
#   1. PCA on soil chemistry (varechem)          -- prcomp()
#   2. NMDS on dune community data (Bray-Curtis)  -- vegan::metaMDS()
#   3. PERMANOVA: does Management explain dune community composition? -- vegan::adonis2()
#   4. Hierarchical clustering (average linkage) on the same dissimilarity
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_04_multivariate_ordination.R
# ============================================================

suppressMessages(library(vegan))

dir.create("figures", showWarnings = FALSE)

## ------------------------------------------------------------
## 1. PCA on soil chemistry -- data/varechem.csv
##    Why standardize: N, P, K, ... are on wildly different scales
##    (mg/kg vs pH units) so raw covariance PCA would be dominated
##    by whichever variable has the largest variance.
## ------------------------------------------------------------

varechem <- read.csv("data/varechem.csv", stringsAsFactors = FALSE)
rownames(varechem) <- varechem$site
chem <- varechem[, setdiff(names(varechem), "site")]

pca <- prcomp(chem, scale. = TRUE)

var_explained <- (pca$sdev^2) / sum(pca$sdev^2)
cat("=== Lecture 4: Multivariate & Ordination (R) ===\n\n")
cat("--- PCA on varechem (soil chemistry, 24 sites x 14 variables) ---\n")
cat("Variance explained by PC1-PC4:\n")
print(round(var_explained[1:4] * 100, 1))
cat("\nPC1 loadings (variable contributions):\n")
print(round(pca$rotation[, 1], 3))

## ------------------------------------------------------------
## 2. NMDS on dune community data (Bray-Curtis dissimilarity)
##    NMDS does not assume linear relationships between species and axes,
##    which is why it (not PCA) is the workhorse ordination method for
##    community abundance data with many zeros and nonlinear turnover.
## ------------------------------------------------------------

dune_species <- read.csv("data/dune_species.csv", stringsAsFactors = FALSE)
dune_env     <- read.csv("data/dune_env.csv",     stringsAsFactors = FALSE)

stopifnot(identical(as.character(dune_species$site), as.character(dune_env$site)))

sp_mat <- as.matrix(dune_species[, setdiff(names(dune_species), "site")])
rownames(sp_mat) <- dune_species$site

set.seed(42)
nmds <- metaMDS(sp_mat, distance = "bray", k = 2, trace = FALSE)

cat("\n--- NMDS on dune_species (Bray-Curtis, k = 2) ---\n")
cat("Stress:", round(nmds$stress, 4),
    "-- rule of thumb: <0.10 excellent, <0.20 usable, >0.20 risky\n")

## Ordination plot colored by Management
png("figures/lecture_04_dune_nmds.png", width = 1400, height = 1100, res = 150)
mgmt <- factor(dune_env$Management)
pal  <- c("BF" = "#2E6E8E", "HF" = "#C0562B", "NM" = "#3F8F5C", "SF" = "#8E5AA8")
plot(nmds, type = "n", main = "NMDS of Dune Meadow Vegetation (Bray-Curtis)")
points(nmds, display = "sites", pch = 19, col = pal[as.character(mgmt)], cex = 1.4)
ordihull(nmds, groups = mgmt, col = pal[levels(mgmt)], draw = "polygon", alpha = 40, label = FALSE)
text(nmds, display = "sites", labels = dune_env$site, pos = 3, cex = 0.7)
legend("topright", legend = names(pal), col = pal, pch = 19, title = "Management", bty = "n")
dev.off()
cat("Saved figures/lecture_04_dune_nmds.png\n")

## ------------------------------------------------------------
## 3. PERMANOVA -- does Management explain community composition?
##    adonis2() partitions variance in the dissimilarity matrix by
##    permuting group labels; it is the multivariate analogue of ANOVA
##    when the response is a distance matrix rather than a single variable.
## ------------------------------------------------------------

bc_dist <- vegdist(sp_mat, method = "bray")

set.seed(42)
perm <- adonis2(bc_dist ~ Management, data = dune_env, permutations = 999)

cat("\n--- PERMANOVA: bray-curtis distance ~ Management (999 permutations) ---\n")
print(perm)

## ------------------------------------------------------------
## 4. Hierarchical clustering (average linkage) -- complementary,
##    exploratory view of the same Bray-Curtis dissimilarity matrix.
## ------------------------------------------------------------

hc <- hclust(bc_dist, method = "average")

png("figures/lecture_04_dune_hclust.png", width = 1400, height = 900, res = 150)
plot(hc, main = "Average-linkage clustering of dune sites (Bray-Curtis)",
     xlab = "Site", sub = "", cex = 0.8)
dev.off()
cat("Saved figures/lecture_04_dune_hclust.png\n")

cat("\n=== Done ===\n")

# --- EXERCISES ---
# TODO 1: Run PCA on a subset of varechem variables (e.g. N, P, K, Ca, Mg, pH
#         only). Compare PC1 loadings and % variance explained to the
#         full-variable PCA above. Which variables dominate PC1?
# TODO 2: Refit the PERMANOVA using Moisture instead of Management
#         (adonis2(bc_dist ~ Moisture, data = dune_env)). Is the pseudo-F
#         larger or smaller than for Management? What does that imply?
# TODO 3: Re-run metaMDS() with k = 3 instead of k = 2. Does stress drop
#         substantially? Is the extra dimension worth the loss of a simple
#         2-D plot?
# TODO 4: Cut the hclust dendrogram into 4 groups (cutree(hc, k = 4)) and
#         cross-tabulate against dune_env$Management with table(). Do the
#         cluster groups line up with the management categories?
