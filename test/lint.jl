# Run lint DataViews.jl for Error or Critical level message
using Lint

@lintpragma("DataViews.DataView{I,T<:DataViews.AbstractDataCache{T,N}} is a container type")

msgs = lintpkg("DataViews", returnMsgs=true)

for m in msgs
    @test Lint.level(m) != :ERROR
end
