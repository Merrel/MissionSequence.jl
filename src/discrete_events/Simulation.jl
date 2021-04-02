
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

function Base.show(io::IO, c::Clock)
    print(io, "Clock")
end

function tick!(c::Clock)
    c.time += δₜ
end

function step!(c::Clock, δₛ)
    c.time += δₛ
end

function status(c::Clock)
    println("The time is t = $(c.time)")
end

current_event_completed(c::Clock) = false


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

function step!(active::Array{Tickable, 1}, δₛ)
    for x in active
        step!(x, δₛ)
    end
end



###############################################################################
# Simulation Type to hold arrays of Tickable types

mutable struct Simulation            # Now we can make a process_active, process_scheduled... that modifies this in place
    clock::Clock
    active::Array{Tickable, 1}
    scheduled::Array{Tickable, 1}
    completed::Array{Tickable, 1}
    retired::Array{Tickable, 1}
    waiting::Array{Tickable, 1}
    failed::Array{Tickable, 1}
    # next_time::Number  # A place to store the next event to occur. Enable time skipping
end

"""
Constructor with default, empty data arrays
"""
function Simulation()
    Simulation(Clock(), Tickable[], Tickable[], Tickable[], Tickable[], Tickable[], Tickable[])
end

"""
Constructor with keywords
"""
function Simulation(clock; active, scheduled, completed, retired, waiting, failed)
    Simulation(clock, active, scheduled, completed, retired, waiting, failed)
end

function Simulation(clock::Clock, active::Array{Tickable, 1}, scheduled::Array{Tickable, 1})
    Simulation(clock, active, scheduled, Tickable[], Tickable[], Tickable[], Tickable[])
end

function tick!(sim::Simulation)
    tick!(sim.clock)
    tick!(sim.active)
    tick!(sim.scheduled)
    tick!(sim.waiting)
end

function step!(sim::Simulation, δₛ)
    step!(sim.clock, δₛ)
    step!(sim.scheduled, δₛ)
    step!(sim.active, δₛ)
    step!(sim.waiting, δₛ)
end

function handle_scheduled!(sim::Simulation)
    scheduled = sim.scheduled
    if length(scheduled) > 0
        # start new
        # tick!(scheduled)
        #Check if any scheduled processes should start
        new_scheduled = Tickable[]
        while length(scheduled) > 0
            x = pop!(scheduled)
            if current_event_completed(x)
                push!(sim.active, x)
            else
                push!(new_scheduled, x)
            end
        end
        sim.scheduled = new_scheduled
    end
end

function handle_active!(sim::Simulation)
    active = sim.active

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
                push!(sim.waiting, x)
            else
                push!(sim.completed, x)
            end
        else
            push!(new_active, x)
        end
    end
    sim.active = new_active
end

function handle_waiting!(sim::Simulation, event_database::Dict; verbose = false)
    waiting = sim.waiting

    and_criteria = unique!([x.current_event.and for x in waiting])

    waiting_prior_events = [x.event_history[end].name for x in waiting]
    
    for criterion in and_criteria
        on_deck = Tickable[]
        # Criterion are desribed by an array of events that must have happened
        # Check to see if the criterion is contain in a list of all the waiting previous events
        if criterion ⊆ waiting_prior_events
            if verbose
                @info "Criterion $criterion SATISFIED"
            end

            # Get the elements waiting on this and_criteria
            on_deck = filter(x -> x.current_event.and == criterion, waiting)
            for x in on_deck
                to = x.next_event.to[:pass]
                x.next_event = lookup(to, event_database)
            end
            # Move the on deck events to completed
            append!(sim.completed, on_deck)
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
            push!(sim.completed, x)
        else
            push!(new_waiting, x)
        end
    end

    sim.waiting = new_waiting
end

function handle_completed!(sim::Simulation, event_database::Dict; verbose = false)

    completed = sim.completed

    new_completed = Tickable[]

    while length(completed) > 0
        x = pop!(completed)

        if verbose
            println("\nElement $(x.name)")
            println("\tcompleted event $(x.current_event.name)")
            println("\tThe next event is $(x.next_event.name)")
            println("\t ... trying ...")
        end

        to = next(x.next_event)
        # println("!!!!!!!")
        # println(to)
        # println("!!!!!!!")

        if to == :LOM

            if verbose
                @error "LOSS OF MISSION"
            end

            push!(x.event_history, x.current_event)
            push!(x.event_history, LossOfMission( :LOM, "NA"))
            push!(sim.failed, x)
        # elseif to == :COMPLETE   !!! This elseif made obselete by frist part of the else
        #     @warn "COMPLETE"
        #     push!(completed, x)
        elseif to == :DONE

            if verbose
                @warn "Retire element $(x.name)"
            end

            push!(x.event_history, x.current_event)
            push!(sim.retired, x)
        else
            push!(x.event_history, x.current_event)
            x.current_event = x.next_event
            if is_success(x.current_event)
                push!(new_completed, x)
            else
                new_next = lookup(to, event_database)
                x.next_event = new_next
                set_duration_from_current!(x)
                push!(sim.active, x)
            end
        end

    end
    sim.completed = new_completed
end


function run!(sim::Simulation, event_database::Dict; tₘₐₓ=1000, verbose = false, mode = :discrete)
    while sim.clock.time < tₘₐₓ

        # 1) First step in the iteation is always to advance time

        if mode == :continuous
            tick!(sim)
        
        elseif mode == :discrete
            all_elements = vcat(sim.scheduled, sim.active, sim.waiting)

            δₛ = minimum([E.time_to_next for E in all_elements])

            step!(sim, δₛ)
        end

        # @info "α: Time until next event: $(α.time_to_next)"
        # @info "β: Time until next event: $(β.time_to_next)"
        
        # 2) Check for new scheduled processes
        handle_scheduled!(sim)

        # 3) 
        handle_active!(sim)

        # 4) Check AND events
        handle_waiting!(sim, event_database, verbose=verbose)

        # 5) 
        handle_completed!(sim, event_database, verbose=verbose)
            
        # Check for both loss of mission and completion of mission --> breaks while loop
        if length(sim.failed) > 0
            if verbose
                @warn "LOSS OF MISSON"
            end
            break
        elseif length(sim.completed) > 0
            if verbose
                @warn "$(length(sim.completed)) COMPLETE"
                # @warn "$(length(filter(x -> !(typeof(x) <: Clock), sim.active))) ACTIVE"
                @warn "$(length(sim.active)) ACTIVE"
            end
            break
        end

        # Print status of the sim in verbose mode
        if verbose
            status(sim)
            println("\n-------------------------------------------")
        end
    end
end


function status(s::Simulation)
    println("Simulation time: $(s.clock.time)")
    if length(s.active) > 0
        println("  > active:\t",    [x for x in s.active])
    end
    if length(s.scheduled) > 0
        println("  > scheduled:\t", [x for x in s.scheduled])
    end
    if length(s.completed) > 0
        println("  > completed:\t", [x for x in s.completed])
    end
    if length(s.retired) > 0
        println("  > retired:\t",   [x for x in s.retired])
    end
    if length(s.waiting) > 0
        println("  > waiting:\t",   [x for x in s.waiting])
    end
    if length(s.failed) > 0
        println("  > failed:\t",    [x for x in s.failed])
    end
end