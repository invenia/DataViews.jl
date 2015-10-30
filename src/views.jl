abstract AbstractDataView


"""
The DefaultDataView simply stores the indices and labels and dictionaries.
The actual storage of the data is handled by the cache choice, which should minimize
the likelihood of needing to create a custom view type.
"""
immutable DataView <: AbstractDataView
    labels::Tuple{Vararg{Symbol}}
    expected::Tuple
    cache::AbstractDataCache

    function DataView{T<:AbstractDataCache}(expected::Tuple, cache::T; labels=())
        if isempty(labels)
            labels = map(i -> symbol(i), 1:length(expected))
        elseif length(labels) == length(expected)
            labels = map(i -> symbol(i), labels)
        else
            error("You must provide labels for each key.")
        end

        new(
            labels,
            expected,
            cache
        )
    end
end


"""
This is just a helper constructor which will build a regular DataCache for you.
It assumes the DataCache values should be Float64s and the default value should be 0.0 or can be provided
"""
function DataView(expected::Tuple; labels=(), empty_value=0.0)
    DataView(
        expected,
        DefaultDataCache(
            map(i -> length(i), expected)...,
            empty_value=empty_value
        ),
        labels=labels
    )
end


"""
Inserts a default datum into the cache, using the values returned
by `keys(datum)` to select the cache index.
"""
function Base.insert!(view::DataView, model::DefaultDatum)
    index = fill(-1, length(view.labels))

    for i in eachindex(index)
        idx = findfirst(view.expected[i], keys(model)[i])

        if idx > 0
            index[i] = idx
        else
            error("$(keys(model)[i]) is not in $(view.expected[i])")
        end
    end

    view.cache[index] = value(model)
end


"""
Calls setindex on the cache using the expected keys.
"""
function Base.setindex!(view::DataView, x::Any, idx...)
    index = fill(:, length(view.labels))

    for i in 1:length(idx)
        tmp_exp = view.expected[i]
        tmp_idx = idx[i]

        if !isa(tmp_idx, Colon)
            if isa(tmp_idx, Union{AbstractArray, Range})
                tmp_idx = findin(tmp_exp, tmp_idx)
            else
                tmp_idx = findfirst(tmp_exp, tmp_idx)
            end
        end
    end

    view.cache[index...] = x
end


"""
Indexing on the default dataview returns another dataview with a sub cache.
"""
function Base.getindex(view::DataView, idx...)
    index = Array{Any, 1}(length(view.labels))
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

    #println(index)
    #println(subcache)
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
If the default view is indexed by a label then the indices for that label are returned.
"""
Base.getindex(view::DataView, label::Symbol) = view.expected[findfirst(view.labels, label)]

"""
Returns a labels, indices and raw cache data as a tuple.
"""
data(view::DataView) = view.cache


Base.insert!(view::AbstractDataView, x::Type{Any}) = error("Not Implemented")
Base.getindex(view::AbstractDataView, idx...) = error("Not Implemented")
Base.getindex(view::AbstractDataView, label::Symbol) = error("Not Implemented")
Base.setindex!(cache::AbstractDataView, x::Any, idx...) = error("Not Implemented")
data(view::AbstractDataView) = error("Not Implemeneted")
