
datum = DefaultDatum((1, 2, 3))
@test keys(datum) == (1, 2)
@test value(datum) == 3
