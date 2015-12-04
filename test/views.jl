# Test interface failure conditions
type BadView <: AbstractDataView end

bv = BadView()

@test_throws(ErrorException, bv[1])
@test_throws(ErrorException, bv[1] = 1.0)
@test_throws(ErrorException, bv[:foo])
@test_throws(ErrorException, insert!(bv, (1,2,3)))
@test_throws(ErrorException, data(bv))

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

@test_throws(ErrorException, myview[start, 7:9])
@test_throws(ErrorException, myview[start, 7])
@test_throws(ErrorException, myview[start, (:gps => 1:2,)])
@test_throws(ErrorException, myview[start, (:gps, :weather)])
empty_labels = DataView((expected_time, expected_id))
@test_throws(ErrorException, DataView((expected_time, expected_id); labels=("foo",)))

# View with stats cache
statsview = DataView(
    Variance,
    (expected_time, expected_id);
    labels=("time", "id"),
    weighting=ExponentialWeighting(0.5)
)

@test index(myview, :time) == expected_time
@test index(myview, :id) == expected_id

myview[start, 1] = 5.0
@test expected_time[1] == expected_time[1]

# Test `insert!` with a datum
datum = create_datum((expected_time[1], 2, 3.0))
insert!(
    myview,
    datum
)

# Check index, cache tuple returned from `data`
idx, cache = components(myview)
@test collect(keys(idx)) == [:time, :id]
@test collect(values(idx)) == Array[expected_time, expected_id]
@test cache[1,2] == 3.0

# Check subselection
subselect = myview[
    expected_time[2]:expected_time[4],
    2:5
]

@test data(subselect) == sub(data(myview), 2:4, 2:5)

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
@test data(partitioned[start, (:gps, :weather)]) == zeros(15)

partitioned[start, (:gps => 1,)] = 1.0
@test data(partitioned[start, (:gps, :weather,)]) != zeros(15)

test_gps = [1.0, 2.0, 3.0, 4.0, 5.0]
partitioned[start, :gps] = test_gps
sliced_partitioned = partitioned[start, :gps]
idx, cache = components(sliced_partitioned)
@test collect(keys(idx)) == [:gps]
@test cache == test_gps

idx, cache = components(sub(partitioned, start, :gps))
@test collect(keys(idx)) == [:time, :gps]
@test cache == test_gps'

@test data(partitioned[start, 1:2]) == test_gps[1:2]
data(partitioned[start, OrderedDict((:gps => 1:2, :direction => 3:4))])[2]

stats_partitioned = DataView(Variance, index_map)

alternate_partitioned = DataView((expected_time,
    (:gps => 1:5, :direction => 1:8, :weather => 1:10));
    labels=(:time, :features)
)
