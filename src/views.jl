using DataStructures


abstract AbstractDataView{I, T}

typealias IndexValue Union{AbstractArray, }
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
immutable DataView{I<:Any, T<:AbstractDataCache} <: AbstractDataView{I,T}
    index::OrderedDict{Symbol, I}
    cache::T
end

"""
`DataViews{T<:AbstractDataCache}(index::OrderedDict{Symbol, Any}, cache::T` is the default
constructor that the other DataView constructors call, which explicitly takes the index
dict and DataCache.
"""
function DataView{I<:Any, T<:AbstractDataCache}(index::OrderedDict{Symbol, I}, cache::T)
    new_index = copy(index)

    # Convert partitions to OrderedDicts
    for (key, val) in index
        if isa(val, Tuple{Tuple}) || isa(val, Tuple{Pair})
            new_index[key] = OrderedDict(val)
        end
    end

    DataView{I,T}(index, cache)
end

"""
`DataViews{T<:AbstractDataCache}(expected::Tuple, cache::T; label=())` explicityly takes the
cache, but allows optionally specifying the labels.
"""
function DataView{T<:AbstractDataCache}(expected::Tuple, cache::T; labels=())
    if isempty(labels)
        labels = tuple(map(i -> symbol(i), 1:length(expected))...)
    elseif length(labels) == length(expected)
        labels = map(i -> symbol(i), labels)
    else
        error("You must provide labels for each key. labels=$labels; keys=$expected")
    end

    @assert isa(labels, Tuple)
    @assert isa(expected, Tuple)

    DataView(
        OrderedDict(zip(labels, expected)),
        cache
    )
end

"""
`DataView(index::Dict{Symbol, Any}; empty_value=0.0, mmapped=false)` is a
helper constructor which will build a DefaultCache for you with the
empty_value provided. If type of the empty_value`isbits` you can also tell
it to build a memory mapped cache. Given that the default empty_value is 0.0
this assumes that your cache type with only contain Floats.
"""
function DataView{I<:Any}(index::OrderedDict{Symbol, I}; empty_value=0.0, mmapped=false)
    DataView(
        index,
        DataCache(
            get_cache_dim(values(index))...;
            empty_value=empty_value,
            mmapped=mmapped
        )
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
            get_cache_dim(expected)...;
            empty_value=empty_value,
            mmapped=mmapped
        );
        labels=labels
    )
end

"""
`DataView{T<:OnlineStat}(::Type{T}, index::Dict{Symbol, Any}; stats_dim=1)`
builds a DataView with a `StatsCache` of type `T`.
"""
function DataView{T<:OnlineStat, I<:Any}(::Type{T}, index::OrderedDict{Symbol, I}; stats_dim=1, weighting=EqualWeighting())
    cache = StatsCache(T, get_cache_dim(values(index))...; stats_dim=stats_dim, weighting=weighting)
    DataView(
        index,
        cache
    )
end


"""
`DataView{T<:OnlineStat}(::Type{T}, expected::Tuple; labels=(), stats_dim=1)`
builds a DataView with a `StatsCache` of type `T`.
"""
function DataView{T<:OnlineStat}(::Type{T}, expected::Tuple; labels=(), stats_dim=1, weighting=EqualWeighting())
    cache = StatsCache(T, get_cache_dim(expected)...; stats_dim=stats_dim, weighting=weighting)
    DataView(
        expected,
        cache;
        labels=labels
    )
end

# DOUBLE CHECK THIS! Was drunk when I wrote this
# This should be recursive
function indices(view::AbstractDataView, idx...)
    index = Array{Base.ViewIndex, 1}(length(view.index))
    fill!(index, :)

    idx_vals = collect(values(view.index))

    for i in eachindex(index)
        tmp_exp = idx_vals[i]
        tmp_idx = idx[i]

        if !isa(tmp_idx, Colon)
            if isa(tmp_idx, AbstractArray)
                tmp_idx = findin(tmp_exp, tmp_idx)

                if length(tmp_idx) == 0
                    error("$(idx[i]) is not found in $(tmp_exp)")
                end
            elseif isa(tmp_idx, Tuple{Vararg{Symbol}})
                if !isa(tmp_exp, OrderedDict)
                    error("$tmp_idx only works for partition indices, but $(tmp_exp) is not a partitioned index")
                end

                tmp = Int[]
                offset = 0
                for k in keys(tmp_exp)
                    if k in tmp_idx
                        append!(tmp, offset + [1:length(tmp_exp[k])...])
                    end
                    offset += length(tmp_exp[k])
                end
                tmp_idx = tmp
            elseif isa(tmp_idx, Associative)
                if !isa(tmp_exp, OrderedDict)
                    error("$(tmp_exp) is not a valid index argument")
                end

                tmp = Int[]
                offset = 0
                for k in keys(tmp_exp)
                    if haskey(tmp_idx, k)
                        append!(tmp, offset + [findin(tmp_exp[k], tmp_idx[k])...])
                    end
                    offset += length(tmp_exp[k])
                end
                tmp_idx = tmp
            else
                tmp_idx = findfirst(tmp_exp, tmp_idx)

                if tmp_idx == 0
                    error("$(idx[i]) not found in expected $tmp_exp")
                end
            end
        end
        index[i] = tmp_idx
    end

    return index
