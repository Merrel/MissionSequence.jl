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
queue = [db[1], db[2]]

function run_sequence(start::AbstractEvent, db::Dict)
    e = start
    # u = next(e)
    i = 0
    while !(typeof(e) <: AbstractTerminalEvent)
        i += 1
        # Try the event and get the next one
        # e = lookup(u, db)
        u = next(e)
        e = lookup(u, db)
    end
    return e
end

halted = []
while length(queue) > 0
    state = pop!(queue)
    state = run_sequence(state, db)
    push!(halted, state)
end

any_lom(q::Array)      = any([typeof(e) == LossOfMission for e in q])
any_complete(q::Array) = any([typeof(e) == CompleteMission for e in q])

if any_lom(halted)
    println("LOSS OF MISSION")
elseif any_complete(halted)
    println("Mission Completed")
else
    println("continue...")
end

# init_A = queue[1]
# run_sequence(init_A, db)
# init_B = queue[1]
# run_sequence(init_B, db)