#
# Demonstrate loading events as specified in a YAML file
#
import YAML
include("Events.jl")

# Load event_spec from yaml file
event_spec = YAML.load_file("src/A01_Events.yaml")

# Start
event_database = Dict{Any, Any}(
    :LOM => LossOfMission(  :LOM,  -999 ),
    :COMPLETE => CompleteMission( :COMPLETE )
)

# Loop through the spec
for (name, spec) in event_spec
    if "first"  in keys(spec)
        ev = BeginMission(:START, spec["first"])
    elseif "attempts" in keys(spec)
        ev = LimitedEvent(spec["UID"], name, spec["prob"], spec["dest"], spec["attempts"])
        process_dst!(ev)
    else
        ev = Event(spec["UID"], name, spec["prob"], spec["dest"])
        process_dst!(ev)
    end
    event_database[ev.UID] = ev
end

event_database

function run_sequence(db::Dict)
    e = db[:START]
    u = next(e)
    i = 0
    while !(typeof(e) <: AbstractTerminalEvent)
        i += 1
        # Try the event and get the next one
        e = lookup(u, db)
        u = next(e)
    end
    return is_success(e)
end

n_samples = 1e6
samples = [run_sequence(event_database) for i in 1:n_samples]
sum(samples) / n_samples