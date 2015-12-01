stop = DateTime(now())
start = stop - Day(10)
expected_time = collect(start:Day(1):stop)
expected_id = collect(1:5)

# View with default cache
myview = DataView(
    (expected_time, expected_id);
    labels=("time", "id"),
    mmapped=true
)

# View with stats cache
println("Main statscache")
statsview = DataView(
    Variance,
    (expected_time, expected_id);
    labels=("time", "id"),
    weighting=ExponentialWeighting(0.5)
)

@test myview[:time] == expected_time
@test myview[:id] == expected_id

myview[start, 1] = 5.0

@test expected_time[1] == expected_time[1]

datum = create_datum((expected_time[1], 2, 3.0))

insert!(
    myview,
    datum
)

labels, expected, cache = data(myview)
@test labels == (:time, :id)
@test expected == (expected_time, expected_id)
@test cache[1,2] == 3.0

subselect = myview[
    expected_time[2]:expected_time[4],
    2:5
]

@test data(subselect)[3] == sub(data(myview)[3], 2:4, 2:5)
