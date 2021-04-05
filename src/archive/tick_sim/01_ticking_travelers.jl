#
# Sim with global clock, tick!() actions and Elements
#

global δₜ = 1.0  # potential for a dynamically updated tick

###############################################################################
# Clock

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

###############################################################################
# Element

mutable struct Element
    name::String
    src::String
    dst::String
    time_to_dst::Number
end

function tick!(T::Element)
    T.time_to_dst -= δₜ
end

function status(T::Element)
    if T.time_to_dst > 0
        println("  $(T.name):\tTraveling from $(T.src) -> $(T.dst)")
    elseif T.time_to_dst == 0
        println("  $(T.name):\tArrived at $(T.dst)")
    else
        @error("$(T.name):  Travler clock is negative")
    end
end

function status(c::Clock)
    println("The time is t = $(c.time)")
end

###############################################################################
# Arrays of Tickable types

function status(active::Array)
    for x in active
        status(x)
    end
end

function tick!(active::Array)
    for x in active
        tick!(x)
    end
end

###############################################################################
# Demo Sim

t₀ = 0.0
tₘₐₓ = 7
clock = Clock(t₀)

A = Element("α", "waiting", "point B", 8)  # Initially in orbit, waiting
B = Element("β", "point A", "point B", 4)

active = [clock, A]  # Clock is always active; A starts active (waiting in orbit)

while clock.time < tₘₐₓ
    tick!(active)
    if clock.time == 2
        push!(active, B)  # Start the other element
    end
    # Check status
    status(active)
    println("-------------------------------------------\n")
end
