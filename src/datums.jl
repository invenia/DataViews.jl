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
`DefaultDatum{T}`: a datum describes the data schema to use when inserting
raw data into a DataView. For simplicity we assume the first n-1
elements are the keys and the nth element is the value.
"""
immutable Datum{T} <: AbstractDatum{T}
    keys::Tuple
    value::T
end


function create_datum(data::Tuple)
    Datum{typeof(data[end])}(
        data[1:end-1],
        data[end]
    )
end

"""
`create_datum(conversion::Function)` is a closure for creating
datums using an arbitrary conversion function.

NOTE: could probably use a better name.
"""
function create_datum(convert_func::Function; kwargs...)
    function datum_func(data::Tuple)
        #println(data)
        new_data = convert_func(data; kwargs...)
        #println(new_data)
        Datum{typeof(new_data[end])}(
            new_data[1:end-1],
            new_data[end]
        )
    end

    return datum_func
end

Base.keys(datum::Datum) = datum.keys
value(datum::Datum) = datum.value
