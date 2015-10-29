cache = DefaultDataCache(3, 4; empty_value=NaN)
cache[1,1] = 0.0
cache[2,:] = ones(4)

@test cache[1,1] == 0.0
@test isnan(cache[1,2])
@test cache[2, :] == data(sub(cache, 2, :))
