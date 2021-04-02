#
# Sim with global clock, tick!() actions and Elements
#

include("MissionSequence.jl")
using .MissionSequence

using ProgressMeter

# Define the events in the sim; these make up a directed graph
event_spec = YAML.load_file("src/discrete_events/mission01.yml")

event_database = load(event_spec)

function sample()
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

    # Run the simulation and update the sim composite type in place
    # run!(sim, event_database, verbose = false, mode = :continuous)
    run!(sim, event_database, verbose = false, mode = :discrete)

    return length(sim.completed) >= 1 ? true : false
end

#
# MONTE CARLO SIMULATION
#

begin
    iterations = Int(1e6)
    results= zeros(iterations)

    p = Progress(iterations)

    Threads.@threads for n = 1:iterations
        results[n] = sample()
        next!(p)
    end

    R = sum(results) / iterations

    println("\n$iterations simulations --> reliability = $R")

end