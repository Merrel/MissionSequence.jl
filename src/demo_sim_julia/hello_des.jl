using SimJulia  

# -----------------------------------------------------------------------------
# Set up the actor and it's behavior

function car(env::Environment)
    while true
        println("Start parking at $(now(env))")
        parking_duration = 5.0
        yield(Timeout(env, parking_duration))
        println("Start driving at $(now(env))")
        trip_duration = 2.0
        yield(Timeout(env, trip_duration))
    end
end

# -----------------------------------------------------------------------------
# Set up the simulation

# Every DES sim starts by defining an environment
env = Simulation()

@process car(env)

SimJulia.Environment()
