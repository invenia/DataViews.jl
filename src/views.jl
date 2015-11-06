abstract AbstractDataView


"""
`DataView{T<:AbstractDataCache}` provides a mechanism for arbitrary indexing strategies
into an n-dimensional Array beyond just integer indexing. Similarly, these indices can be
labelled.

That being said, whenever possible you should use UnitRanges or StepRanges as this keeps
indexing along a dimension to O(1) rather than O(n), where n is the length of that dimension.
Whenever possible DataViews will attempt to maintain the use of Ranges during subselections.

NOTE: The actual storage of the data is handled by the cache choice, which should minimize
the likelihood of needing to create a custom view type.
"""
immutable DataView{T<:AbstractDataCache} <: AbstractDataView
    labels::Tuple{Vararg{Symbol}}
    expected::Tuple
    cache::T
end

"""
`DataViews{T<:AbstractDataCache}(expected::Tuple, cache::T, label=())` is the default
constructor that the other DataView constructors call which takes explicitly takes a
DataCache.
"""
function DataView{T<:AbstractDataCache}(expected::Tuple, cache::T; labels=())
    if isempty(labels)
        labels = map(i -> symbol(i), 1:length(expected))
    elseif length(labels) == length(expected)
        labels = map(i -> symbol(i), labels)
    else
        error("You must provide labels for each key.")
    end

    DataView{T}(
        labels,
        expected,
        cache
    )
end

"""
`DataView(expected::Tuple; labels=(), empty_value=0.0, mmapped=false)` is a
helper constructorwhich will build a DefaultCache for you with the
empty_value provided. If type of the empty_value`isbits` you can also tell
it to build a memory mapped cache. Given that the default empty_value is 0.0
this assumes that your cache type with only contain Floats.
"""
function DataView(expected::Tuple; labels=(), empty_value=0.0, mmapped=false)
    DataView(
        expected,
        DataCache(
            map(i -> length(i), expected)...;
            empty_value=empty_value,
            mmapped=mmapped
        );
        labels=labels
    )
end

"""
`DataView{T<:OnlineStat}(::Type{T}, expected::Tuple; labels=(), stats_dim=1)`
builds a DataView with a `StatsCache` of type `T`.
"""
function DataView{T<:OnlineStat}(::Type{T}, expected::Tuple; labels=(), stats_dim=1)
    cache = DataCache(T, map(i -> length(i), expected)...; stats_dim=stats_dim)
    DataView(
        expected,
        cache;
        labels=labels
    )
end


"""
`insert!(view::DataView, model::DefaultDatum)` handle the insertion of a
`Datum` into the `DataCache` for the view. The values returned
by `keys(datum)` to select the cache index and the value to be
inserted should be returned by `value(datum)`.
"""
function Base.insert!(view::DataView, model::AbstractDatum)
    index = Array{Any, 1}(length(view.labels))
    fill!(index, -1)

    for i in eachindex(index)
        idx = findfirst(view.expected[i], keys(model)[i])

        if idx > 0
            index[i] = idx
        else
            error("$(keys(model)[i]) is not in $(view.expected[i])")
        end
    end

    view.cache[index...] = value(model)
end


"""
`setindex!(view::DataView, x::Any, idx...)` Calls `setindex!` on the cache,
using the expected keys to determine the determine the element(s) to
set in the cache.
"""
function Base.setindex!(view::DataView, x::Any, idx...)
    index = Array{Any, 1}(length(view.labels))
    fill!(index, :)

    for i in eachindex(index)
        tmp_exp = view.expected[i]
        tmp_idx = idx[i]

        if !isa(tmp_idx, Colon)
            if isa(tmp_idx, Range) || !isa(tmp_idx, AbstractArray)
                tmp_idx = findfirst(tmp_exp, tmp_idx)
            else
                tmp_idx = findin(tmp_exp, tmp_idx)
            end
        end

        index[i] = tmp_idx
    end

    view.cache[index...] = x
end


"""
`getindex(view::DataView, idx...)` performs array style indexing on the
`DataView`. However, to avoid memory overhead the returned DataView is built
from a sub cache rather than a copy of it. Also, if the subcache contains a
single value then that value will be returned rather than a new DataView.
"""
function Base.getindex(view::DataView, idx...)
    index = Array{Base.ViewIndex, 1}(length(view.labels))
    fill!(index, :)

    for i in 1:length(idx)
        tmp_exp = view.expected[i]
        tmp_idx = idx[i]

        if !isa(tmp_idx, Colon)
            if isa(tmp_idx, Union{AbstractArray, Range})
                tmp_idx = findin(tmp_exp, tmp_idx)
            else
                tmp_idx = findfirst(tmp_exp, tmp_idx)
            end

            index[i] = tmp_idx
        end
    end

    subcache = sub(view.cache, index...)

    # If the resulting subcache containts just 1 element
    # just return that element otherwise return a new
    if length(subcache) == 1
        return subcache[1]
    else
        new_exp = tuple(
            map(
                i -> view.expected[i][index[i]],
                eachindex(index)
            )...
        )

        new_lbls = tuple(
            map(
                i -> view.labels[i],
                1:length(size(subcache))
            )...
        )

        return DataView(
            new_exp,
            subcache;
            labels=new_lbls
        )
    end
end


"""
`getindex(view::DataView, label::Symbol)` provides a mechanism for querying the
`DataView` for its indices by label. NOTE: All labels are stored as Symbols.
"""
Base.getindex(view::DataView, label::Symbol) = view.expected[findfirst(view.labels, label)]

"""
`data(view::DataView)` returns the labels, indices and cache as a tuple.
"""
data(view::DataView) = view.labels, view.expected, view.cache


Base.insert!(view::AbstractDataView, x::Type{Any}) = error("Not Implemented")
Base.getindex(view::AbstractDataView, idx...) = error("Not Implemented")
Base.getindex(view::AbstractDataView, label::Symbol) = error("Not Implemented")
Base.setindex!(cache::AbstractDataView, x::Any, idx...) = error("Not Implemented")
data(view::AbstractDataView) = error("Not Implemeneted")
