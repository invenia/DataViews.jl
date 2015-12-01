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

include("datacache.jl")
include("statscache.jl")

if Pkg.installed("PersistentArrays") != nothing
    include("versioncache.jl")
end
