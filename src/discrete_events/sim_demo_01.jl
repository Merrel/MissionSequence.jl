#
# Sim with global clock, tick!() actions and Elements
#

include("MissionSequence.jl")
using .MissionSequence


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
tₘₐₓ = 60
clock = Clock(t₀)

# - Scheduled events will occur at some time in the future, as defined by a tick
α = Element("α", start_α, launch_α)
set_duration_from_current!(α)
β = Element("β", start_β, launch_β)
set_duration_from_current!(β)


sim = Simulation(
    clock,
    active = Tickable[],
    scheduled = Tickable[α, β],
    completed = Tickable[],
    retired = Tickable[],
    waiting = Tickable[],
    failed = Tickable[]
)


# begin
while clock.time < tₘₐₓ

    # 1) First step in the iteation is always to advance time
    tick!(sim)
    
    # @info "α: Time until next event: $(α.time_to_next)"
    # @info "β: Time until next event: $(β.time_to_next)"

    
    # 2) Check for new scheduled processes
    handle_scheduled!(sim)

    # 3) 
    handle_active!(sim)

    # 4) Check AND events
    handle_waiting!(sim, event_database)

    # 5) 
    handle_completed!(sim, event_database)
        
    if length(sim.failed) > 0
        @warn "LOSS OF MISSON"
        break
    elseif length(sim.completed) > 0
        @warn "$(length(sim.completed)) COMPLETE"
        # @warn "$(length(filter(x -> !(typeof(x) <: Clock), sim.active))) ACTIVE"
        @warn "$(length(sim.active)) ACTIVE"
        break
    end

    # 5)
    status(sim)
    println("\n-------------------------------------------")
end


status(sim)
