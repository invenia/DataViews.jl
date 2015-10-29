module DataViews

include("utils.jl")
include("datums.jl")
include("caches.jl")
include("views.jl")
#include("sources.jl")

export
    AbstractDatum,
    DefaultDatum,
    value,

    AbstractDataCache,
    DefaultDataCache,

    AbstractDataView,
    DataView,
    data

    # AbstractDataSource,
    # SQLDataSource,
    # SQLConnectionInfo,
    # fetch!

end
