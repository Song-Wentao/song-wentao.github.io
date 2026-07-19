"""
Lecture 14 -- Population Modeling
Structured (stage-based) matrix population models: Leslie/Lefkovitch
matrices, projection, the dominant eigenvalue (lambda), the stable stage
distribution, and elasticity analysis.

SYSTEM: loggerhead sea turtle (Caretta caretta) stage-structured population,
after Crouse, Crowder & Caswell (1987) "A stage-based population model for
loggerhead sea turtles and implications for conservation," Ecology 68(5),
1412-1423.

---------------------------------------------------------------------------
HONEST DATA PROVENANCE -- READ THIS BEFORE USING THESE NUMBERS FOR ANYTHING
---------------------------------------------------------------------------
The 5x5 matrix below is a RECONSTRUCTION, not a transcription. It was built
from memory to be representative of the stage structure, survival/growth
regime, and qualitative conclusions of Crouse, Crowder & Caswell (1987) --
a population dominated by low hatchling survival, increasing survival
through larger juvenile/subadult stages, high adult survival, modest adult
fecundity discounted by egg/hatchling mortality, and a resulting lambda
slightly below 1 (a declining population under status-quo, pre-Turtle-
Excluder-Device bycatch levels). The specific numeric entries are NOT
claimed to match the published matrix. For the exact published values,
consult the original paper: Crouse, Crowder & Caswell (1987), Ecology
68(5):1412-1423 (or Caswell's "Matrix Population Models" textbook, which
reproduces it as a worked example).
---------------------------------------------------------------------------

NOTE: Julia is not installed in the environment this lecture was authored
in, so this script could not be executed here. It is written carefully and
idiomatically from the documented LinearAlgebra / Plots APIs, mirroring the
R and Python versions line for line so it can be run and checked directly.
"""

using LinearAlgebra
using Plots

isdir("figures") || mkpath("figures")

# --- 1. THE STAGE-STRUCTURED (LEFKOVITCH) PROJECTION MATRIX ----------------
# Stages: 1 Eggs/Hatchlings, 2 Small juveniles (pelagic), 3 Large juveniles
# (benthic), 4 Subadults, 5 Adults (breeding females).
#
# Stasis (Pi) on the diagonal, growth into the next stage (Gi) on the
# subdiagonal below it -- standard Lefkovitch form for a stage-classified
# (not strictly age-classified) population, appropriate for sea turtles
# because growth rate to maturity varies substantially among individuals.
#
# Row 1 = fecundity contributions (eggs produced, already discounted to
# hatchlings) from subadults (small) and adults (larger, the main breeders).

stage_names = ["Eggs/Hatchlings", "Small Juv", "Large Juv", "Subadult", "Adult"]

A = [
    0.000  0.000  0.000  1.000  3.200;   # row 1: hatchling production
    0.675  0.643  0.000  0.000  0.000;   # row 2: egg->small juv survival; small juv stasis
    0.000  0.107  0.656  0.000  0.000;   # row 3: small->large juv growth; large juv stasis
    0.000  0.000  0.094  0.667  0.000;   # row 4: large juv->subadult growth; subadult stasis
    0.000  0.000  0.000  0.133  0.800    # row 5: subadult->adult growth; adult stasis
]

println("Projection matrix A (Lefkovitch form, columns = stage at t, rows = stage at t+1):")
for i in 1:5
    println(rpad(stage_names[i], 17), round.(A[i, :]; digits = 3))
end

# --- 2. DOMINANT EIGENVALUE (lambda) AND STABLE STAGE DISTRIBUTION ---------
ev = eigen(A)
dom_idx = argmax(real.(ev.values))
lambda = real(ev.values[dom_idx])

w = real.(ev.vectors[:, dom_idx])
w = w ./ sum(w)

println("\nDominant eigenvalue (asymptotic population growth rate) lambda = ", round(lambda; digits = 4))
if lambda < 1
    println("  -> lambda < 1: population is projected to DECLINE at status-quo rates.")
else
    println("  -> lambda >= 1: population is projected to grow or stay stable.")
end

println("\nStable stage distribution (proportion of individuals in each stage once")
println("the population settles into its long-run structure):")
for i in 1:5
    println(rpad(stage_names[i], 17), round(w[i]; digits = 4))
end

# --- 3. PROJECT THE POPULATION FORWARD ~30 YEARS ----------------------------
n_years = 30
# Arbitrary starting stage vector -- e.g. a small founder population skewed
# toward juveniles, as might be observed in a beach/in-water survey.
n0 = [5000.0, 1200.0, 600.0, 200.0, 100.0]

n_mat = zeros(5, n_years + 1)
n_mat[:, 1] = n0
for t in 1:n_years
    n_mat[:, t + 1] = A * n_mat[:, t]
end
total_n = vec(sum(n_mat; dims = 1))

