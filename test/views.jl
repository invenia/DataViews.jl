start = DateTime(now())
stop = start - Day(60)
expected_time = collect(start:Day(1):stop)
expected_id = collect(1:200)

myview = DataView((expected_time, expected_id); labels=("time", "id"))

@test myview[:time] == expected_time
@test myview[:id] == expected_id

myview[start, 1] = 5.0
