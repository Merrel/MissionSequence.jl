#
# Show a sample of a few events
#
include("Events.jl")

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
    Dict(:pass => 102, :fail => :LOM)
)

# Orbit Insertion
orbit = Event(
    102,
    "Orbit Insertion",
    0.95,
    Dict(:pass => 103, :fail => :LOM)
)

dock = Event(
    103,
    "Docking",
    0.75,
    Dict(:pass => :COMPLETE, :fail => 104)
)

recycle = LimitedEvent(
    104,
    "Recycle Docking",
    0.99,
    Dict(:pass => 103, :fail => :LOM),
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
event_dict = Dict()
for ev in events
    event_dict[ev.UID] = ev
end


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

n_samples = 1e6
samples = [run_sequence(start) for i in 1:n_samples]
sum(samples) / n_samples