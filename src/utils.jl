import Base: intersect, findin, findfirst
import Base.Dates: DateTime, Period, unix2datetime, datetime2unix, Second


"""
`intersect{S<:Period}(r::StepRange{DateTime,S}, s::StepRange{DateTime,S})`
provides a datetime specific intersection by 1) taking datetime ranges 2)reducing
the DateTime and step Period to seconds 3)performing a normal StepRange{Int,Int}
intersection and then 4)converting the result back. For now we only do second
level accuracy, but milliseconds may be supported in the future.
"""
function intersect{S<:Period}(r::StepRange{DateTime,S}, s::StepRange{DateTime,S})
    nintersect = Base.intersect(integer_range(r), integer_range(s))

    #return integer_range(r), integer_range(s)
    return datetime_range(S, nintersect)
end

"""
Simply tests whether a is within b.

NOTE: this is a less strict version of issubset as it doesn't test
the internal values, which is useful for querying by different UnitRanges.
"""
function within(a, b)
    if first(a) < first(b) || last(a) > last(b)
        return false
    else
        return true
    end
end

"""
`findfirst{T<:Any}(keys::Range{T}, key::T)` calculates the first index
in a Range where the `key` is located. In base julia `findfirst` with a Range
is the same function as with any `AbstractArray` which searches linearly
rather than using the information in the Range to calculate the index.
"""
function Base.findfirst{T<:Any}(keys::Range{T}, key::T)
    if key in keys
        step_type = typeof(step(keys))
        return round(Int, step_type(key - first(keys)) / step(keys)) + 1
    else
        return 0
    end
end

"""
`findin{T<:Any, S<:Any}(a::StepRange{T,S}, b::StepRange{T,S})` provides `findin`
method that returns a StepRange{T} when given two StepRange{T}.
Currently, `findin` only returns a Range{T} when working with UnitRanges,
otherwise an `Array` is returned, which we want to avoid in DataViews.
"""
function Base.findin{T<:Any,S<:Any}(a::StepRange{T,S}, b::StepRange{T,S})
    nintersect = intersect(a, b)
    step_type = typeof(step(a))

    nstart = findfirst(a, first(nintersect))
    nstep = round(Int, step(nintersect) / step(a))
    nstop = findfirst(a, last(nintersect))

    return nstart:nstep:nstop
end


function integer_range(x::StepRange)
    nstart = Int(datetime2unix(first(x)))
    nstep = Int(Second(step(x)))
    nstop = Int(datetime2unix(last(x)))

    return nstart:nstep:nstop
end


function datetime_range{T<:Period}(t::Type{T}, x::StepRange)
    nstart = unix2datetime(first(x))
    nstep = T(Second(step(x)))
    nstop = unix2datetime(last(x))

    return nstart:nstep:nstop
end
