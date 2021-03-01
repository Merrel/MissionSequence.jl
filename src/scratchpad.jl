


# Start at the :START, Launch A
e = db[:START]
# Go to the next one
u = next(e)
e = db[u]

u = next(e)
e = db[u]

bothlaunched = AndEvent(
    201,
    "Successful Launch of A, B",
    1.0,
    [db[102], db[102]],
    Dict("pass" => 103, "fail" => :LOM)
)

bothlaunched.and


path_A = begin
    # Start at the :START, Launch A
    e = db[:START]
    # Go to the next one
    u = next(e)
    e = db[u]

    u = next(e)
    e = db[u]
end

path_B = begin
    # Start at the :START, Launch A
    e = db[:START]
    # Go to the next one
    u = next(e)
    e = db[u]

    u = next(e)
    e = db[u]
end