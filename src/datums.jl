"""
`AbstractDatum{T}` defines an interface for inserting
raw data into a `DataView`.

[Required Methods]
* `keys(datum::AbstractDatum)` returns the keys in order for insertion.
* `value(datum::AbstractDatum)` returns the value to insert.
"""
abstract AbstractDatum{T}
Base.keys(datum::AbstractDatum) = error("Not Implemented")
value(datum::AbstractDatum) = error("Not Implemented")


"""
`DefaultDatum{T}`: the default datum type for inserting raw
data into a DataView. For simplicity we assume the first n-1
elements are the keys and the nth element is the value.
"""
immutable DefaultDatum{T} <: AbstractDatum{T}
    keys::Tuple
    value::T
end

"""
`DefaultDatum(data::Tuple) is the `DefaultDatum`
constructor. It determines the type `T` for `DefaultDatum{T}`
from the type of the last element in the supplied data tuple.
"""
function DefaultDatum(data::Tuple)
    DefaultDatum{typeof(data[end])}(
        data[1:end-1],
        data[end]
    )
end

Base.keys(datum::DefaultDatum) = datum.keys
value(datum::DefaultDatum) = datum.value
