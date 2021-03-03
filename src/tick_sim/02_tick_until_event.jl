#
# Sim with global clock, tick!() actions and Elements
#

include("Events.jl")

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

function status(c::Clock)
    println("The time is t = $(c.time)")
end

current_event_completed(c::Clock) = false

###############################################################################
# Element

mutable struct Element
    name::String
    current_event::AbstractEvent
    next_event::AbstractEvent
    time_to_next::Number

    function Element(name, current_event, next_event)
        new(name, current_event, next_event, NaN)
    end
end

function tick!(E::Element)
    E.time_to_next -= δₜ
end

function status(E::Element)
    if E.time_to_next > 0
        println("  $(E.name):\t Current=$(E.current_event.name) --> Next=$(E.next_event.name)")
    elseif E.time_to_next == 0
        println("  $(E.name):\tCompleted $(E.current_event.name)")
    else
        @error("$(E.name):  Element clock is negative")
    end
end

function set_duration_from_current!(E::Element)
    E.time_to_next = E.current_event.duration
end

function current_event_completed(E::Element)
    if E.time_to_next > 0
        return false
    else
        return true
    end
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

# Define the events in the sim; these make up a directed graph

launch_α = Event(
    101,
    "launch_α",
    0.9,
    Dict(:pass => 102, :fail => :LOM),
    3
)

orbit_α = Event(
    102,
    "orbit_α",
    0.9,
    Dict(:pass => 103, :fail => :LOM),
    5
)

# Now start the sim by generating an element to traverse the graph
if attempt(launch_α) == :pass
    α = Element("α", launch_α, orbit_α)
    set_duration_from_current!(α)
    @info "Successful Launch"
else
    @error "Failed Launch"
end

# Now the Element is traversing an edge of the graph between events
status(α)

# There is a time required to travese the edge
@info "Time until next event: $(α.time_to_next)"

# Define a sim to tick!() forward in time until the event is completed
t₀ = 0.0
tₘₐₓ = 4
clock = Clock(t₀)

# - There must be a collection of "tickable events" so we can just have one call to tick!()
active = [clock, α]  # Clock is always active; A starts active (waiting in orbit)
# - 
scheduled = []
# - 
completed = []

while clock.time < tₘₐₓ
# for i = 1:3
    # 1) First step in the iteation is always to advance time
    tick!(active)
    # 2) Check for new scheduled processes
    if length(scheduled) > 0
        # start new
    end
    # 3) Check if any process completed
    for x in active
        if current_event_completed(x)
            push!(completed, x)
        end
    end

    if length(completed) > 0
        for x in completed
            @info "Element $(x.name) completed event $(x.current_event.name)"
        end
        break
    end

    # 4) Check Status
    status(active)
    @info "Time until next event: $(α.time_to_next)"
    println("-------------------------------------------\n")
end


# while clock.time < tₘₐₓ
#     tick!(active)
#     if clock.time == 2
#         push!(active, B)  # Start the other element
#     end
#     # Check status
#     status(active)
#     println("-------------------------------------------\n")
# end
