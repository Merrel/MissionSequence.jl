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
    name::Symbol
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
    cause::Symbol  # will be the UID of the event that led to LOM
end

mutable struct Event <: AbstractBernoulliEvent
    # UID::Int64
    name::Symbol
    𝑃::Number
    to::Dict
    duration::Number
    counter::Int
    # Constructor
    Event(name::Symbol, 𝑃::Number, to::Dict, duration::Number) = new(name, 𝑃, to, duration, 0)
end
    
mutable struct CountLimitedEvent <: AbstractEvent
    # UID::Int64
    name::Symbol
    # 𝑃::Number
    max_count::Number
    to::Dict
    duration::Number
    counter::Int
    # Constructor
    CountLimitedEvent(name::Symbol, max_count::Number, to::Dict, duration::Number) = new(name, max_count, to, duration, 0)
end

mutable struct AndEvent <: AbstractEvent
    # UID::Int64
    name::Symbol
    and::Array
    to::Dict
    status::Symbol
    duration::Number
    counter::Int
    # Constructor
    AndEvent(name::Symbol, and::Array, to::Dict, status::Symbol, duration::Number) = new(name, and, to, status, duration, 0) 
end
#
# Methods to evaluate event logic
#

function attempt(e::AbstractBernoulliEvent)
    if rand(Bernoulli(1 - e.𝑃))
        e.counter += 1
        return :pass
    else
        return :fail
    end
end

function attempt(e::CountLimitedEvent)
    if e.counter <= e.max_count
        e.counter += 1
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
next(e::CountLimitedEvent) = e.to[attempt(e)]
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
# Loading Events from file

# 


function load(event_spec::Dict)
    # Start
    event_database = Dict{Union{Symbol, String}, AbstractEvent}(
        :LOM       => LossOfMission( :LOM, :NA),
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
            event_database[name] = Event(Symbol(name), spec["Pf"], to, spec["duration"])

        elseif spec["type"] == "AND"
            and = [Symbol(v)  for v in spec["and"]]
            event_database[name] = AndEvent(Symbol(name), and, to, :fail, spec["duration"])

        elseif spec["type"] == "CountLimited"
            event_database[name] = CountLimitedEvent(Symbol(name), spec["max_count"], to, spec["duration"])
        end
    end

    # Finally convert all keys to symbols and return
    return Dict(Symbol(k)=>v  for (k,v) in event_database)
end

###############################################################################
# Sampling Events according to given distributions

function parse_distribution(dist_spec::String)
    dist_name   = string(match(r"^(.*)\(.*\)", dist_spec)[1])
    dist_params = string(match(r"^.*\((.*)\)", dist_spec)[1])

    dist_params = parse.(Float64,
                strip.(
                split(dist_params, ","
                )))


    distFxn = getfield(Main, Symbol(dist_name))

    return distFxn(dist_params...)
end


function sample_distributions!(event_database, event_spec)
    for (k, ev) in event_database
        try
            # Parse the string to a distribution object that we can sample
            spec = event_spec["Events"][string(k)]
            ev_dist = parse_distribution(spec["Pf_dist"])
            # Sample from the distribution
            ev.𝑃 = rand(ev_dist)
        catch
        end

    end
    return nothing
end


###############################################################################
# Managing Event fields

function reset_events!(event_database::Dict)
    # Set all the counters to zero
    for (k, v) in event_database
        try
            event_database[k].counter = 0
        catch
        end
    end
end


