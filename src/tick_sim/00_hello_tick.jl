#
# Sim with global clock and tick!() actions
#

global δₜ = 1.0  # potential for a dynamically updated tick

mutable struct Clock
    start_time::Number
    time::Number
    function Clock()
        new(0.0, 0.0)
    end
    function Clock(tₛ)
        new(tₛ, tₛ)
    end
end

function tick!(c::Clock)
    c.time += δₜ
end

t₀ = 0.0
tₘₐₓ = 10
clock = Clock(t₀)

while clock.time < tₘₐₓ
    tick!(clock)
    println("The time is t = $(clock.time)")
end