using OnlineStats

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
function StatsCache{T<:OnlineStat}(::Type{T}, dims::Int...; stats_dim::Int=1, weighting=EqualWeighting())
    dump(T)
    a = Array(T, dims...)
    map(i -> a[i] = T(weighting), eachindex(a))
    StatsCache{T,ndims(a)}(a, stats_dim)
end

"`data(cache::StatsCache)` just returns the data field."
data(cache::StatsCache) = cache.data

"`sub(cache::StatsCache, idx::Base.ViewIndex...)` builds a new StatsCache with subarray of `data`"
Base.sub(cache::StatsCache, idx::Base.ViewIndex...) = StatsCache(sub(data(cache), idx...), cache.stats_dim)

"""
`setindex!(cache::DataCache, x::Any, idx::Int...` copies the previous element
along the `stats_dim` if there is one and calls `update!` with `x` at location `idx`.
"""
function Base.setindex!(cache::StatsCache, x::Any, idx::Int...)
    if idx[cache.stats_dim] > 1
        prev_idx = [idx...]
        prev_idx[cache.stats_dim] -= 1
        data(cache)[idx...] = copy(data(cache)[prev_idx...])
    end
    OnlineStats.update!(data(cache)[idx...], x)
end

# For common operations like mean or std on the StatsCache data we
# should probably add them here.
