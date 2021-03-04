#
# Sim with global clock, tick!() actions and Elements
#

include("Events.jl")

import Base: names

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
    event_history::Array{AbstractEvent, 1}

    function Element(name, current_event, next_event)
        new(name, current_event, next_event, NaN, AbstractEvent[])
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

function status(active::Array{Tickable, 1})
    for x in active
        status(x)
    end
end

function tick!(active::Array{Tickable, 1})
    for x in active
        tick!(x)
    end
end

# function names(arr::Array{Tickable, 1})
#     return [x.name for x in arr]
# end

###############################################################################
# Demo Sim

# Define the events in the sim; these make up a directed graph

# Define the events for α
begin

    start_α = Event(
        # 100,
        "start_α",
        1.0,
        Dict(:pass => "launch_α", :fail => :LOM),
        1
    )

    launch_α = Event(
        # 101,
        "launch_α",
        0.95,
        Dict(:pass => "orbit_α", :fail => :LOM),
        3
    )

    orbit_α = Event(
        # 102,
        "orbit_α",
        0.99,
        Dict(:pass => "wait_α", :fail => :LOM),
        5
    )

    wait_α = AndEvent(
        # 103,
        "wait_α",
        # 0.9,
        ["orbit_α", "orbit_β"],
        Dict(:pass => "TLI_α", :fail => :LOM),
        :fail,
        30
    )

    TLI_α = Event(
        # 102,
        "TLI_α",
        0.95,
        Dict(:pass => :COMPLETE, :fail => :LOM),
        5
    )

end

# Define the events for β
begin

    start_β = Event(
        # 200,
        "start_β",
        1.0,
        Dict(:pass => "launch_β", :fail => :LOM),
        20
    )

    launch_β = Event(
        # 201,
        "launch_β",
        0.95,
        Dict(:pass => "orbit_β", :fail => :LOM),
        3
    )

    orbit_β = Event(
        # 202,
        "orbit_β",
        0.99,
        Dict(:pass => "wait_β", :fail => :LOM),
        8
    )

    wait_β = AndEvent(
        # 203,
        "wait_β",
        # 0.9,
        ["orbit_α", "orbit_β"],
        Dict(:pass => :DONE, :fail => :LOM),
        :fail,
        30
    )
end

# Define the events for γ


event_database = Dict{Any, Any}(
    :LOM       => LossOfMission( :LOM, "NA"),
    :COMPLETE  => CompleteMission( :COMPLETE ),
    :DONE      => RetireElement( :DONE ),

    "start_α"  => start_α,
    "launch_α" => launch_α,
    "orbit_α"  => orbit_α,
    "wait_α"   => wait_α,
    "TLI_α"    => TLI_α,
    
    "start_β"  => start_β,
    "launch_β" => launch_β,
    "orbit_β"  => orbit_β,
    "wait_β"   => wait_β
)

# Define a sim to tick!() forward in time until the event is completed
t₀ = 0.0
tₘₐₓ = 50
clock = Clock(t₀)

# - There must be a collection of "tickable events" so we can just have one call to tick!()
active = Tickable[clock,]  # Clock is always active

# - Scheduled events will occur at some time in the future, as defined by a tick
α = Element("α", start_α, launch_α)
set_duration_from_current!(α)
β = Element("β", start_β, launch_β)
set_duration_from_current!(β)

scheduled = Tickable[α, β]

# - 
completed = Tickable[]

# - retired
retired = Tickable[]

# - 
waiting = Tickable[]

# - 
failed = Tickable[]

mutable struct Simulation            # Now we can make a process_active, process_scheduled... that modifies this in place
    active::Array{Tickable, 1}
    scheduled::Array{Tickable, 1}
    completed::Array{Tickable, 1}
    waiting::Array{Tickable, 1}
    failed::Array{Tickable, 1}
    retired::Array{Tickable, 1}

    function Simulation()
        new(Tickable[], Tickable[], Tickable[], Tickable[], Tickable[], Tickable[])
    end
end

sim = Simulation()

