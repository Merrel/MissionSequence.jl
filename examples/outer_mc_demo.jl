#
# Sim with global clock, tick!() actions and Elements
#

include("../src/MissionSequence.jl")
using .MissionSequence

using ProgressMeter
using UnicodePlots

#
# Single Sample of Event Sequence
#

function sample_sequence(event_database::Dict)
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
    run!(sim, event_database, verbose = false, mode = :discrete)

    # Get the final event
    terminal_event = vcat(sim.completed, sim.failed)[1].event_history[end].name
    penultimate_event = vcat(sim.completed, sim.failed)[1].event_history[end-1].name

    # Process return code
    return_code = length(sim.completed) >= 1 ? true : false

    return (return_code, terminal_event, penultimate_event)
end

#
# (INNER) MONTE CARLO SIMULATION
#

function sample_innerMC(event_database, iterations)

    # Preallocate the return arryas
    return_codes = Vector{Number}(undef,iterations)
    penultimate_events = Vector{Symbol}(undef,iterations)
    final_events = Vector{Symbol}(undef,iterations)

    # Perform sampling in multi-threaded mode
    Threads.@threads for n = 1:iterations
        return_codes[n], final_events[n], penultimate_events[n] = sample_sequence(event_database)
    end

    R = sum(return_codes) / iterations

    # # Show terminal events
    # event_bin = Dict(k => 0 for k in unique(penultimate_events))

    # for ev in penultimate_events
    #     event_bin[ev] += 1
    # end

    return R
end

#
# (OUTER) MONTE CARLO SIMULATION
#

begin

    # Set the number of iterations
    outer_iterations = 100

    # Preallocate the return arryas
    R_samples = Vector{Number}(undef,outer_iterations)

    # Create progress bar
    p = Progress(outer_iterations)

    # Define the events in the sim; these make up a directed graph
    event_spec = YAML.load_file("./missions/mission01b.yml")
    event_database = load(event_spec)

    for n = 1:outer_iterations
        sample_distributions!(event_database, event_spec)
        this_R = sample_innerMC(event_database, Int(1e5))
        R_samples[n] = this_R
        next!(p)
    end

end

histogram(R_samples, nbins=12)

# using Plots, StatsPlots

# plot(
#     histogram(R_samples, c=:tomato, alpha=0.6, xlims=(0.7,0.9)),
#     density(R_samples, xlims=(0.7,0.9)),
#     layout = (2, 1)
# )