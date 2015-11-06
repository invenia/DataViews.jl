module DataViews

using DBI
using OnlineStats


include("utils.jl")
include("datums.jl")
include("caches.jl")
include("views.jl")
include("sources.jl")

export
    AbstractDatum,
    DefaultDatum,
    value,

    AbstractDataCache,
    DefaultCache,
    StatsCache,
    DataCache,

    AbstractDataView,
    DataView,
    data,

    AbstractDataSource,
    SQLDataSource,
    SQLConnectionInfo,
    fetch!

end
