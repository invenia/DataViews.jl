using DataStructures


abstract AbstractDataView{I, T}

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
type DataView{I<:Any, T<:AbstractDataCache} <: AbstractDataView{I,T}
    index::OrderedDict{Symbol, I}
    cache::T
end

"""
`DataViews{T<:AbstractDataCache}(index::OrderedDict{Symbol, Any}, cache::T` is the default
constructor that the other DataView constructors call, which explicitly takes the index
dict and DataCache.
"""
function DataView{I<:Any, T<:AbstractDataCache}(index::OrderedDict{Symbol, I}, cache::T)
    new_index = build_index(index)

    calculated = tuple(get_cache_dim(new_index)...)
    actual = size(cache)
    if calculated != actual
        error("Dimension dimension mismatch: index=$(calculated), cache=$actual, orig_map=$index, new_map=$new_index")
    end

    DataView{I,T}(new_index, cache)
end

"""
`DataViews{T<:AbstractDataCache}(expected::Tuple, cache::T; label=())` explicityly takes the
cache, but allows optionally specifying the labels.
"""
function DataView{T<:AbstractDataCache}(expected::Tuple, cache::T; labels=())
    DataView(
        build_index(expected, labels),
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
    new_index = build_index(index)
    DataView(
        new_index,
        DataCache(
            get_cache_dim(new_index)...;
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
    index = build_index(expected, labels)
    cache = DataCache(
        get_cache_dim(index)...;
        empty_value=empty_value,
        mmapped=mmapped
    )

    DataView(index, cache)
end

"""
`DataView{T<:OnlineStat}(::Type{T}, index::Dict{Symbol, Any}; stats_dim=1)`
builds a DataView with a `StatsCache` of type `T`.
"""
function DataView{T<:OnlineStat, I<:Any}(::Type{T}, index::OrderedDict{Symbol, I}; stats_dim=1, weighting=EqualWeight())
    new_index = build_index(index)
    cache = StatsCache(T, get_cache_dim(new_index)...; stats_dim=stats_dim, weighting=weighting)
    DataView(
        new_index,
        cache
    )
end


"""
`DataView{T<:OnlineStat}(::Type{T}, expected::Tuple; labels=(), stats_dim=1)`
builds a DataView with a `StatsCache` of type `T`.
"""
function DataView{T<:OnlineStat}(::Type{T}, expected::Tuple; labels=(), stats_dim=1, weighting=EqualWeight())
    index = build_index(expected, labels)
    cache = StatsCache(T, get_cache_dim(index)...; stats_dim=stats_dim, weighting=weighting)
    DataView(
        index,
        cache
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
                if isa(tmp_exp, OrderedDict)
                    tmp_idx = findin(1:size(view.cache, i), tmp_idx)
                else
                    tmp_idx = findin(tmp_exp, tmp_idx)
                end

                if length(tmp_idx) == 0
                    error("$(idx[i]) is not found in $(tmp_exp)")
                end
            elseif isa(tmp_idx, Tuple{Vararg{Symbol}}) || isa(tmp_idx, Symbol)
                if !isa(tmp_exp, OrderedDict)
                    error("$tmp_idx only works for partition indices, but $(tmp_exp) is not a partitioned index")
                end

                if isa(tmp_idx, Symbol)
                    tmp_idx = (tmp_idx,)
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
    view[keys(model)...] = value(model)
end


"""
`setindex!(view::DataView, x::Any, idx...)` Calls `setindex!` on the cache,
using the expected keys to determine the determine the element(s) to
set in the cache.
"""
function Base.setindex!(view::DataView, x::Any, i...)
    idx = convert_partitions(pad(view, i))
    index = indices(view, idx...)
    view.cache[index...] = x
end

Base.getindex(view::DataView, i...) = slice(view, i...)

function Base.slice(view::DataView, i...)
    idx = convert_partitions(pad(view, i))
    index = indices(view, idx...)

    sliced = slice(view.cache, index...)

    if length(sliced) == 1
        return sliced[1]
    else
        idx_vals = collect(values(view.index))
        idx_keys = collect(keys(view.index))

        # Handle what was dropped by the slice
        new_idx = Any[]
        new_index = Any[]
        new_idx_vals = Any[]
        new_idx_keys = Any[]

        for j in eachindex(index)
            if (isa(index[j], Colon) ||
                (isa(index[j], AbstractArray) && length(index[j]) > 1))
                push!(new_idx, idx[j])
                push!(new_index, index[j])
                push!(new_idx_vals, idx_vals[j])
                push!(new_idx_keys, idx_keys[j])
            end
        end

        new_exp = reindex(new_idx_vals, new_index, new_idx)

        return DataView(
            tuple(new_exp...),
            sliced;
            labels=(new_idx_keys...)
        )
    end
end

"""
`getindex(view::DataView, idx...)` performs array style indexing on the
`DataView`. However, to avoid memory overhead the returned DataView is built
from a sub cache rather than a copy of it. Also, if the subcache contains a
single value then that value will be returned rather than a new DataView.
"""
function Base.sub(view::DataView, i...)
    idx = convert_partitions(pad(view, i))
    index = indices(view, idx...)

    subcache = sub(view.cache, index...)

    # If the resulting subcache containts just 1 element
    # just return that element otherwise return a new
    if length(subcache) == 1
        return subcache[1]
    else
        idx_vals = collect(values(view.index))
        new_exp = reindex(idx_vals, index, idx)

        return DataView(
            tuple(new_exp...),
            subcache;
            labels=(keys(view.index)...)
        )
    end
end


"""
`index(view::DataView, label::Symbol)` provides a mechanism for querying the
`DataView` for its indices by label. NOTE: All labels are stored as Symbols.
"""
function index(view::DataView, labels::Vararg{Symbol})
    if length(labels) > 1
        return tuple(map(i -> view.index[i], labels)...)
    elseif length(labels) == 1
        return view.index[labels[1]]
    else
        return view.index
    end
end

data(view::DataView) = view.cache

"""
`raw(view::DataView)` returns the labels, indices and cache as a tuple.
"""
components(view::DataView) = view.index, view.cache


Base.insert!(view::AbstractDataView, x::Any) = error("Not Implemented")
Base.getindex(view::AbstractDataView, idx...) = error("Not Implemented")
Base.setindex!(view::AbstractDataView, x::Any, idx...) = error("Not Implemented")
index(view::AbstractDataView, labels::Vararg{Symbol}) = error("Not Implemeneted")
data(view::AbstractDataView) = error("Not Implemeneted")
components(view::AbstractDataView) = error("Not Implemeneted")


function get_cache_dim(index::OrderedDict)
    result = map(values(index)) do d
        l = 0

        if isa(d, Associative)
            for k in keys(d)
                l += length(d[k])
            end
        elseif isa(d, AbstractArray)
            for i in d
                if isa(i, AbstractArray) || isa(i, Tuple)
                    l += length(i)
                else
                    l += 1
                end
            end
        else
            l += 1
        end
        return l
    end
    return result
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

function build_index(expected::Tuple, labels::Tuple)
    if isempty(labels)
        labels = tuple(map(i -> Symbol("$i"), 1:length(expected))...)
    elseif length(labels) == length(expected)
        labels = map(i -> Symbol(i), labels)
    else
        error("You must provide labels for each key. labels=$labels; keys=$expected")
    end

    @assert isa(labels, Tuple)
    @assert isa(expected, Tuple)

    return build_index(OrderedDict(zip(labels, expected)))
end

function build_index(index::OrderedDict)
    new_index = copy(index)

    # Convert partitions to OrderedDicts
    i = 1
    for (key, val) in index
        if isa(val, Tuple{Vararg{Tuple}}) || isa(val, Tuple{Vararg{Pair}})
            new_dict = OrderedDict{Symbol, Any}()
            for item in val
                new_dict[Symbol(item[1])] = item[2]
            end

            new_index[key] = new_dict
        end

        # If a partitioned dim has 1 or 0 items we collapse the partition
        if isa(new_index[key], OrderedDict) && length(new_index[key]) <= 1
            # If the partitioned dim has 1 partition we replace the dim with the name of
            # partition and its values
            if length(new_index[key]) == 1
                new_keys = collect(keys(new_index))
                new_vals = Any[values(new_index)...]

                new_key = collect(keys(new_index[key]))[1]
                new_val = new_index[key][new_key]

                new_keys[i] = new_key
                new_vals[i] = new_val

                new_index = OrderedDict(zip(new_keys, new_vals))
            else
                # We remove the collapsed
                pop!(new_index, key)
            end
        end
        i += 1
    end

    return new_index
end

function reindex(expected, sub_indices, idx)
    new_exp = Any[]

    for i in eachindex(sub_indices)
        if isa(expected[i], Associative)
            sub_dict = OrderedDict()
            if isa(idx[i], Tuple{Vararg{Symbol}}) || isa(idx[i], Symbol)
                tmp_idx = idx[i]
                if isa(idx[i], Symbol)
                    tmp_idx = (idx[i],)
                end

                for key in tmp_idx
                    sub_dict[key] = expected[i][key]
                end
            elseif isa(idx[i], Associative)
                for key in keys(idx[i])
                    sub_dict[key] = expected[i][key][idx[i][key]]
                end
            elseif isa(idx[i], AbstractArray)
                count = 1
                all_found = Any[]
                for key in keys(expected[i])
                    start_idx = count
                    end_idx = count + 1
                    val = expected[i][key]

                    if isa(val, AbstractArray)
                        end_idx = count + length(val)
                    end
                    count = end_idx

                    found = findin(start_idx:end_idx, idx[i])
                    if length(found) > 0
                        sub_dict[key] = found
                        push!(all_found, found...)
                    end
                end

                @assert Set(all_found) == Set(idx[i])
            elseif isa(idx[i], Colon)
                sub_dict = expected[i]
            end

            push!(new_exp, sub_dict)
        else
            push!(new_exp, expected[i][sub_indices[i]])
        end
    end

    return new_exp
end

function pad(view, idx)
    len_diff = length(view.index) - length(idx)

    if len_diff > 0
        return vcat(
            idx...,
            fill(:, len_diff)...
        )
    else
        return idx
    end
end

