# Test the DefaultCache
default_cache = DataCache(3, 4; empty_value=NaN)
default_cache[1,1] = 0.0
@test default_cache[1,1] == 0.0
default_cache[2,:] = ones(4)

@test default_cache[1,1] == 0.0
@test vec(default_cache[2,:]) == vec(ones(4))
@test isnan(default_cache[1,2])
@test default_cache[2, :] == data(sub(default_cache, 2, :))

# Test a StatsCache
stats_cache = DataCache(Variance, 3, 4)
stats_cache[1,1] = 2.0
@test mean(stats_cache[1,1]) == 2.0
@test nobs(stats_cache[1,1]) == 1
stats_cache[2,1] = 4.0
@test mean(stats_cache[2,1]) == 3.0
@test nobs(stats_cache[2,1]) == 2

stats_cache[2, :] = ones(4)
@test map(i -> nobs(stats_cache[2,i]), eachindex(stats_cache[2,:])) == [2, 1, 1, 1]
@test stats_cache[2,:] == data(sub(stats_cache, 2, :))