println("\nTotal population size: year 0 = ", round(total_n[1]; digits = 0),
        ", year ", n_years, " = ", round(total_n[end]; digits = 0),
        " (ratio = ", round(total_n[end] / total_n[1]; digits = 3), ")")

# --- 4. FIGURE: population trajectory over the 30-year projection ----------
plt = plot(0:n_years, total_n,
    seriestype = :scatter, markershape = :circle,
    yscale = :log10,
    xlabel = "Year", ylabel = "Total population size (log scale)",
    title = "Projected loggerhead population (lambda = $(round(lambda; digits = 3)))",
    color = "#8B2500", legend = false)
plot!(plt, 0:n_years, total_n, seriestype = :line, color = "#8B2500")
savefig(plt, "figures/lecture_14_population_trajectory.png")
println("\nFigure saved to figures/lecture_14_population_trajectory.png")

# --- 5. ELASTICITY ANALYSIS -------------------------------------------------
# Elasticity of lambda to entry a_ij: the proportional change in lambda per
# proportional change in a_ij, evaluated numerically by finite difference
# (perturb one entry at a time, recompute lambda, no analytical eigenvector
# shortcut -- simple and transparent).

function lambda_of(mat)
    vals = eigvals(mat)
    return real(vals[argmax(real.(vals))])
end

lambda0 = lambda_of(A)
rel_step = 1e-4
E = zeros(5, 5)

for i in 1:5, j in 1:5
    aij = A[i, j]
    if aij != 0
        A_pert = copy(A)
        da = rel_step * aij
        A_pert[i, j] = aij + da
        lambda1 = lambda_of(A_pert)
        E[i, j] = (lambda1 - lambda0) / lambda0 / (da / aij)
    end
end

println("\nElasticity matrix (all nonzero entries sum to ~1.0):")
for i in 1:5
    println(rpad(stage_names[i], 17), round.(E[i, :]; digits = 4))
end
println("Sum of all elasticities (should be ~1): ", round(sum(E); digits = 4))

records = NamedTuple[]
for i in 1:5, j in 1:5
    if A[i, j] != 0
        push!(records, (from = stage_names[i], to = stage_names[j],
                         value = A[i, j], elasticity = E[i, j]))
    end
end
sort!(records, by = r -> r.elasticity, rev = true)

println("\nTop matrix entries ranked by elasticity:")
for r in records
    println(rpad(r.from, 17), " -> ", rpad(r.to, 17),
            "  value=", round(r.value; digits = 3),
            "  elasticity=", round(r.elasticity; digits = 4))
end

fecundity_elasticity = sum(E[1, :])
juvenile_survival_elasticity = E[2, 2] + E[3, 2] + E[3, 3] + E[4, 3] + E[4, 4]

println("\nTotal fecundity elasticity (row 1, egg production): ", round(fecundity_elasticity; digits = 4))
println("Total juvenile/subadult survival+growth elasticity: ", round(juvenile_survival_elasticity; digits = 4))
println("Interpretation: lambda is far more sensitive to juvenile/subadult survival")
println("than to fecundity -- this is the core Crouse/Crowder/Caswell (1987) result")
println("that redirected sea turtle conservation policy toward reducing bycatch")
println("mortality (Turtle Excluder Devices) rather than protecting nests alone.")

# --- EXERCISES ---
# TODO 1: Increase small-juvenile and large-juvenile survival (the stasis
#         entries A[2,2] and A[3,3], and the growth entries A[3,2], A[4,3])
#         by 10%, simulating widespread Turtle Excluder Device (TED)
#         adoption reducing bycatch mortality in shrimp trawls. Recompute
#         lambda. How much does lambda change relative to a 10% increase in
#         fecundity (A[1,5]) instead? Which intervention gets the population
#         closer to lambda = 1?
# TODO 2: Compute the stable stage distribution from the matrix as given.
#         Suppose a hypothetical beach/in-water survey instead observed
#         proportions roughly [0.10, 0.55, 0.20, 0.10, 0.05] across the five
#         stages. Compare this "observed" distribution to the stable stage
#         distribution -- is the real population closer to or farther from
#         its stable structure, and what would you expect to happen to total
#         population growth in the short term (transient dynamics) before it
#         settles toward the asymptotic lambda?
# TODO 3: Identify the single nonzero matrix entry with the highest
#         elasticity from the `records` table above. Is it a fecundity term,
#         a stasis (survival-in-place) term, or a growth (transition) term?
#         Explain in a sentence or two why a small proportional change in
#         that entry has an outsized effect on lambda.
# TODO 4: Re-run the 30-year projection starting from a population vector
#         weighted almost entirely toward adults (e.g. [100.0, 100.0, 100.0,
#         100.0, 5000.0]) instead of the juvenile-heavy starting vector used
#         above. Does the total population trajectory still converge to the
#         same asymptotic growth rate lambda? Plot both trajectories on the
#         same log-scale axes and describe what differs in the first few
#         years (transient dynamics) versus the long run.
