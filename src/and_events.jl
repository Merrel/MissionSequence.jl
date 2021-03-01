#
# Demonstrate AND events
#
import YAML
include("Events.jl")

function load_events(yml::String)


    # Load event_spec from yaml file
    event_spec = YAML.load_file(yml)

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

    return event_database
end

db = load_events("src/A0b_Events.yaml")

init_events = filter(e -> e.second.UID == :START, db)

# queue
queue = [db[:START], db[:START]]

function run_sequence(start::AbstractEvent, db::Dict)
    e = start
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

init_A = queue[1]
run_sequence(init_A, db)
init_B = queue[1]
run_sequence(init_B, db)