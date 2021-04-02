module MissionSequence

#
# Dependencies
#
using Distributions
import YAML

#
# Exports
#
export YAML

export Event, BeginMission, CompleteMission, LossOfMission, AndEvent, RetireElement, 
       next, is_success, lookup, load

export Element, status, set_duration_from_current!, current_event_completed

export Simulation, Clock, tick!, status, current_event_completed, Tickable, run!,
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


end