#
# Sim with global clock, tick!() actions and Elements
#

include("MissionSequence.jl")
using .MissionSequence


###############################################################################
# Demo Sim

# Define the events in the sim; these make up a directed graph
event_spec = YAML.load_file("src/discrete_events/mission01.yml")

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

# Run the simulation and update the sim composite type in place
run!(sim, event_database, verbose = false, tₘₐₓ = 120)

status(sim)
