# Lecture 2 Exercises — Data Structures and Management

Work in whichever language(s) you are practicing (R, Python, or Julia). Use
the datasets in `data/`. Save any figures to `figures/` and give them
descriptive filenames.

## Exercise 1 — Richness by management (dune data)

Using `dune_species.csv` and `dune_env.csv`:

1. Compute species richness per site (the number of species with a nonzero
   count at that site).
2. Join the richness values to `dune_env.csv` by `site`.
3. Compute the mean richness for each `Management` category, sorted from
   highest to lowest.
4. In one or two sentences, describe which management type has the highest
   mean richness and speculate why that might be ecologically reasonable.

## Exercise 2 — Wide-to-long and back (mite data)

Using `mite_species.csv`:

1. Reshape the species matrix from wide format (site x species) to long
   format (`site`, `species`, `count`).
2. From the long-format table, compute the number of sites at which each
   species is present (count > 0), i.e. each species' *occupancy*.
3. Reshape your occupancy summary back into a wide table with one row and
   one column per species (or produce a sorted bar plot instead) and
   identify the three most widespread and three rarest species.

## Exercise 3 — Missing data workflow (varespec / varechem)

Using `varespec.csv` and `varechem.csv`:

1. Join the two tables by site.
2. Run an explicit missing-data check on every column (e.g. a count of
   `NA`/`NaN`/`missing` per column). Report whether the dataset is complete.
3. Artificially introduce missing values: set the `pH` value to missing for
   3 randomly chosen sites. Recompute the mean `pH` (a) ignoring missing
   values and (b) after dropping those rows entirely from the joined table.
   Do the two approaches agree? When would they *not* agree, and why does
   that matter for downstream models?

## Exercise 4 — Grouped summaries and derived variables (mite data)

Using `mite_species.csv` and `mite_env.csv`:

1. Join the species matrix to the environmental table by `site`.
2. Compute total abundance and species richness per site.
3. Group the joined table by `Topo` (hummock vs. blanket) and by `Shrub`
   (Few/Many/None) separately, and compute the mean and standard deviation
   of richness within each group.
4. Which grouping variable — `Substrate`, `Topo`, or `Shrub` — appears to
   explain the most variation in mean richness across its categories? Justify
   your answer using the summary tables you produced (a formal statistical
   test is not required — that's coming in Lecture 3).
