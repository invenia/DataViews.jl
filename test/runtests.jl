include("../src/DataViews.jl")

using DataViews
using Base.Test

using DBI
using PostgreSQL
using DataStructures

import Base.Dates: Day

TEST_DIR = pwd()

# lint tests commented out until Lint.jl
# stops break our tests or producing lots of warnings.
tests = [
    "lint",
    "utils",
    "datums",
    "caches",
    "views",
    "sources",
]


println("Running tests:")


for t in tests
    tfile = string(t, ".jl")
    println(" * $(tfile) ...")
    include(joinpath(TEST_DIR, tfile))
end
