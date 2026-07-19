# =============================================================================
# Lecture 1: Introduction -- "Hello Data" demonstration (R)
# Ecological Modelling with R, Python, and Julia
#
# Dataset: Oribatid mite community, Lac Cromwell peat blanket
#          Borcard & Legendre (1994), Ecology 75(4)
#
# Convention used all semester:
#   - Run scripts with the working directory set to the repository root
#     (i.e. the folder that contains data/, code/, figures/, exercises/).
#   - Read inputs from   data/<file>.csv
#   - Write figures to   figures/lecture_NN_<slug>.png
# =============================================================================

# ---- 1. Load data -----------------------------------------------------------
# Base R: read.csv() returns a data.frame; strings are not auto-factored
# in modern R (>= 4.0), which is what we want here.
species <- read.csv("data/mite_species.csv", stringsAsFactors = FALSE)
env     <- read.csv("data/mite_env.csv",     stringsAsFactors = FALSE)

# Tidyverse equivalent for reading both files:
#   species <- readr::read_csv("data/mite_species.csv")
#   env     <- readr::read_csv("data/mite_env.csv")

# ---- 2. Compute total abundance per site ------------------------------------
# The first column is the site identifier; all remaining columns are species
# counts. Row-summing the species columns gives total abundance per site.
species_cols   <- setdiff(names(species), "site")
total_abund    <- rowSums(species[, species_cols])

abundance_df <- data.frame(
  site          = species$site,
  total_abund   = total_abund
)

# Tidyverse equivalent:
#   abundance_df <- species |>
#     dplyr::mutate(total_abund = rowSums(dplyr::across(-site))) |>
#     dplyr::select(site, total_abund)

# ---- 3. Join to environmental data on site ----------------------------------
mite <- merge(abundance_df, env, by = "site")

# Tidyverse equivalent:
#   mite <- dplyr::left_join(abundance_df, env, by = "site")

# ---- 4. Summary statistics ---------------------------------------------------
cat("=== Lecture 1: Hello Data (R) ===\n")
cat(sprintf("Sites joined: %d\n", nrow(mite)))

watr_mean <- mean(mite$WatrCont)
watr_sd   <- sd(mite$WatrCont)
cat(sprintf("Water content (WatrCont): mean = %.2f, sd = %.2f\n", watr_mean, watr_sd))

abund_mean <- mean(mite$total_abund)
abund_sd   <- sd(mite$total_abund)
cat(sprintf("Total abundance: mean = %.2f, sd = %.2f\n", abund_mean, abund_sd))

r_val <- cor(mite$total_abund, mite$WatrCont)
cat(sprintf("Correlation(total abundance, WatrCont) = %.3f\n", r_val))

# ---- 5. Plot: total abundance vs. water content ------------------------------
dir.create("figures", showWarnings = FALSE)

png("figures/lecture_01_abundance_vs_watercontent.png", width = 900, height = 700, res = 130)
plot(
  mite$WatrCont, mite$total_abund,
  pch = 19, col = "#2E6E8E",
  xlab = "Water content (WatrCont, g/L substrate)",
  ylab = "Total mite abundance (individuals per core)",
  main = "Mite abundance vs. substrate water content\nLac Cromwell (Borcard & Legendre 1994)"
)
abline(lm(total_abund ~ WatrCont, data = mite), col = "firebrick", lwd = 2)
dev.off()

cat("Saved figures/lecture_01_abundance_vs_watercontent.png\n")

# =============================================================================
# --- EXERCISES ---
# TODO 1: Repeat this analysis using SubsDens (substrate density) instead of
#         WatrCont. Is the correlation with total abundance stronger or weaker?
# TODO 2: Compute total abundance separately for each level of Shrub
#         (None/Few/Many) and compare the group means.
# TODO 3: Identify the single most abundant species overall (largest column
#         sum in mite_species.csv) and plot its abundance against WatrCont.
# =============================================================================
