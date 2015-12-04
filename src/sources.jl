using DBI

"""
`AbstractDataSource` provides an interfaces for wrappers that help
map inserting raw data from real data sources into `DataView`s.

[Required Methods]
* fetch!(src::AbstractDataSource) fetches data an inserts into into the
   DataViews, returning those DataViews.
"""
abstract AbstractDataSource
fetch!(src::AbstractDataSource) = error("Not Implemented")

"""
`SQLConnectionInfo{T<:DBI.DatabaseSystem}` stores the common
connection information needed by DBI to create the DB connection.
"""
immutable SQLConnectionInfo{T<:DBI.DatabaseSystem}
    driver::Type{T}
    addr::AbstractString
    username::AbstractString
    password::AbstractString
    dbname::AbstractString
    port::Int64
end


"""
`SQLDataSource{T<:AbstractDatum}` is a subtype of AbstractDataSource which implements
the DataSource interface for DBI compatible raw sources. Takes the db connection
info, the query info, a datum type to convert to and a list of view to dump into.

NOTE: currently isn't mutable cause of the fetched bool.
"""
type SQLDataSource <: AbstractDataSource
    dbinfo::SQLConnectionInfo                       # Stores common db info required for making a connection to the db
    query::AbstractString                           # the sql query to run
    views::Tuple{Vararg{AbstractDataView}}          # A list of caches to use.
    params::Tuple                                   # Parameters to pass to the query
    converters::Tuple{Vararg{Function}}             # A type to convert each row to, which allows us to dispatch on inserting into a cache
    fetched::Bool
end

"""
`SQLDataSource{T<:AbstractDatum}` the SQLDataSource constructor.
"""
function SQLDataSource(
        dbinfo::SQLConnectionInfo,
        query::AbstractString,
        views::Tuple{Vararg{AbstractDataView}};
        parameters::Tuple=(),
        converters::Union{Function, Tuple{Vararg{Function}}}=create_datum
    )
    if isempty(views)
        error("Please supply at least 1 DataView.")
    end

    convert_funcs = converters
    if isa(converters, Function)
        convert_funcs = (map(i -> converters, 1:length(views))...)
    elseif length(converters) != length(views)
        error("Please provide a converter function for each view.")
    end

    SQLDataSource(
        dbinfo,
        query,
        views,
        parameters,
        convert_funcs,
        false
    )
end

"""
`fetch!(src::SQLDataSource)` handles the grabbing of data from the datasource
and inserting it into the dataviews. Currently, this is a synchronous
operation, but support for an async fetch maybe provided in the future.
"""
function fetch!(src::SQLDataSource)
    if !src.fetched
        dbinfo = src.dbinfo

        # This entire process of fetching data should probably happen in a separate thread, however,
        # we would need to make restrictions on the order in which data is inserted into the dataview.
        connect(dbinfo.driver, dbinfo.addr, dbinfo.username, dbinfo.password, dbinfo.dbname, dbinfo.port) do conn
            stmt = prepare(conn, src.query)
            results = execute(stmt, [src.params...])

            if errcode(conn) != 0 || errstring(conn) != ""
                error("
                    Query Failed with '$(errstring(conn))($(errcode(conn)))':\n
                        \tStatement=$(src.query), Parameters=$(src.params)
                ")
            end

            for r in results
                #println(r)
                #datum = src.datum((r...))
                #println(typeof(datum))
                #println(datum)
                # At the very least we parallelize the insertion of the datum into each view.
                for i in 1:length(src.views)
                    datum = src.converters[i]((r...))
                    insert!(src.views[i], datum)
                end
            end
        end
        src.fetched = true
    end
    return src.views
end
