"""
`DataCache{T,N}` is the default cache type used by DataViews.
It is simply wrapper to an n-dimensional array with a default empty
value of 0.0.
"""
immutable DataCache{T,N} <: AbstractDataCache{T,N}
    data::AbstractArray{T,N}
end

"""
`DataCache{T,N}{a::AbstractArray{T,N})` is the base constructor
for a DataCache.
"""
DataCache{T,N}(a::AbstractArray{T,N}) = DataCache{T,N}(a)

"""
`DataCache{T}(dims::Int64...; empty_value::T=0.0, mapped=false)` is a
constructor for building a DataCache that may or may or not be memory
mapped.
"""
function DataCache{T}(dims::Int...; empty_value::T=0.0, mmapped=false)
    if mmapped
        array = Mmap.mmap(Array{T, length(dims)}, dims...)
        if length(array) > 0 && array[1] != empty_value
            fill!(array, empty_value)
        end
        return DataCache{T,length(dims)}(array)
    else
        return DataCache{T,length(dims)}(fill(empty_value, dims...))
    end
end

"`data(cache::DataCache)` just returns the data field."
data(cache::DataCache) = cache.data

"`sub(cache::DataCache, idx::Base.ViewIndex...)` builds a new DataCache with subarray of `data`"
Base.sub(cache::DataCache, idx::Base.ViewIndex...) = DataCache(sub(data(cache), idx...))

"`slice(cache::DataCache, idx::Base.ViewIndex...)` builds a new DataCache with a slice of `data`"
Base.slice(cache::DataCache, idx::Base.ViewIndex...) = DataCache(slice(data(cache), idx...))

"`setindex!(cache::DataCache, x::Any, idx::Int...` sets the index in the `data` of the DataCache"
Base.setindex!(cache::DataCache, x::Any, idx::Int...) = data(cache)[idx...] = x
