# DataViews.jl

[![Build Status](https://travis-ci.org/invenia/DataViews.jl.svg?branch=master)](https://travis-ci.org/invenia/DataViews.jl)
[![codecov.io](https://codecov.io/github/invenia/DataViews.jl/coverage.svg?branch=master)](https://codecov.io/github/invenia/DataViews.jl?branch=master)

Types
---------

#### DataSource ####

A DataSource defines a way of retrieving raw data from a db, csv, socket or arbitrary function.
DataSources are responsible for fetching this data and inserting it into DataViews with the help
of a user provided datum type and insert method. The DataSource is also responsible for returning DataViews
with the `fetch!` function. An SQLDataSource is already provided which wraps the DBI (soon to be DBAPI) interface.


#### DataView ####

A DataView provides a simple DataFrame like interface to the source data, while providing a more efficient way of storing it. Typically, DataViews store the data in an n-dimensional array (ie: shared, sparse, memory-mapped, nullable, variance, etc), where the dimensions represent indices. DataViews can use any subtype of AbstractArray to map arbitrary keys to array indices, however, Ranges are preferred for performance reasons. While custom DataViews can be added by subtyping AbstractDataView, DataView should handle most cases.

NOTE: while all DataView implementations should support the same interface, there are clear performance trade offs based on what backend storage structure is being used (DataCache).

#### DataCache ####

The DataCache provides a layer of abstraction between the DataView interface and the underlying storage. While this is normally just some AbstractArray, you may wish to store you data in some other format based on the most common kinds of queries you're making on the resulting DataView. Currently, the only provided cache is DefaultDataCache which is used automatically by DataView.

#### Datum ####

In order to insert arbitrary elements into the DataView a Datum type must be used. It wraps the raw data and implements the `value` and `keys` methods which returns the value and indices into the DataView respectively. By default DefaultDatum is used which takes an iterable of length n and uses the first n-1 elements (in the original ordering) as the keys and the last element as the value.


Usage
--------
```
using Base.Dates
using PostgreSQL
using DataViews

stop = DateTime(now())
start = stop - Day(10)
expected_time = collect(start:Day(1):stop)
expected_id = collect(1:5)

# Assuming we have a table with some time series data
dbinfo = SQLConnectionInfo(
    Postgres,
    "localhost",
    "postgres",
    "",
    "test_db",
    5432
)

view = DataView((expected_time, expected_id); labels=("time", "id"))
query = "
    SELECT obs_time, sensor_id, value 
    FROM test_table 
    WHERE obs_time BETWEEN \$1 AND \$2;
"
src = SQLDataSource(
    dbinfo,
    query,
    (view,);
    parameters=(start, stop)
)

myview = fetch!(src)[1]

myview[start,2]
...
```
* `fetch!(src::DataSource)` - Grabs the raw data and feeds it into the DataViews with the datum type provided. If the DataViews are already being populated the DataViews will be returned.
* `insert!(view::DataView, x::Type{Datum})` - Inserts the datum into the DataView using the fieldnames of the datum type and the index and value names.


Requirements from User
-----------------------

The user will need to instantiate their own DataSource and DataViews.

* `DataSource`
    1. provide source specific information (ie: connection and query info for SQLDataSource)
    2. a list of DataViews to insert into
    3. the Datum to use (default it DefaultDatum as described above).
* `DataViews`
    1. provide the value name and
    2. named indices
    3. specify an alternative cache type if the default (Array{Float64, N) doesn't work.

    The names used in the last two should match the fieldnames in the DatumType in order for inserts to work correctly.


TODO
------
* Alternative cache types.
    1. Variance
    2. Nullable
    3. CircularBuffer
* Alternative source types.
    1. DataStreams as DataSources using DataStreams.jl
    2. Loading from CSV (maybe via DataStreams and CSV.jl?)
* Exporting DataViews to DataFrames.
* Proper parallism support with the threading branch release.
* 
