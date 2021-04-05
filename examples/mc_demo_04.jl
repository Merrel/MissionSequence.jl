#
# Sim with global clock, tick!() actions and Elements
#

include("../src/MissionSequence.jl")
using .MissionSequence

using ProgressMeter

function sample(event_database::Dict)
    # Define a sim to tick!() forward in time until the event is completed
    t₀ = 0.0
    tₘₐₓ = 60
    clock = Clock(t₀)

    # Start the initial elements
    DE = Element("DE", event_database[:start_DE], event_database[:launch_DE])
    set_duration_from_current!(DE)
    AE = Element("AE", event_database[:start_AE], event_database[:launch_AE])
    set_duration_from_current!(AE)

    # - Active element are currently running an in-process event and running a countdown
    active = Tickable[]
    # - Scheduled events will occur at some time in the future, as defined by a tick
    scheduled = Tickable[AE, DE]

    # Create the simulation
    sim = Simulation(clock, active, scheduled)

    # Reset the event database
    reset_events!(event_database)

    # Run the simulation and update the sim composite type in place
    # run!(sim, event_database, verbose = false, mode = :continuous)
    run!(sim, event_database, verbose = false, mode = :discrete)

    # Get the final event
    terminal_event = vcat(sim.completed, sim.failed)[1].event_history[end].name
    penultimate_event = vcat(sim.completed, sim.failed)[1].event_history[end-1].name

    # Process return code
    return_code = length(sim.completed) >= 1 ? true : false

    return (return_code, terminal_event, penultimate_event)
end

#
# MONTE CARLO SIMULATION
#

begin
    # Define the events in the sim; these make up a directed graph
    event_spec = YAML.load_file("./missions/mission01.yml")
    event_database = load(event_spec)

    # Set the number of iterations
    iterations = Int(1e5)

    # Preallocate the return arryas
    return_codes = Vector{Number}(undef,iterations)
    penultimate_events = Vector{Symbol}(undef,iterations)
    final_events = Vector{Symbol}(undef,iterations)

    # Create progress bar
    p = Progress(iterations)

    # Perform sampling in multi-threaded mode
    Threads.@threads for n = 1:iterations
        return_codes[n], final_events[n], penultimate_events[n] = sample(event_database)
        next!(p)
    end

    R = sum(return_codes) / iterations

    println("\n$iterations simulations --> reliability = $R")

    # Show terminal events
    event_bin = Dict(k => 0 for k in unique(penultimate_events))

    for ev in penultimate_events
        event_bin[ev] += 1
    end

    event_bin

end