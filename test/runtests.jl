include("../src/DataViews.jl")

using DataViews
using Base.Test

using DBI
using PostgreSQL

import Base.Dates: Day

TEST_DIR = pwd()

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
