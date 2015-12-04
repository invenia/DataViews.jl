function fill_db(conn)
    for x in 10:15
        for y in 3:7
            stmt = prepare(conn, "
                INSERT INTO test_table
                VALUES (\$1, \$2, \$3);
            ")
            execute(stmt, [x, y, rand() + 1.0])
            finish(stmt)
            @test errcode(conn) == 0
            @test errstring(conn) == ""
        end
    end
end

dbinfo = SQLConnectionInfo(
    Postgres,
    "localhost",
    "postgres",
    "",
    "julia_test",
    5432
)

connect(dbinfo.driver, dbinfo.addr, dbinfo.username, dbinfo.password, dbinfo.dbname, dbinfo.port) do conn
    try
        # Fill the db
        stmt = prepare(conn, "
            CREATE TABLE test_table
            (
                x INTEGER,
                y INTEGER,
                val DOUBLE PRECISION
            )
        ")
        execute(stmt)
        finish(stmt)
        @test errcode(conn) == 0
        @test errstring(conn) == ""

        fill_db(conn)

        # Test basic SQLDataSource
        view = DataView((10:15, 3:7); labels=("x", "y"))
        src = SQLDataSource(dbinfo, "SELECT * FROM test_table", (view,))

        views = fetch!(src)

        @test length(views) == 1
        @test views[1][11, 4] != 0.0

        # Test bad query
        bad_src = SQLDataSource(dbinfo, "I DON'T KNOW HOW TO SQL", (view,))
        @test_throws(ErrorException, fetch!(bad_src))

        @test_throws(ErrorException, SQLDataSource(dbinfo, "SELECT * FROM test_table", ()))
        @test_throws(ErrorException, SQLDataSource(dbinfo, "SELECT * FROM test_table", (view,); converters=()))
    finally
        stmt = prepare(conn, "DROP TABLE test_table")
        execute(stmt)
    end
end
