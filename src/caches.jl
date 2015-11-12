import Base: LinearFast, ==


"""
`AbstractDataCache{T,N} is an abstract subtype of AbstractArray
that defines the required interface for a DataCache with sane default
methods for AbstractArray.

[Required Methods]
* `data(cache::AbstractDataCache)` - returns the wrapped data
* `setindex!(cache::AbstractDataCache, x::Any, idx::Int...)` - handles setindex! with multiple scalars.
* `sub(cache::AbstractDataCache, idx::Base.ViewIndex...)` - handles creation of a sub DataCache.

[Option Methods]
* `getindex(cache::AbstractDataCache, idx::Int...)`
* `size(cache::AbstractDataCache, idx::Int...)`
* `length(cache::AbstractDataCache)`
* `linearindexing{T <: AbstractDataCache}(::Type{T})`
* `ndims(cache::AbstractDataCache)`
* `=={T<:AbstractDataCache}(a::T, b::T)`
"""
abstract AbstractDataCache{T,N} <: AbstractArray{T,N}


"""
`DefaultCache{T,N}` is the default cache type used by DataViews.
It is simply wrapper to an n-dimensional array with a default empty
value of 0.0.
"""
immutable DefaultCache{T,N} <: AbstractDataCache{T,N}
    data::AbstractArray{T,N}
end

"""
`DefaultCache{T,N}{a::AbstractArray{T,N})` is the base constructor
for a DefaultCache.
"""
DefaultCache{T,N}(a::AbstractArray{T,N}) = DefaultCache{T,N}(a)


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
`DataCache{T}(dims::Int64...; empty_value::T=0.0, mapped=false)` is a
constructor for building a DefaultCache that may or may or not be memory
mapped.
"""
function DataCache{T}(dims::Int64...; empty_value::T=0.0, mmapped=false)
    if mmapped
        array = Mmap.mmap(Array{T, length(dims)}, dims...)
        if length(array) > 0 && array[1] != empty_value
            fill!(array, empty_value)
        end
        return DefaultCache{T,length(dims)}(array)
    else
        return DefaultCache{T,length(dims)}(fill(empty_value, dims...))
    end
end

"""
`DataCache{T<:OnlineStat}(::Type{T}, dims::Int64...; stats_dim::Int64=1)` is
constructor for building a StatsCache.
"""
function DataCache{T<:OnlineStat}(::Type{T}, dims::Int64...; stats_dim::Int64=1, weighting=EqualWeighting())
    a = Array{T, length(dims)}(dims...)
    map(i -> a[i] = T(weighting), eachindex(a))
    StatsCache{T,ndims(a)}(a, stats_dim)
end

"""
`data(cache::AbstractDataCache)` throws a 'Not Implemented' error.
"""
data(cache::AbstractDataCache) = error("Not Implemented")

"""
`getindex(cache::AbstractDataCache, idx::Int...)` provides
a default behaviour for DataCaches that call getindex on its wrapped `data`.
"""
Base.getindex(cache::AbstractDataCache, idx::Int...) = getindex(data(cache), idx...)

"""
`size(cache::AbstractDataCache, idx::Int...)` provides a
default behaviour for DataCaches that call size on its wrapped `data`.
"""
Base.size(cache::AbstractDataCache, idx::Int...) = size(data(cache), idx...)

"""
`length(cache::AbstractDataCache)` provides a default behaviour for
DataCaches that call length on its wrapped `data`.
"""
Base.length(cache::AbstractDataCache) = length(data(cache))

"""
`sub(cache::AbstractDataCache, idx::Base.ViewIndex...)` throws a 'Not Implemeneted' error.
"""
Base.sub(cache::AbstractDataCache, idx::Base.ViewIndex...) = error("Not Implemented")

"""
`setindex!(cache::AbstractDataCache, x::Any, idx::Int...)` throws a 'Not Implemeneted' error.
"""
Base.setindex!(cache::AbstractDataCache, x::Any, idx::Int...) = error("Not Implemented")

"""
`linearindexing{T <: AbstractDataCache}(::Type{T})` default is LinearFast
"""
Base.linearindexing{T <: AbstractDataCache}(::Type{T}) = LinearFast()

"""
`ndims(cache::AbstractDataCache)` returns the number of dimensions of the wrapped `data`
"""
Base.ndims(cache::AbstractDataCache) = ndims(data(cache))

"""
`=={T<:AbstractDataCache}(a::T, b::T)` provides an equality check for
all subtypes of `AbstractDataCache`
"""
=={T<:AbstractDataCache}(a::T, b::T) = data(a) == data(b)

"`data(cache::DefaultCache)` just returns the data field."
data(cache::DefaultCache) = cache.data

"`sub(cache::DefaultCache, idx::Base.ViewIndex...)` builds a new DefaultCache with subarray of `data`"
Base.sub(cache::DefaultCache, idx::Base.ViewIndex...) = DefaultCache(sub(data(cache), idx...))

"`setindex!(cache::DefaultCache, x::Any, idx::Int...` sets the index in the `data` of the DefaultCache"
Base.setindex!(cache::DefaultCache, x::Any, idx::Int...) = data(cache)[idx...] = x

"`data(cache::DefaultCache)` just returns the data field."
data(cache::AbstractDataCache) = cache.data

"`sub(cache::DefaultCache, idx::Base.ViewIndex...)` builds a new StatsCache with subarray of `data`"
Base.sub(cache::StatsCache, idx::Base.ViewIndex...) = StatsCache(sub(data(cache), idx...), cache.stats_dim)

"""
`setindex!(cache::DefaultCache, x::Any, idx::Int...` copies the previous element
along the `stats_dim` if there is one and calls `update!` with `x` at location `idx`.
"""
function Base.setindex!(cache::StatsCache, x::Any, idx::Int...)
    if idx[cache.stats_dim] > 1
        prev_idx = [idx...]
        prev_idx[cache.stats_dim] -= 1
        data(cache)[idx...] = copy(data(cache)[prev_idx...])
    end
    update!(data(cache)[idx...], x)
end

# For common operations like mean or std on the StatsCache data we
# should probably add them here.
