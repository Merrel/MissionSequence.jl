
import Base: show

###############################################################################
# Element

abstract type Tickable end

function Base.show(io::IO, t::Tickable)
    # print(io, "Tickable: ", t.name)
    print(io, t.name)
end

mutable struct Element <: Tickable
    name::String
    current_event::AbstractEvent
    next_event::AbstractEvent
    time_to_next::Number
    event_history::Array{AbstractEvent, 1}

    function Element(name, current_event, next_event)
        new(name, current_event, next_event, NaN, AbstractEvent[])
    end
end

function tick!(E::Element)
    E.time_to_next -= δₜ
end

function step!(E::Element, δₛ)
    E.time_to_next -= δₛ
end

function status(E::Element)
    if E.time_to_next > 0
        println("  $(E.name):\t Current=$(E.current_event.name) --> Next=$(E.next_event.name)")
    elseif E.time_to_next == 0
        println("  $(E.name):\tCompleted $(E.current_event.name)")
    else
        @error("$(E.name):  Element clock is negative")
    end
end

function set_duration_from_current!(E::Element)
    E.time_to_next = E.current_event.duration
end

function current_event_completed(E::Element)
    if E.time_to_next > 0
        return false
    else
        return true
    end
end
