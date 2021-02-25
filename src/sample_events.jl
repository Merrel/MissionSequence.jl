#
# Show a sample of a few events
#
using Distributions

abstract type AbstractEvent end
abstract type AbstractBernoulliEvent <: AbstractEvent end
abstract type AbstractTerminalEvent <: AbstractEvent end

struct BeginMission <: AbstractEvent
    UID::Symbol
    first::Int64
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
    to::NamedTuple
end

struct LimitedEvent <: AbstractBernoulliEvent
    UID::Int64
    name::String
    pₛ::Number
    to::NamedTuple
    attempts::Int64
end

start = BeginMission(
    :START,
    101
)

lom = LossOfMission(
    :LOM,
    -999
)


# Define the launch event
launch = Event(
    101,
    "Launch",
    0.9,
    (pass = 102, fail = :LOM)
)

# Orbit Insertion
orbit = Event(
    102,
    "Orbit Insertion",
    0.95,
    (pass = 103, fail = :LOM)
)

dock = Event(
    103,
    "Docking",
    0.75,
    (pass = :COMPLETE, fail = 104)
)

recycle = LimitedEvent(
    104,
    "Recycle Docking",
    0.99,
    (pass = 103, fail = :LOM),
    3
)

complete = CompleteMission(
    :COMPLETE
)

# Collect all the events to an array

events = [
    start,
    launch,
    orbit,
    dock,
    recycle,
    complete,
    lom
]

# Process events to lookup table
lookup = Dict()
for ev in events
    lookup[ev.UID] = ev
end


function attempt(e::AbstractEvent)
    if rand(Bernoulli(e.pₛ))
        return :pass
    else
        return :fail
    end
end


next(e::BeginMission) = e.first
next(e::AbstractBernoulliEvent) = e.to[attempt(e)]
next(e::CompleteMission) = :COMPLETE
next(e::LossOfMission) = :LOM

# check(e::AbstractTerminalEvent) = if typeof(e) == CompleteMission true else false end
is_success(e::AbstractTerminalEvent) = typeof(e) == CompleteMission ? true : false

function run_sequence(first_event::BeginMission)
    e = first_event
    u = next(e)
    i = 0
    while !(typeof(e) <: AbstractTerminalEvent)
        i += 1
        # Try the event and get the next one
        e = lookup[u]
        u = next(e)
    end
    return is_success(e)
end

n_samples = 1e6
samples = [run_sequence(start) for i in 1:n_samples]
sum(samples) / n_samples