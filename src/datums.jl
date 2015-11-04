abstract AbstractDatum
Base.keys(datum::AbstractDatum) = error("Not Implemented")
value(datum::AbstractDatum) = error("Not Implemented")


"""
DefaultData:
    Assumptions
        1. data provided to constructor is iterable
        2. the first n-1 elements are keys and the nth element is the value
        3. keys are by default ints and values are by default floats.
"""
immutable DefaultDatum <: AbstractDatum
    keys::Tuple
    value::Float64

    function DefaultDatum(data)
        new(
            data[1:end-1],
            data[end]
        )
    end
end

Base.keys(datum::DefaultDatum) = datum.keys
value(datum::DefaultDatum) = datum.value
