#
# Sim with global clock, tick!() actions and Elements
#

include("../src/MissionSequence.jl")
using .MissionSequence


###############################################################################
# Demo Sim

begin
    # Define the events in the sim; these make up a directed graph
    event_spec = YAML.load_file("./missions/mission01b.yml")
    event_database = load(event_spec)

    # Define a sim to tick!() forward in time until the event is completed
    clock = Clock()

    # Start the initial elements
    DE = Element("DE", event_database[:start_DE], event_database[:launch_DE])
    set_duration_from_current!(DE)
    AE = Element("AE", event_database[:start_AE], event_database[:launch_AE])
    set_duration_from_current!(AE)

    # - Active element are currently running an in-process event and running a countdown
    active = Tickable[]
    # - Scheduled events will occur at some time in the future, as defined by a tick
    scheduled = Tickable[DE, AE]

    # Create the simulation
    sim = Simulation(clock, active, scheduled)

    # Reset the event database
    reset_events!(event_database)

    # Run the simulation and update the sim composite type in place
    run!(sim, event_database, verbose = true, tₘₐₓ = 1200, mode = :discrete)

    status(sim)
end