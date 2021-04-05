abstract type AbstractState end

mutable struct State <: AbstractState 
    name::String
    current::AbstractEvent
    history::Array{AbstractEvent, 1}

    function State(name::String, current::AbstractEvent)
        new(name, current, AbstractEvent[])
    end
end