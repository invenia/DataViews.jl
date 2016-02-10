# Test Interface
import OnlineStats: Variance, mean, nobs

type BadCache <: AbstractDataCache end

bc = BadCache()
@test_throws(ErrorException, data(bc))
@test_throws(ErrorException, sub(bc, 1))
@test_throws(ErrorException, bc[1] = 1.0)

# Test the DefaultCache
default_cache = DataCache(3, 4; empty_value=NaN)
default_cache[1,1] = 0.0
@test default_cache[1,1] == 0.0
default_cache[2,:] = ones(4)

@test default_cache[1,1] == 0.0
@test vec(default_cache[2,:]) == vec(ones(4))
@test isnan(default_cache[1,2])
@test default_cache[2, :] == data(sub(default_cache, 2, :))
@test vec(default_cache[2, :]) == data(slice(default_cache, 2, :))

# Test a StatsCache
stats_cache = DataViews.StatsCache(Variance, 3, 4)
stats_cache[1,1] = 2.0

@test mean(stats_cache[1,1]) == 2.0
@test nobs(stats_cache[1,1]) == 1
stats_cache[2,1] = 4.0
@test mean(stats_cache[2,1]) == 3.0
@test nobs(stats_cache[2,1]) == 2

stats_cache[2, :] = ones(4)
@test map(i -> nobs(stats_cache[2,i]), eachindex(stats_cache[2,:])) == [2, 1, 1, 1]
@test stats_cache[2,:] == data(sub(stats_cache, 2, :))
@test vec(stats_cache[2,:]) == data(slice(stats_cache, 2, :))

# Test a VersionCache
# Should create a 3 x 4 Persistent Array that
# is accessible as a 3rd dimension
version_cache = DataViews.VersionCache(3, 4)

version_cache[1,1,1] = 2.0
@test version_cache[1,1,1] == 2.0

version_cache[4,1,1] = 4.5
@test version_cache[4,1,1] == 4.5
sub_ver_cache = sub(version_cache, 2, :, :)
sliced_ver_cache = slice(version_cache, 2, :, :)
#@test isa(data(sub_ver_cache), PersistentArray)
