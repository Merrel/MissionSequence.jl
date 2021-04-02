#
# Define a type hierarchy for events
#
# import Base:show

abstract type AbstractEvent end
abstract type AbstractBernoulliEvent <: AbstractEvent end
abstract type AbstractTerminalEvent <: AbstractEvent end
# abstract type AbstractANDEvent <: AbstractEvent end

struct BeginMission <: AbstractEvent
    # UID::Int64
    name::String
    to::Int64
    duration::Number
end

struct CompleteMission <: AbstractTerminalEvent
    name::Symbol
    # name::String
end

struct RetireElement <: AbstractTerminalEvent
    name::Symbol
    # name::String
end

struct LossOfMission <: AbstractTerminalEvent
    name::Symbol
    cause::String  # will be the UID of the event that led to LOM
end

struct Event <: AbstractBernoulliEvent
    # UID::Int64
    name::String
    pₛ::Number
    to::Dict
    duration::Number
end

struct AndEvent <: AbstractEvent
    # UID::Int64
    name::String
    and::Array
    to::Dict
    status::Symbol
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
next(e::AndEvent) = e.to[e.status]
next(e::AbstractBernoulliEvent) = e.to[attempt(e)]
next(e::CompleteMission) = :COMPLETE
next(e::LossOfMission) = :LOM
next(e::RetireElement) = :DONE

is_success(e::AbstractEvent) = typeof(e) == CompleteMission ? true : false


#
# Methods for working with collections of events
#

lookup(name::Union{Symbol, String}, d::Dict) = d[name]

function process_dst!(ev::AbstractBernoulliEvent)
    for (k, v) in ev.to
        if typeof(v) == String
            ev.to[k] = Symbol(v)
        end
    end
end

###############################################################################
# Loading Events

# 


function load(event_spec::Dict)
    # Start
    event_database = Dict{Union{Symbol, String}, AbstractEvent}(
        :LOM       => LossOfMission( :LOM, "NA"),
        :COMPLETE  => CompleteMission( :COMPLETE ),
        :DONE      => RetireElement( :DONE ),
    )

    for (name, spec) in event_spec["Events"]
        # Get the type if available, else assign
        try
            e_type = spec["type"]
        catch
            spec["type"] = "Event"
        end

        to = Dict(Symbol(k)=>Symbol(v)  for (k,v) in spec["to"])

        if spec["type"] == "Event"
            event_database[name] = Event(name, spec["Ps"], to, spec["duration"])

        elseif spec["type"] == "AND"
            event_database[name] = AndEvent(name, spec["and"], to, :fail, spec["duration"])

        end
    end

    # Finally convert all keys to symbols and return
    return Dict(Symbol(k)=>v  for (k,v) in event_database)
end
