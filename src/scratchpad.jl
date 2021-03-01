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

        println(name)
        println(spec)

        if spec["type"] == "BeginMission"
            ev = BeginMission(spec["UID"], name, spec["dest"])

        elseif spec["type"] == "LimitedEvent"
            ev = LimitedEvent(spec["UID"], name, spec["prob"], spec["dest"], spec["attempts"])
            process_dst!(ev)

        elseif spec["type"] == "AndEvent"
            ev = AndEvent(spec["UID"], name, spec["and"], spec["dest"])
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

init_events = filter(e -> typeof(e.second) == BeginMission, db)

# queue
# queue = [db[:START], db[:START]]


# path_A = begin
    # Start at theinit_events, Launch A
    e = init_events[1]
    # Go to the next one
    u = next(e)
    e = db[u]

    u = next(e)
    e = db[u]

    u = next(e)
    e = db[u]
# end

path_B = begin
    # Start at the :START, Launch A
    e = db[:START]
    # Go to the next one
    u = next(e)
    e = db[u]

    u = next(e)
    e = db[u]
end