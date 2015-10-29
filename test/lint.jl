# Run lint DataViews.jl for Error or Critical level message
using Lint

msgs = lintpkg("DataViews", returnMsgs=true)
for m in msgs
    @test m.level < 2
end