end


"""
`insert!(view::DataView, model::DefaultDatum)` handle the insertion of a
`Datum` into the `DataCache` for the view. The values returned
by `keys(datum)` to select the cache index and the value to be
inserted should be returned by `value(datum)`.
"""
function Base.insert!(view::DataView, model::AbstractDatum)
    index = Array{Any, 1}(length(view.index))
    fill!(index, -1)

    idx_vals = collect(values(view.index))

    for i in eachindex(index)
        idx = findfirst(idx_vals[i], keys(model)[i])

        if idx > 0
            index[i] = idx
        else
            error("$(keys(model)[i]) is not in $(idx_vals[i])")
        end
    end

    view.cache[index...] = value(model)
end


"""
`setindex!(view::DataView, x::Any, idx...)` Calls `setindex!` on the cache,
using the expected keys to determine the determine the element(s) to
set in the cache.
"""
function Base.setindex!(view::DataView, x::Any, i...)
    idx = convert_partitions(i)
    index = indices(view, idx...)
    view.cache[index...] = x
end


"""
`getindex(view::DataView, idx...)` performs array style indexing on the
`DataView`. However, to avoid memory overhead the returned DataView is built
from a sub cache rather than a copy of it. Also, if the subcache contains a
single value then that value will be returned rather than a new DataView.
"""
function Base.getindex(view::DataView, i...)
    idx = convert_partitions(i)
    index = indices(view, idx...)

    subcache = sub(view.cache, index...)

    # If the resulting subcache containts just 1 element
    # just return that element otherwise return a new
    if length(subcache) == 1
        return subcache[1]
    else
        idx_vals = collect(values(view.index))
        new_exp = Any[]

        for i in eachindex(index)
            if isa(idx_vals[i], Associative)
                sub_dict = OrderedDict()
                if isa(idx[i], Tuple{Vararg{Symbol}})
                    for key in idx[i]
                        sub_dict[key] = idx_vals[i][key]
                    end
                elseif isa(idx[i], Associative)
                    for key in keys(idx[i])
                        sub_dict[key] = idx_vals[i][key][idx[i][key]]
                    end
                end
                push!(new_exp, sub_dict)
            else
                push!(new_exp, idx_vals[i][index[i]])
            end
        end

        return DataView(
            tuple(new_exp...),
            subcache;
            labels=(keys(view.index)...)
        )
    end
end


"""
`getindex(view::DataView, label::Symbol)` provides a mechanism for querying the
`DataView` for its indices by label. NOTE: All labels are stored as Symbols.
"""
Base.getindex(view::DataView, label::Symbol) = view.index[label]

"""
`data(view::DataView)` returns the labels, indices and cache as a tuple.
"""
data(view::DataView) = view.index, view.cache


Base.insert!(view::AbstractDataView, x::Any) = error("Not Implemented")
Base.getindex(view::AbstractDataView, idx...) = error("Not Implemented")
Base.getindex(view::AbstractDataView, label::Symbol) = error("Not Implemented")
Base.setindex!(view::AbstractDataView, x::Any, idx...) = error("Not Implemented")
data(view::AbstractDataView) = error("Not Implemeneted")


function get_cache_dim(expected)
    return map(expected) do d
        l = 0

        if isa(d, Associative)
            for k in keys(d)
                l += length(d[k])
            end
        else
            for i in d
                if isa(i, AbstractArray) || isa(i, Tuple)
                    l += length(i)
                else
                    l += 1
                end
            end
        end
        return l
    end
end

function convert_partitions(x)
    return map(x) do d
        if isa(d, Tuple{Tuple}) || isa(d, Tuple{Pair})
            return OrderedDict(d)
        else
            return d
        end
    end
end
