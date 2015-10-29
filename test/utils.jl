
@test findfirst(1:10, 3) == 3
@test findfirst(1:10, 15) == 0

@test findfirst(0:5:40, 25) == 6
@test findfirst(5:5:40, 1) == 0

r1 = DateTime(now())-Dates.Day(60):Dates.Day(5):DateTime(now())
r2 = r1[1:5]

@test findfirst(r1, r1[3]) == 3
@test findfirst(r1, DateTime(now() + Dates.Day(1))) == 0

@test findin(r1, r2) == 1:5

r3 = 0:5:40
idx = findin(r3, 8:2:30)
@test isa(idx, StepRange)
@test r3[idx] == 10:10:30
