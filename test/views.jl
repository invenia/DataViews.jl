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

# Test `insert!` with a datum
datum = create_datum((expected_time[1], 2, 3.0))
insert!(
    myview,
    datum
)

# Check index, cache tuple returned from `data`
index, cache = data(myview)
@test collect(keys(index)) == [:time, :id]
@test collect(values(index)) == Array[expected_time, expected_id]
@test cache[1,2] == 3.0

# Check subselection
subselect = myview[
    expected_time[2]:expected_time[4],
    2:5
]

@test data(subselect)[2] == sub(data(myview)[2], 2:4, 2:5)

# Test partitioned DataView
index_map = OrderedDict((
    :time => expected_time,
    :features => OrderedDict((
        :gps => 1:5,
        :direction => 1:8,
        :weather => 1:10
    ))
))

partitioned = DataView(index_map)
@test data(partitioned[start, (:gps, :weather,)])[2] == zeros(15)'
