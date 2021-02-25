#
# Show a sample of a few events
#

struct AbstractEvent end

struct BeginMission <: AbstractEvent
    UID::Int64
end

struct CompleteMission <: AbstractEvent
    UID::Int64
end

struct LossOfMission <: AbstractEvent
    cause::Int64  # will be the UID of the event that led to LOM
end

struct Event <: AbstractEvent
    UID::Int64
    pₛ::Number
    to::NamedTuple
end

struct LimitedEvent <: AbstractEvent
    UID::Int64
    pₛ::Number
    to::NamedTuple
    attempts::Int64
end

(pass = 101, fail = :LOM)

# Define the launch event
launch = Event(
    101,
    0.9,
    (pass = 102, fail = :LOM)
)

# Orbit Insertion
orbit = Event(
    102,
    0.95,
    (pass = 102, fail = :LOM)
)

dock = Event(
    103,
    0.75,
    (pass = 104, fail = 105)
)

recycle = LimitedEvent(
    105,
    0.99,
    (pass = 103, fail = :LOM),
    3
)

complete = <: AbstractEvent(
    104
)