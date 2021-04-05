#
# Sim with global clock, tick!() actions and Elements
#

include("MissionSequence.jl")
using .MissionSequence


###############################################################################
# Demo Sim

# Define the events in the sim; these make up a directed graph

# Define the events for DE

begin

    start_DE = Event(
        # 100,
        "start_DE",
        1.0,
        Dict(:pass => "launch_DE", :fail => :LOM),
        1
    )

    launch_DE = Event(
        # 101,
        "launch_DE",
        0.95,
        Dict(:pass => "burnTLI_DE", :fail => :LOM),
        3
    )

    burnTLI_DE = Event(
        # 102,
        "burnTLI_DE",
        0.99,
        Dict(:pass => "burnNRHO_DE", :fail => :LOM),
        5
    )

    burnNRHO_DE = Event(
        # 102,
        "burnNRHO_DE",
        0.99,
        Dict(:pass => "loiter_DE", :fail => :LOM),
        5
    )

    loiter_DE = AndEvent(
        # 103,
        "loiter_DE",
        # 0.9,
        ["burnNRHO_DE", "rendezvous_AE"],
        Dict(:pass => "docking", :fail => :LOM),
        :fail,
        45
    )

    docking = Event(
        # 102,
        "docking",
        0.10,
        Dict(:pass => "complete_mission", :fail => "retry"),
        2
    )

    retry = Event(
        # 102,
        "retry",
        0.90,
        Dict(:pass => "docking", :fail => :LOM),
        2
    )

    complete_mission = Event(
        # 102,
        "complete mission",
        1.0,
        Dict(:pass => :COMPLETE, :fail => :LOM),
        5
    )

end

# Define the events for AE
begin

    start_AE = Event(
        # 200,
        "start_AE",
        1.0,
        Dict(:pass => "launch_AE", :fail => :LOM),
        20
    )

    launch_AE = Event(
        # 201,
        "launch_AE",
        1.0,
        Dict(:pass => "burnTLI_AE", :fail => :LOM),
        3
    )

    burnTLI_AE = Event(
        # 202,
        "burnTLI_AE",
        0.99,
        Dict(:pass => "burnNRHO_AE", :fail => :LOM),
        8
    )

    burnNRHO_AE = Event(
        # 202,
        "burnNRHO_AE",
        0.99,
        Dict(:pass => "rendezvous_AE", :fail => :LOM),
        2
    )

    rendezvous_AE = Event(
        # 202,
        "rendezvous_AE",
        0.99,
        Dict(:pass => "wait_AE", :fail => :LOM),
        4
    )

    wait_AE = AndEvent(
        # 203,
        "wait_AE",
        # 0.9,
        ["burnNRHO_DE", "rendezvous_AE"],
        Dict(:pass => :DONE, :fail => :LOM),
        :fail,
        45
    )
end

# Define the events for γ


event_database = Dict{Any, Any}(
    :LOM       => LossOfMission( :LOM, "NA"),
    :COMPLETE  => CompleteMission( :COMPLETE ),
    :DONE      => RetireElement( :DONE ),

    "start_DE"  => start_DE,
    "launch_DE" => launch_DE,
    "burnTLI_DE"  => burnTLI_DE,
    "burnNRHO_DE"  => burnNRHO_DE,
    "loiter_DE"   => loiter_DE,
    "docking"    => docking,
    "retry"    => retry,
    "complete_mission" => complete_mission,
    
    "start_AE"  => start_AE,
    "launch_AE" => launch_AE,
    "burnTLI_AE"  => burnTLI_AE,
    "burnNRHO_AE"  => burnNRHO_AE,
    "rendezvous_AE"  => rendezvous_AE,
    "wait_AE"   => wait_AE
)

# Define a sim to tick!() forward in time until the event is completed
t₀ = 0.0
tₘₐₓ = 34
clock = Clock(t₀)

# Start the initial elements
DE = Element("DE", start_DE, launch_DE)
set_duration_from_current!(DE)
AE = Element("AE", start_AE, launch_AE)
set_duration_from_current!(AE)

# - Active element are currently running an in-process event and running a countdown
active = Tickable[]
# - Scheduled events will occur at some time in the future, as defined by a tick
scheduled = Tickable[DE, AE]

# Create the simulation
sim = Simulation(clock, active, scheduled)

# Run the simulation and update the sim composite type in place
run!(sim, event_database, verbose = true, tₘₐₓ = 120)

status(sim)
