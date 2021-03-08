module MissionSequence

#
# Dependencies
#
using Distributions

#
# Exports
#
export Event, BeginMission, CompleteMission, LossOfMission, AndEvent, RetireElement, 
       next, is_success, lookup

export Element, status, set_duration_from_current!, current_event_completed

export Simulation, Clock, tick!, status, current_event_completed, Tickable,
       handle_active!, handle_completed!, handle_scheduled!, handle_waiting!

#
# Type Hierarchies - Show the top level abstract types here
#

#
# Sub-modules
#

global δₜ = 1.0  # potential for a dynamically updated tick

include("Events.jl")
include("Elements.jl")
include("Simulation.jl")


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

end