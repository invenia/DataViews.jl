abstract AbstractDataCache
Base.getindex(cache::AbstractDataCache, idx...) = error("Not Implemented")
Base.sub(cache::AbstractDataCache, idx...) = error("Not Implemented")
Base.setindex!(cache::AbstractDataCache, x::Any, idx...) = error("Not Implemented")
data(cache::AbstractDataCache) = error("Not Implemented")

"""
The default cache type is simply an n-dimensional array with a
default empty value of 0.0.
"""
immutable DefaultDataCache <: AbstractDataCache
    data::AbstractArray

    DefaultDataCache(dims::Int64...; empty_value=0.0) = new(fill(empty_value, dims...))
    DefaultDataCache(a::AbstractArray) = new(a)
end

Base.getindex(cache::DefaultDataCache, idx...) = getindex(cache.data, idx...)
Base.sub(cache::DefaultDataCache, idx...) = DefaultDataCache(sub(cache.data, idx...))
Base.setindex!(cache::DefaultDataCache, x::Any, idx...) = setindex!(cache.data, x, idx...)
Base.length(cache::DefaultDataCache) = length(cache.data)
data(cache::DefaultDataCache) = cache.data
