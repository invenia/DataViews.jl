using PersistentArrays

"""
`VersionCache{T,N}` wraps a PersistentArray such that the versions
in the PersistentArray can be treated as an extra dimension. By default,
the version dimension is the first dimension.
"""
immutable VersionCache{T,N} <: AbstractDataCache{T,N}
    data::Union{PersistentArray, SubArray}
    version_dim::Int64
end

"""
`VersionCache{T}(dims::Int...; version_dim::Int=1, default_value::T=0.0)`
"""
function VersionCache(dims::Int...; version_dim::Int=1, default_value=0.0)
    array_dims = dims[setdiff(1:length(dims), version_dim)...]

    VersionCache{Node, length(dims)-1}(
        PersistentArray(array_dims...; default_value=default_value, default_version=1),
        version_dim
    )
end

"`data(cache::VersionCache)` just returns the data field."
data(cache::VersionCache) = cache.data

"""
`getindex(cache::VersionCache, x:Any, idx::Int..)`
"""
function Base.getindex(cache::VersionCache, idx::Int...)
    array_idx = idx[[setdiff(1:length(idx), cache.version_dim)...]]

    if idx[cache.version_dim] == version(cache.data)
        return cache.data[array_idx...]
    else
        return lookup(cache.data, idx[cache.version_dim], array_idx...)
    end
end

"""
`setindex!(cache::VersionCache, x::Any, idx::Int...)`
"""
function Base.setindex!(cache::VersionCache, x::Any, idx::Int...)
    array_idx = idx[[setdiff(1:length(idx), cache.version_dim)...]]

    if idx[cache.version_dim] >= version(cache.data)
        # If the version specified is larger than the version
        # of the persistent array then we `commit!` till they are equal
        while idx[cache.version_dim] > version(cache.data)
            commit!(cache.data)
        end

        return cache.data[array_idx...] = x
    else
        return PersistentArrays.update!(cache.data, x, idx[cache.version_dim], array_idx...)
    end
end

"""
`sub(cache::VersionCache, idx::Base.ViewIndex...)` builds
a new VersionCache with subarray of `data`.

NOTE: currently the PersistentArray doesn't provide its own `sub` that
handles subarrays of the versions per element so for now we are just
ignoring any sub index specified for the version_dim.
"""
function Base.sub{T,N}(cache::VersionCache{T,N}, idx::Base.ViewIndex...)
    array_idx = idx[[setdiff(1:length(idx), cache.version_dim)...]]
    VersionCache{T,N}(
        sub(
            data(cache),
            array_idx...
        ),
        cache.version_dim
    )
end
