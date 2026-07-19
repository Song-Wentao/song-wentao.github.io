# Ecological Modelling with R, Python, and Julia

A 16-lecture, lab-focused course. Every model is demonstrated in R, Python, AND Julia
on real data from published, peer-reviewed ecological research.

## Folder structure
- `slides/` — one self-contained HTML slide deck per lecture (open directly in any browser; arrow keys / click to navigate)
- `code/R/`, `code/python/`, `code/julia/` — one runnable script per lecture per language
- `exercises/` — a short practice sheet per lecture (no answers included, by design)
- `data/` — every real dataset used across the course, as CSV

## Running the code
All scripts assume the working directory is this folder (the repo root), e.g.:
```
Rscript code/R/lecture_05_linear_models.R
python3 code/python/lecture_05_linear_models.py
```
R and Python scripts in every lecture were actually executed against the real data during
development and run cleanly end to end. Julia scripts are written carefully and idiomatically
against the real package APIs but could not be executed in the build environment (no Julia
runtime was available there) — install Julia + the packages named at the top of each script to run them.

## Datasets (all real, all published)
See `SYLLABUS.md` for the full list with citations. Highlights: the Barro Colorado Island
50-hectare forest census (Condit, Hubbell & Foster 2002, *Science*), the oribatid mite community
data (Borcard & Legendre 1994, *Ecology*), the red grouse tick dataset (Elston et al. 2001,
*Parasitology* — a canonical GLMM teaching dataset), and the Hudson's Bay Company lynx trapping
records (analyzed in Stenseth et al., *Science*/*PNAS*).

One dataset (Lecture 11, occupancy models) is honestly labeled as simulated-but-calibrated to a
real published study design, because raw survey data wasn't reachable from the offline build
environment — see the lecture's provenance slide and script header for details. One (Lecture 14,
population matrix) uses representative values in the structure of a real, famous published study
(Crouse, Crowder & Caswell 1987) rather than claiming to reproduce its exact published numbers —
also clearly flagged in-slide and in-script.

## Lecture sequence
1. Introduction
2. Data Structures and Management
3. Basic Statistical Analysis
4. Multivariate and Ordination Methods
5. Linear Models
6. Generalized Linear Models
7. Mixed-Effects Models
8. Generalized Additive Models
9. Bayesian Hierarchical Models
10. Time Series and State-Space Models
11. Occupancy and N-mixture Models
12. Machine Learning
13. Species Distribution / Niche Models
14. Population Modeling
15. Community Ecology Models
16. Spatial Modeling
