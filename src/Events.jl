#
# Show a sample of a few events
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
end

mutable struct LimitedEvent <: AbstractBernoulliEvent
    UID::Int64
    name::String
    pₛ::Number
    to::Dict
    attempts::Int64
end

struct AndEvent <: AbstractTerminalEvent
    UID::Int64
    name::String
    and::Array{String,1}
    to::Dict
end


lookup(uid::Union{Symbol, Int64}, d::Dict) = d[uid]


function attempt(e::AbstractEvent)
    if rand(Bernoulli(e.pₛ))
        return "pass"
    else
        return "fail"
    end
end


next(e::BeginMission) = e.to
next(e::AbstractBernoulliEvent) = e.to[attempt(e)]
next(e::CompleteMission) = :COMPLETE
next(e::LossOfMission) = :LOM

function next(e::LimitedEvent)
    if e.attempts < 1
        return :LOM
    else        
        e.attempts -= 1
        return e.to[attempt(e)]
    end
end

# function next(e::AndEvent)
#     if and
#         return e.to["pass"]
#     elseif more_in_queue
#         # start the next in the queue
#     else # case where no met and no more in queue
#         return :LOM
# end

is_success(e::AbstractTerminalEvent) = typeof(e) == CompleteMission ? true : false

function run_sequence(first_event::BeginMission)
    e = first_event
    u = next(e)
    i = 0
    while !(typeof(e) <: AbstractTerminalEvent)
        i += 1
        # Try the event and get the next one
        e = lookup(u, event_dict)
        u = next(e)
    end
    return is_success(e)
end

function process_dst!(ev::Union{AbstractBernoulliEvent, AndEvent})
    for (k, v) in ev.to
        if typeof(v) == String
            ev.to[k] = Symbol(v)
        end
    end
end