# begin
while clock.time < tₘₐₓ

    # 1) First step in the iteation is always to advance time
    println("ACTIVE +++++++++++++++++++++++")
    tick!(active)
    status(active)
    # @info "α: Time until next event: $(α.time_to_next)"
    # @info "β: Time until next event: $(β.time_to_next)"

    if length(waiting) > 0
        println("WAITING +++++++++++++++++++++++")
        tick!(waiting)
        status(waiting)
    end
    
    # 2) Check for new scheduled processes
    if length(scheduled) > 0
        # start new
        tick!(scheduled)
        #Check if any scheduled processes should start
        new_scheduled = Tickable[]
        while length(scheduled) > 0
            x = pop!(scheduled)
            if current_event_completed(x)
                push!(active, x)
            else
                push!(new_scheduled, x)
            end
        end
        scheduled = new_scheduled
    end
    # 3) Check if any process completed
    new_active = Tickable[]
    while length(active) > 0
        x = pop!(active)
        if current_event_completed(x)  # <--- This is where we also need to check for waiting status
            #
            # Check what the next event type is
            # - "regular event" --> mark completed -> process
            # - "And event"     --> Move to the waiting queue
            # - "scheduler"     --> somehow process the event and add to scheuled queue
            
            # Check for AND event
            if typeof(x.next_event) <: AndEvent
                # Change current event to waiting
                push!(x.event_history, x.current_event)
                x.current_event = x.next_event
                set_duration_from_current!(x)
                push!(waiting, x)
            else
                push!(completed, x)
            end
        else
            push!(new_active, x)
        end
    end
    active = new_active

    # 4) Check AND events

    and_criteria = unique!([x.current_event.and for x in waiting])

    waiting_prior_events = [x.event_history[end].name for x in waiting]
    
    for criterion in and_criteria
        on_deck = Tickable[]
        # Criterion are desribed by an array of events that must have happened
        # Check to see if the criterion is contain in a list of all the waiting previous events
        if criterion ⊆ waiting_prior_events
            @info "Criterion $criterion SATISFIED"

            # Get the elements waiting on this and_criteria
            on_deck = filter(x -> x.current_event.and == criterion, waiting)
            for x in on_deck
                to = x.next_event.to[:pass]
                x.next_event = lookup(to, event_database)
            end
            # Move the on deck events to completed
            append!(completed, on_deck)
            # Remove the on deck events from the waiting queue
            waiting = filter(x -> !(x in on_deck), waiting)
        end
    end

    new_waiting = Tickable[]
    while length(waiting) > 0
        x = pop!(waiting)
        if x.time_to_next <= 0
            to = x.next_event.to[:fail]
            x.next_event = lookup(to, event_database)
            push!(completed, x)
        else
            push!(new_waiting, x)
        end
    end

    waiting = new_waiting


        # Process matches
        # - x (the first one selected) drives the next activity
        #     This should be set up such that all matched events have the same outcome
        # push!(completed, x)

        # Somehow remove the other entries in matched from waiting

    if length(completed) > 0

        new_completed = Tickable[]

        while length(completed) > 0
            x = pop!(completed)
            println("\nElement $(x.name)")
            println("\tcompleted event $(x.current_event.name)")
            println("\tThe next event is $(x.next_event.name)")
            println("\t ... trying ...")

            to = next(x.next_event)
            # println("!!!!!!!")
            # println(to)
            # println("!!!!!!!")

            if to == :LOM
                @error "LOSS OF MISSION"
                push!(x.event_history, x.current_event)
                push!(x.event_history, LossOfMission( :LOM, "NA"))
                push!(failed, x)
            # elseif to == :COMPLETE   !!! This elseif made obselete by frist part of the else
            #     @warn "COMPLETE"
            #     push!(completed, x)
            elseif to == :DONE
                @warn "Retire element $(x.name)"
                push!(x.event_history, x.current_event)
                push!(retired, x)
            else
                push!(x.event_history, x.current_event)
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

        
        
        
        if length(failed) > 0
            @warn "LOSS OF MISSON"
            break
        elseif length(completed) > 0
            @warn "$(length(completed)) COMPLETE"
            @warn "$(length(filter(x -> !(typeof(x) <: Clock), active))) ACTIVE"
            break
        end
    end

    # TODO: Add event history to the element
    #       - possible to include just the event name, or name + global time of event


    # 4) Check Status
    println("-------------------------------------------\n")
end