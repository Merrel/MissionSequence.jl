#
# Demonstrate various BETA distributions for testing
#

using Distributions
using Plots, StatsPlots

beta_pool = [
    Beta(1, 1),
    Beta(5, 5),
    Beta(2, 10),
    Beta(2, 50),
]

plot(title = "Various Beta Distributions")

for Β ∈ beta_pool
    plot!(Β, label=string(params(Β)))
end

current()


mode(Beta(2, 5))

mode(Beta(2, 50))

mode(Beta(2, 100))


quantile(Beta(2, 5), .05)
quantile(Beta(2, 5), .95)