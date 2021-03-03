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

# t₀ = 0.0
# tₘₐₓ = 10
# clock = Clock(t₀)

# while clock.time < tₘₐₓ
#     tick!(clock)
#     println("The time is t = $(clock.time)")
# end

mutable struct Traveler
    name::String
    src::String
    dst::String
    time_to_dst::Number
end

function status(T::Traveler)
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

function status(active::Array)
    for x in active
        status(x)
    end
end

function tick!(T::Traveler)
    T.time_to_dst -= δₜ
end

function tick!(active::Array)
    for x in active
        tick!(x)
    end
end

t₀ = 0.0
tₘₐₓ = 7
clock = Clock(t₀)

A = Traveler("α", "waiting", "point B", 8)  # Initially in orbit, waiting
B = Traveler("β", "point A", "point B", 4)

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



clock = Clock(t₀)
A = Traveler("α", "waiting", "point B", 8)  # Initially in orbit, waiting
B = Traveler("β", "point A", "point B", 4)

active = [clock, A]

tick!(active)

active



# Initial Node

