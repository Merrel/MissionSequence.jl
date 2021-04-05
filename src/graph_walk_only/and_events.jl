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

function next!(s::State, db::Dict)
    # Get the next event UID (includes probability sampling)
    next_uid = next(s.current)
    # try
    #     next_uid = next(s.current)
    # catch
    #     println(s)
    # end
    # Look up the next event by UID
    next_event = lookup(next_uid, db)
    # Add event to history and assign new event
    push!(s.history, s.current)
    s.current = next_event
end

function run_sequence(s::AbstractState, db::Dict)
    # Get the current state
    e = s.current

    while !(typeof(e) <: AbstractTerminalEvent)
        # Next the state object
        next!(s, db)
        # Get the current state
        e = s.current
    end
    return s
end

function next(e::AndEvent, m::Array{State,1}, db::Dict)
    if typeof(matched_event) == AndEvent
        # Check if and is satisfied
        satisfed = all([n in names(m) for n in events(m)[1].and])
        if satisfed
            return lookup(matched_event.to["pass"], db)
        else
            return lookup(matched_event.to["fail"], db)
        end
    end
end

#
# =============================================================================
#

db = load_events("src/A0b_Events.yaml")

init_events = filter(e -> typeof(e.second) == BeginMission, db)

function run()

    queue = [State(init.name, init) for (k, init) in init_events]

    halted = State[]
    while length(queue) > 0
        state = pop!(queue)
        state = run_sequence(state, db)
        push!(halted, state)
    end

    any_lom(q::Array{State, 1})      = any([typeof(state.current) == LossOfMission for state in q])
    any_complete(q::Array{State, 1}) = any([typeof(state.current) == CompleteMission for state in q])

    function check_termination(h::Array{State, 1}, verbose=false)
        if any_lom(h)
            if verbose
                println("LOSS OF MISSION")
            end
            return false
        elseif any_complete(h)
            if verbose
                println("Mission Completed")
            end
            return true
        else
            if verbose
                println("continue...")
            end
            return true
        end
    end

    if !check_termination(halted)
        return false
    end

    names(q::Array{State, 1}) = [state.name for state in q]
    events(q::Array{State, 1}) = [state.current for state in q]

    names(halted)

    events(halted)

    # if match events and satisfy then consume and add to next queue

    # IF THERE ARE MATCHING EVENTS

    # Check for matching events

    # # Add artificial non-matching
    # hfake = State("fake", db[201])
    # push!(halted, hfake)

    # halted

    unique_current = []
    for h in halted
        if !(h.current in unique_current)
            push!(unique_current, h.current)
        end
    end

    matched_sets = []
    unmatched_states = State[]
    for unique_event in unique_current
        f = filter(s -> s.current === unique_event, halted)
        if length(f) > 1
            push!(matched_sets, (unique_event, f))
        else
            push!(unmatched_states, f[1])
        end
    end

    # Add the unmatched and halted states back to halted
    halted = unmatched_states

    # AND IF THE MATCHED EVENT IS SATISFIED

    for (matched_event, matched_set) in matched_sets
        next_event = next(matched_event, matched_set, db)
        push!(queue, State(matched_event.name, next_event))
    end

    # Check to see if there are any terminations in the queue
    if !check_termination(halted)
        return false
    end

    # Break if nothing to simulated (nothing in the QUEUE) AND still something in halted
    if isempty(queue) && !(isempty(queue))
        println("ERROR UNFINISED")
    end

    # return queue

    while length(queue) > 0
        state = pop!(queue)
        state = run_sequence(state, db)
        push!(halted, state)
    end

    # Check to see if there are any terminations in the queue
    if check_termination(halted, false)
        # if typeof(halted[1].current) == CompleteMission
        #     return true
        # else
        #     return false
        # end
        return true
    else
        return false
    end
end

n_runs = 1e6
res = [run() for i in 1:n_runs]

sum(res) / n_runs

# for i = 1:10
#     run()
# end