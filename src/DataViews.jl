module DataViews

using DBI
using OnlineStats

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
    data,

    AbstractDataSource,
    SQLDataSource,
    SQLConnectionInfo,
    fetch!

end
