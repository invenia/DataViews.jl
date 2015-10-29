# Run lint DataViews.jl for Error or Critical level message
msgs = lintpkg("DataViews", returnMsgs=true)
for m in msgs
    @test m.level < 2
end
