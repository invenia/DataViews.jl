import Base: intersect, findin, findfirst
import Base.Dates: DateTime, Period, unix2datetime, datetime2unix, Second


"""
Provides a datetime specific intersection by taking datetime ranges reducing the DateTime
and step Period to seconds performing a normal StepRange{Int,Int} intersection and the converting
the result back. For now we only do second level accuracy, but milliseconds may be supported in the future.
"""
function intersect{S<:Period}(r::StepRange{DateTime,S}, s::StepRange{DateTime,S})
    nintersect = Base.intersect(integer_range(r), integer_range(s))

    #return integer_range(r), integer_range(s)
    return datetime_range(S, nintersect)
end


function Base.findfirst{T<:Any}(keys::Range{T}, key::T)
    if key in keys
        step_type = typeof(step(keys))
        return round(Int, step_type(key - first(keys)) / step(keys)) + 1
    else
        return 0
    end
end


function Base.findin{T<:Any}(a::StepRange{T}, b::StepRange{T})
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
