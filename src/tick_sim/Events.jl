#
# Define a type hierarchy for events
#
using Distributions

abstract type AbstractEvent end
abstract type AbstractBernoulliEvent <: AbstractEvent end
abstract type AbstractTerminalEvent <: AbstractEvent end
# abstract type AbstractANDEvent <: AbstractEvent end

struct BeginMission <: AbstractEvent
    UID::Int64
    name::String
    to::Int64
end

struct CompleteMission <: AbstractTerminalEvent
    UID::Symbol
end

struct LossOfMission <: AbstractTerminalEvent
    UID::Symbol
    cause::Int64  # will be the UID of the event that led to LOM
end

struct Event <: AbstractBernoulliEvent
    UID::Int64
    name::String
    pₛ::Number
    to::Dict
    duration::Number
end

#
# Methods to evaluate event logic
#

function attempt(e::AbstractBernoulliEvent)
    if rand(Bernoulli(e.pₛ))
        return :pass
    else
        return :fail
    end
end

#
# Methods to determine the next event
#

next(e::BeginMission) = e.to
next(e::AbstractBernoulliEvent) = e.to[attempt(e)]
next(e::CompleteMission) = :COMPLETE
next(e::LossOfMission) = :LOM

is_success(e::AbstractTerminalEvent) = typeof(e) == CompleteMission ? true : false


#
# Methods for working with collections of events
#

lookup(uid::Union{Symbol, Int64}, d::Dict) = d[uid]

function process_dst!(ev::AbstractBernoulliEvent)
    for (k, v) in ev.to
        if typeof(v) == String
            ev.to[k] = Symbol(v)
        end
    end
end