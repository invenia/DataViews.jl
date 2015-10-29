abstract AbstractDataSource
fetch(src::AbstractDataSource) = error("Not Implemented")

"""
Stores the connection information
"""
immutable SQLConnectionInfo{T<:DBAPI.DatabaseInterface}
    driver::Type{T}
    addr::AbstractString
    username::AbstractString
    password::AbstractString
    dbname::AbstractString
    port::Int64
end


"""
SQLDataSource takes the db connection info, the query info,
a datum type to convert to and a list of view to dump into.
"""
immutable SQLDataSource <: AbstractDataSource
    dbinfo::SQLConnectionInfo                       # Stores common db info required for making a connection to the db
    query::AbstractString                           # the sql query to run
    params::Tuple                                     # Parameters to pass to the query

    datum_type::AbstractDatum                       # A type to convert each row to, which allows us to dispatch on inserting into a cache
    views::Tuple                                    # A list of caches to use.

    fetched::Bool

    function SQLDataSource(dbinfo::SQLConnectionInfo, query::AbstractString, parameters=(), views...; datum_type=DefaultDatum)
        new(
            dbinfo,
            query,
            parameters,
            datum_type,
            views,
            false
        )
    end
end


"""
fetch handles the grabbing of data from the datasource and inserting it into the dataviews.
Currently, this is a synchronous operation, but support for an async fetch maybe provided in the future.
"""
function fetch!(src::SQLDataSource)
    if !src.fetched
        dbinfo = src.dbinfo

        # This entire process of fetching data should probably happen in a separate thread, however,
        # we would need to make restrictions on the order in which data is inserted into the dataview.
        connect(dbinfo.driver, dbinfo.addr, dbinfo.username, dbinfo.password, dbinfo.dbname, dbinfo.port) do conn
            cursor_obj = cursor(conn)
            execute(cursor_obj, src.query, src.params)
            results = rows(cursor_obj)

            for r in results
                datum = datum_type(r)

                # At the very least we parallelize the insertion of the datum into each view.
                @parallel for i in 1:length(views)
                    insert(views[i], datum)
                end
            end
        end
        src.fetched = true
    end
    return src.views
end
