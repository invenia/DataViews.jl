# Test interface
type BadDatum <: AbstractDatum end

bd = BadDatum()

@test_throws(ErrorException, keys(bd))
@test_throws(ErrorException, value(bd))


convert_data(data::Tuple{Int, Int, Int}) = (
    unix2datetime(data[1]),
    data[2],
    float(data[3])
)

datum = create_datum((1, 2, 3))
@test isa(datum, AbstractDatum)
@test isa(datum, Datum)
@test keys(datum) == (1, 2)
@test value(datum) == 3

# Test conversions
dt_now = now()
int_now = Int(datetime2unix(dt_now))

datum_factory = create_datum(convert_data)
conv_datum = datum_factory((int_now, 5, 8))
@test isa(conv_datum, AbstractDatum)
@test isa(conv_datum, Datum)
@test keys(conv_datum) == (dt_now, 5)
@test value(conv_datum) == 8.0
