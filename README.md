# DataViews.jl

[![Build Status](https://travis-ci.org/invenia/DataViews.jl.jl.svg?branch=dev)](https://travis-ci.org/invenia/DataViews.jl.jl)
[![codecov.io](https://codecov.io/github/invenia/DataViews.jl/coverage.svg?branch=master)](https://codecov.io/github/invenia/DataViews.jl?branch=master)

Types
---------

#### DataSource ####

A DataSource defines a way of retrieving raw data from a db, csv, socket or arbitrary function.
DataSources are responsible for fetching this data and inserting it into DataViews with the help
of a user provided datum type and insert method. The DataSource is also responsible for returning DataViews
from the fetch function.


#### DataView ####

A DataView provides a simple DataFrame like interface to the source data, while providing a more efficient way of storing it.
Typically, DataViews store the data in an n-dimensional array
(ie: shared, sparse, memory-mapped, nullable, variance, etc), where the dimensions represent indices. Each dimension index uses a
dict to map arbitrary keys to array indices.

NOTE: while all DataView implementations should support the same interface, there are clear performance trade offs based on what
backend storage structure is being used.

Methods
--------

* `fetch(src::DataSource)` - Grabs the raw data and feeds it into the DataViews with the datum type provided. If the DataViews are already being populated the DataViews will be returned.
* `insert(view::DataView, x::Type{Datum})` - Inserts the datum into the DataView using the fieldnames of the datum type and the index and value names.
# `get(view::DataView, ...)` - Responds to various queries on the DataView (look how DataFrames.jl does it).


Requirements from User
-----------------------

* `DataSource` - the user will need to instantiate their own DataSource and DataViews.
* `DataSchema` - converts the rows/lines/tuples returned from the DataSource into a type with appropriately named fields.
* `DataViews` -
    1) know the type of the view they'd like to use (ie: shared, sparse, memory-mapped)
    2) provide the value name and
    3) named indices.

    The names used in the last two should match the fieldnames in the DatumType in order for inserts to work correctly.


TODO:
* Figure out a cleaner way to abstract the DataView storage method (may need to be done at the application level).
