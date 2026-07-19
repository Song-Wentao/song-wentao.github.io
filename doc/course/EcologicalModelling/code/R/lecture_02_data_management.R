# ============================================================
# Lecture 2 -- Data Structures and Management
# Ecological Modelling with R, Python, and Julia
#
# Datasets:
#   data/mite_species.csv + data/mite_env.csv   (Borcard & Legendre 1994)
#   data/dune_species.csv + data/dune_env.csv   (Jongman, ter Braak & van Tongeren)
#
# Assumes working directory = repository root, i.e. run as:
#   Rscript code/R/lecture_02_data_management.R
# ============================================================

## ------------------------------------------------------------
## 1. Load data
## ------------------------------------------------------------

mite_species <- read.csv("data/mite_species.csv", stringsAsFactors = FALSE)
mite_env     <- read.csv("data/mite_env.csv",     stringsAsFactors = FALSE)

dune_species <- read.csv("data/dune_species.csv", stringsAsFactors = FALSE)
dune_env     <- read.csv("data/dune_env.csv",     stringsAsFactors = FALSE)

cat("mite_species:", nrow(mite_species), "sites x", ncol(mite_species) - 1, "species\n")
cat("mite_env    :", nrow(mite_env), "rows x", ncol(mite_env), "columns\n")

## ------------------------------------------------------------
## 2. Missing-data check
##    (Real field surveys are rarely fully complete -- always check,
##    even when you expect a clean textbook dataset like this one.)
## ------------------------------------------------------------

cat("\n--- Missing data check ---\n")
cat("NAs in mite_species:", sum(is.na(mite_species)), "\n")
cat("NAs in mite_env    :", sum(is.na(mite_env)), "\n")
# Column-wise breakdown -- useful for deciding drop vs. impute
na_by_col <- colSums(is.na(mite_env))
print(na_by_col[na_by_col > 0])  # empty here: dataset is complete

## ------------------------------------------------------------
## 3. Join species matrix to environmental covariates (mite data)
## ------------------------------------------------------------

mite_joined <- merge(mite_species, mite_env, by = "site")

# tidyverse equivalent:
# mite_joined <- mite_species |> dplyr::left_join(mite_env, by = "site")

## ------------------------------------------------------------
## 4. Derived variables: total abundance and species richness
## ------------------------------------------------------------

sp_cols <- setdiff(names(mite_species), "site")

mite_joined$total_abundance <- rowSums(mite_joined[, sp_cols])
mite_joined$richness        <- rowSums(mite_joined[, sp_cols] > 0)

cat("\n--- Derived variables (head) ---\n")
print(head(mite_joined[, c("site", "Substrate", "total_abundance", "richness")]))

## ------------------------------------------------------------
## 5. Group + summarize: mean richness/abundance by Substrate
## ------------------------------------------------------------

richness_by_substrate <- aggregate(
  cbind(richness, total_abundance) ~ Substrate,
  data = mite_joined,
  FUN  = mean
)
names(richness_by_substrate)[2:3] <- c("mean_richness", "mean_abundance")
richness_by_substrate <- richness_by_substrate[order(-richness_by_substrate$mean_richness), ]

# tidyverse equivalent:
# richness_by_substrate <- mite_joined |>
#   dplyr::group_by(Substrate) |>
#   dplyr::summarize(mean_richness = mean(richness),
#                     mean_abundance = mean(total_abundance))

cat("\n--- Mean richness & abundance by Substrate ---\n")
print(richness_by_substrate)

## ------------------------------------------------------------
## 6. Wide-to-long reshape (dune species matrix)
## ------------------------------------------------------------

dune_long <- reshape(
  dune_species,
  direction  = "long",
  varying    = setdiff(names(dune_species), "site"),
  v.names    = "count",
  timevar    = "species",
  times      = setdiff(names(dune_species), "site"),
  idvar      = "site"
)
dune_long <- dune_long[order(dune_long$site, dune_long$species), c("site", "species", "count")]
rownames(dune_long) <- NULL

# tidyverse equivalent:
# dune_long <- dune_species |>
#   tidyr::pivot_longer(-site, names_to = "species", values_to = "count")

cat("\n--- Dune species matrix reshaped wide -> long (head) ---\n")
print(head(dune_long, 10))

## ------------------------------------------------------------
## 7. Dune worked example: richness, join to dune_env, group by Management
## ------------------------------------------------------------

dune_sp_cols <- setdiff(names(dune_species), "site")
dune_species$richness <- rowSums(dune_species[, dune_sp_cols] > 0)

dune_joined <- merge(dune_species[, c("site", "richness")], dune_env, by = "site")

richness_by_mgmt <- aggregate(richness ~ Management, data = dune_joined, FUN = mean)
names(richness_by_mgmt)[2] <- "mean_richness"

cat("\n--- Dune: mean richness by Management ---\n")
print(richness_by_mgmt)

## ------------------------------------------------------------
## 8. Figure: mean richness by substrate (mite data)
## ------------------------------------------------------------

if (!dir.exists("figures")) dir.create("figures", recursive = TRUE)

png("figures/lecture_02_richness_by_substrate.png", width = 1000, height = 700, res = 120)
op <- par(mar = c(8, 4, 3, 1))
bar_order <- order(-richness_by_substrate$mean_richness)
bp <- barplot(
  richness_by_substrate$mean_richness[bar_order],
  names.arg = richness_by_substrate$Substrate[bar_order],
  las     = 2,
  col     = "#0e7c86",
  border  = NA,
  ylab    = "Mean species richness",
  main    = "Mean Oribatid Mite Species Richness by Substrate"
)
par(op)
dev.off()

cat("\nFigure saved to figures/lecture_02_richness_by_substrate.png\n")
cat("\nDone.\n")

# --- EXERCISES ---
# 1. TODO: Compute species richness per site in the dune dataset and merge
#    with dune_env. Find the mean richness by Management type.
#    (Partially demonstrated above -- extend to explore Use and Manure too.)
#
# 2. TODO: Load varespec.csv and varechem.csv. Join them by site (row order/id),
#    compute total abundance per site, and report the correlation between
#    total abundance and soil pH.
#
# 3. TODO: Reshape mite_species.csv from wide to long format. Then compute,
#    for each species, the number of sites in which it is present (nonzero).
#    Which species is the most widespread?
#
# 4. TODO: In the mite_env data, introduce artificial missing values into
#    WatrCont for 5 random sites (set to NA). Compare the mean of WatrCont
#    computed with and without na.rm = TRUE, and discuss when it would be
#    appropriate to drop vs. impute those rows.
