stop = DateTime(now())
start = stop - Day(10)
expected_time = collect(start:Day(1):stop)
expected_id = collect(1:5)

myview = DataView((expected_time, expected_id); labels=("time", "id"))

@test myview[:time] == expected_time
@test myview[:id] == expected_id

myview[start, 1] = 5.0

@test expected_time[1] == expected_time[1]

datum = DefaultDatum((expected_time[1], 2, 3.0))

insert!(
    myview,
    datum
)

@test data(myview)[1, 2] == 3.0

subselect = myview[
    expected_time[2]:expected_time[4],
    2:5
]

@test data(subselect) == sub(data(myview), 2:4, 2:5)
