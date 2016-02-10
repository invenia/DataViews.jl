module DataViews

using DBI
import OnlineStats: OnlineStat, ExponentialWeight, EqualWeight, fit!

macro lintpragma( s )
end

@lintpragma("DataViews.DataView{I,T<:DataViews.AbstractDataCache{T,N}} is a container type")

include("cache/Cache.jl")

include("utils.jl")
include("datums.jl")

include("views.jl")
include("sources.jl")

export
    AbstractDatum,
    Datum,
    value,
    create_datum,

    AbstractDataCache,
    DataCache,

    AbstractDataView,
    DataView,
    index,
    data,
    components,

    AbstractDataSource,
    SQLDataSource,
    SQLConnectionInfo,
    fetch!

end
