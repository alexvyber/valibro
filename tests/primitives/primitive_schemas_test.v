module valibro_test

import valibro.tests.support
import math
import math.big
import time
import valibro as v
import valibro.actions
import valibro.methods
import valibro.schemas

fn test_number_schema_rejects_nan_but_accepts_infinity_and_signed_zero() {
	for input in [0.0, -0.0, 42.5, -42.5, math.inf(1), math.inf(-1)] {
		output := v.parse(v.number(), input) or { panic(err) }
		assert output == input
		assert math.signbit(output) == math.signbit(input)
	}
	result := support.observe(v.pipe(v.number(), v.check(fn (input f64) bool {
		panic('Check ran after NaN schema failure')
	})), math.nan())
	assert !result.success
	assert result.output == none
	assert result.issues.len == 1
	assert result.issues[0].code == 'number'
	assert result.issues[0].expected == 'number'
	assert result.issues[0].received == 'NaN'
	assert result.issues[0].path.len == 0
	assert support.observe(v.number('No NaN'), math.nan()).issues[0].message == 'No NaN'
	dynamic := v.number(v.message_fn(fn (issue v.Issue) string {
		return '${issue.code}: ${issue.received}'
	}))
	assert support.observe(dynamic, math.nan()).issues[0].message == 'number: NaN'
}

fn check_native_number_type[T](input T) {
	output := v.parse(v.number_of[T](), input) or { panic(err) }
	assert typeof(output).name == typeof(input).name
	assert output == input
}

fn test_native_numeric_schemas_preserve_types_and_full_integer_precision() {
	check_native_number_type[i8](-128)
	check_native_number_type[i16](-32768)
	check_native_number_type[i32](-2147483647 - 1)
	check_native_number_type[int](-42)
	check_native_number_type[i64](-9223372036854775807 - 1)
	check_native_number_type[u8](255)
	check_native_number_type[u16](65535)
	check_native_number_type[u32](4294967295)
	check_native_number_type[u64](18446744073709551615)
	check_native_number_type[f32](1.5)
	check_native_number_type[f64](1.5)
	assert !support.observe(v.number_of[f32](), f32(math.nan())).success
	assert support.observe(v.number_of[f32](), f32(math.inf(1))).success
}

fn test_boolean_and_bigint_schemas() {
	assert v.parse(v.boolean(), true) or { panic(err) }
	assert !(v.parse(v.boolean(), false) or { panic(err) })
	assert support.observe(v.pipe(v.boolean(), v.value(true)), true).success
	assert !support.observe(v.pipe(v.boolean(), v.value(true)), false).success
	assert support.observe(v.pipe(v.boolean(), v.not_value(true)), false).success
	assert support.observe(v.pipe(v.boolean(), v.values([true, false])), false).success
	assert !support.observe(v.pipe(v.boolean(), v.not_values([true, false])), false).success
	for input in ['0', '-123456789012345678901234567890', '123456789012345678901234567890'] {
		value := big.integer_from_string(input) or { panic(err) }
		output := v.parse(v.bigint(), value) or { panic(err) }
		assert output == value
		assert output.str() == input
	}
}

fn test_date_schema_checks_calendar_fields_and_repairs_cached_timestamp() {
	raw := time.Time{
		year:       2024
		month:      2
		day:        29
		hour:       12
		minute:     30
		second:     45
		nanosecond: 999999999
	}
	output := v.parse(v.date(), raw) or { panic(err) }
	assert output == time.new(raw)
	stale := time.Time{
		...time.unix(1700000000)
		year:  2024
		month: 2
		day:   29
	}
	repaired := v.parse(v.date(), stale) or { panic(err) }
	assert repaired.unix() == time.new(time.Time{
		year:   2024
		month:  2
		day:    29
		hour:   stale.hour
		minute: stale.minute
		second: stale.second
	}).unix()
	assert repaired.unix() != stale.unix()
	assert output.nanosecond == raw.nanosecond
	for input in [time.unix(0), time.now(), time.utc(),
		time.new(time.Time{
			year:  -9999
			month: 1
			day:   1
		}),
		time.new(time.Time{ year: 9999, month: 12, day: 31 })] {
		parsed := v.parse(v.date(), input) or { panic(err) }
		assert parsed.unix() == input.unix()
		assert parsed.is_local == input.is_local
	}
	for input in [time.Time{}, time.Time{ ...raw, year: -271822 },
		time.Time{ ...raw, year: 275761 }, time.Time{ ...raw, year: 2023 },
		time.Time{ ...raw, month: 0 }, time.Time{ ...raw, month: 13 },
		time.Time{ ...raw, day: 0 }, time.Time{ ...raw, day: 30 },
		time.Time{ ...raw, hour: -1 }, time.Time{ ...raw, hour: 24 },
		time.Time{ ...raw, minute: -1 }, time.Time{ ...raw, minute: 60 },
		time.Time{ ...raw, second: -1 }, time.Time{ ...raw, second: 60 },
		time.Time{ ...raw, nanosecond: -1 }, time.Time{ ...raw, nanosecond: 1000000000 }] {
		result := support.observe(v.date('Invalid calendar'), input)
		assert !result.success, input.debug()
		assert result.output == none
		assert result.issues.len == 1
		assert result.issues[0].code == 'date'
		assert result.issues[0].message == 'Invalid calendar'
	}
}

fn test_primitive_submodule_imports() {
	assert methods.parse(methods.pipe(schemas.number(), actions.finite(), actions.integer()), 42.0) or {
		panic(err)
	} == 42.0
	assert methods.parse(schemas.number_of[int](), 42) or { panic(err) } == 42
	assert methods.parse(schemas.boolean(), true) or { panic(err) }
	assert methods.parse(schemas.bigint(), big.integer_from_int(42)) or { panic(err) } == big.integer_from_int(42)
	assert methods.parse(schemas.date(), time.unix(0)) or { panic(err) } == time.unix(0)
}
