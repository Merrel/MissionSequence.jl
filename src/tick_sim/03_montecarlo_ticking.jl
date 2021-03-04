#
# Sim with global clock, tick!() actions and Elements
#
using ProgressMeter

include("Events.jl")

global δₜ = 1.0  # potential for a dynamically updated tick

abstract type Tickable end

###############################################################################
# Clock

mutable struct Clock <: Tickable
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

mutable struct Element <: Tickable
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

wait_α = Event(
    103,
    "wait_α",
    0.9,
    Dict(:pass => :COMPLETE, :fail => :LOM),
    30
)

event_database = Dict{Any, Any}(
    :LOM =>      LossOfMission(  :LOM,  -999 ),
    :COMPLETE => CompleteMission( :COMPLETE , "COMPLETE"),
    101 =>       launch_α,
    102 =>       orbit_α,
    103 =>       wait_α
)

function run()

    # Now start the sim by generating an element to traverse the graph
    if attempt(launch_α) == :pass
        α = Element("α", launch_α, orbit_α)
        set_duration_from_current!(α)
        # @info "Successful Launch"
    else
        # @error "Failed Launch"
        return false
    end

    # # Now the Element is traversing an edge of the graph between events
    # status(α)
            
    # # There is a time required to travese the edge
    # @info "Time until next event: $(α.time_to_next)"

    # Define a sim to tick!() forward in time until the event is completed
    t₀ = 0.0
    tₘₐₓ = 60
    clock = Clock(t₀)

    # - There must be a collection of "tickable events" so we can just have one call to tick!()
    active = [clock, α]  # Clock is always active; A starts active (waiting in orbit)
    # - 
    scheduled = []
    # - 
    completed = []
    # - 
    waiting = []
    # - 
    failed = []

    while clock.time < tₘₐₓ
    # for i = 1:3
        # 1) First step in the iteation is always to advance time
        tick!(active)
        # status(active)
        # @info "Time until next event: $(α.time_to_next)"
        # 2) Check for new scheduled processes
        if length(scheduled) > 0
            # start new
        end
        # 3) Check if any process completed
        new_active = []
        while length(active) > 0
            x = pop!(active)
            if current_event_completed(x)
                push!(completed, x)
            else
                push!(new_active, x)
            end
        end
        active = new_active

        if length(completed) > 0

            new_completed = []

            while length(completed) > 0
                x = pop!(completed)

                to = next(x.next_event)

                if to == :LOM
                    # @error "LOSS OF MISSION"
                    push!(failed, x)
                else
                    x.current_event = x.next_event
                    if is_success(x.current_event)
                        push!(new_completed, x)
                    else
                        new_next = lookup(to, event_database)
                        x.next_event = new_next
                        set_duration_from_current!(x)
                        push!(active, x)
                    end
                end

            end
            completed = new_completed

            # status(α)
            if length(failed) > 0
                # @warn "LOSS OF MISSON"
                break
            elseif length(completed) > 0
                # @warn "$(length(completed)) COMPLETE"
                break
            end
        end

        # 4) Check Status
        # println("-------------------------------------------\n")
    end
    # return 
    return length(completed) >= 1 ? true : false
end

# println()
# println(α.current_event)

# println("\nα, time = $(α.time_to_next)")

iterations = Int(1e6)

results= zeros(iterations)

@showprogress for n = 1:iterations
    results[n] = run()
end

reliability = sum(results) / iterations

println("\n$iterations simulations --> reliability = $reliability")
