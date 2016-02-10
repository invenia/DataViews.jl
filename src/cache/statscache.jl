"""
`StatsCache{T<:OnlineStat,N}` is a cache that stores
running statistics along some dimension using the
Variance type from OnlineStats.jl
"""
immutable StatsCache{T<:OnlineStat,N} <: AbstractDataCache{T,N}
    data::AbstractArray{T,N}
    stats_dim::Int64
end

"""
`StatsCache{T<:OnlineStat,N}(a::Array{T,N}, stats_dim::Int64)` is
the base constructor for a StatsCache.
"""
function StatsCache{T<:OnlineStat,N}(a::Array{T,N}, stats_dim::Int64)
    StatsCache{T,N}(a, stats_dim)
end

"""
`DataCache{T<:OnlineStat}(::Type{T}, dims::Int64...; stats_dim::Int64=1)` is
constructor for building a StatsCache.
"""
function StatsCache{T<:OnlineStat}(::Type{T}, dims::Int...; stats_dim::Int=1, weighting=EqualWeight())
    a = Array(T, dims...)
    #init_val = T(weighting)
    map(i -> a[i] = T(deepcopy(weighting)), eachindex(a))
    StatsCache{T,ndims(a)}(a, stats_dim)
end

"`data(cache::StatsCache)` just returns the data field."
data(cache::StatsCache) = cache.data

"`sub(cache::StatsCache, idx::Base.ViewIndex...)` builds a new StatsCache with subarray of `data`"
Base.sub(cache::StatsCache, idx::Base.ViewIndex...) = StatsCache(sub(data(cache), idx...), cache.stats_dim)

"`slice(cache::StatsCache, idx::Base.ViewIndex...)` builds a new StatsCache with subarray of
`data`, but drops any dimensions of length 1"
function Base.slice(cache::StatsCache, idx::Base.ViewIndex...)
    # Set the stats_dim to -1 if slice has dropped that dimension to avoid
    # breaking our subcache.
    stats_dim = -1
    if (cache.stats_dim >= 1 && length(idx) < stats_dim
        && (isa(idx[cache.stats_dim], Colon) || length(idx[cache.stats_dim]) > 1))

        stats_dim = cache.stats_dim
    end

    sliced = slice(data(cache), idx...)
    StatsCache(sliced, stats_dim)
end
"""
`setindex!(cache::DataCache, x::Any, idx::Int...` copies the previous element
along the `stats_dim` if there is one and calls `update!` with `x` at location `idx`.
"""
function Base.setindex!(cache::StatsCache, x::Any, idx::Int...)
    if cache.stats_dim != -1 && idx[cache.stats_dim] > 1
        prev_idx = [idx...]
        prev_idx[cache.stats_dim] -= 1
        data(cache)[idx...] = copy(data(cache)[prev_idx...])
    end

    fit!(data(cache)[idx...], x)
end

# For common operations like mean or std on the StatsCache data we
# should probably add them here.
