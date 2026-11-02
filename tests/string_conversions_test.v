module valibro_test

import math
import math.big
import time
import valibro as v
import valibro.types
import x.json2

fn test_string_number_conversion() {
	schema := v.pipe_to(v.string(), v.to_number())
	for input, expected in {
		'':        0.0
		' \ufeff': 0.0
		' 42 ':    42.0
		'-1.5e2':  -150.0
		'.5':      0.5
		'12.':     12.0
		'0xff':    255.0
		'0O17':    15.0
		'0B101':   5.0
	} {
		value := v.parse(schema, input) or { panic('${input}: ${err}') }
		assert value == expected
	}
	for input in ['x', '42px', 'NaN', 'nan', '+0x1', '-0b1', '0x', '1_000', '.'] {
		assert !v.safe_parse(schema, input).success, input
	}
	assert math.is_inf(v.parse(schema, 'Infinity') or { panic(err) }, 1)
	assert math.is_inf(v.parse(schema, '-Infinity') or { panic(err) }, -1)
	assert math.is_inf(v.parse(schema, '1e999') or { panic(err) }, 1)
	assert math.signbit(v.parse(schema, '-0') or { panic(err) })
	custom := v.pipe_to(v.string(), v.to_number('Not a number'))
	assert v.safe_parse(custom, 'abc').issues[0].message == 'Not a number'
}

fn test_string_boolean_conversions() {
	truthy := v.pipe_to(v.string(), v.to_boolean())
	assert v.parse(truthy, 'false') or { panic(err) }
	assert !(v.parse(truthy, '') or { panic(err) })
	parsed := v.pipe_to(v.string(), v.parse_boolean())
	for input in ['true', 'TRUE', '1', 'yes', 'Y', 'on', 'Enabled'] {
		assert v.parse(parsed, input) or { panic(err) }
	}
	for input in ['false', 'FALSE', '0', 'no', 'N', 'off', 'Disabled'] {
		assert !(v.parse(parsed, input) or { panic(err) })
	}
	for input in ['', ' true ', 'maybe'] {
		assert !v.safe_parse(parsed, input).success
	}
	custom := v.pipe_to(v.string(), v.parse_boolean_with_config(v.ParseBooleanConfig{
		truthy: [
			'OK',
		]
		falsy:  ['NOPE']
	}))
	assert v.parse(custom, 'ok') or { panic(err) }
	assert !(v.parse(custom, 'nope') or { panic(err) })
	assert !v.safe_parse(custom, 'true').success
}

fn test_string_bigint_conversion() {
	schema := v.pipe_to(v.string(), v.to_bigint())
	for input, expected in {
		'':                               '0'
		' \ufeff ':                       '0'
		'123456789012345678901234567890': '123456789012345678901234567890'
		'-42':                            '-42'
		'+42':                            '42'
		'0xFF':                           '255'
		'0o17':                           '15'
		'0b101':                          '5'
	} {
		value := v.parse(schema, input) or { panic('${input}: ${err}') }
		assert value.str() == expected
	}
	for input in ['1.5', '1e2', 'Infinity', '+', '-', '0x', '-0xff'] {
		assert !v.safe_parse(schema, input).success
	}
	// Verify the public output is a real arbitrary-precision integer.
	large := v.parse(schema, '123456789012345678901234567890') or { panic(err) }
	assert (large + big.integer_from_int(1)).str() == '123456789012345678901234567891'
}

fn test_string_date_conversion() {
	schema := v.pipe_to(v.string(), v.to_date())
	date := v.parse(schema, '2024-01-02T03:04:05Z') or { panic(err) }
	assert date.unix() == time.new(time.Time{
		year:   2024
		month:  1
		day:    2
		hour:   3
		minute: 4
		second: 5
	}).unix()
	offset := v.parse(schema, '2024-01-02T05:04:05+02:00') or { panic(err) }
	assert offset.unix() == date.unix()
	assert !v.safe_parse(schema, 'not a date').success
	assert v.safe_parse(schema, '2024-01-02').success
	assert v.safe_parse(schema, 'Tue, 02 Jan 2024 03:04:05 GMT').success
}

fn test_string_json_conversions() {
	schema := v.pipe_to(v.string(), v.parse_json())
	obj := v.parse(schema, '{"name":"Alex","n":1}') or { panic(err) }
	assert obj.as_map()['name'] or { panic('Missing name') } == json2.Any('Alex')
	for input in ['null', 'true', '42', '"hello"', '[]', '{}', '[1, false, null]'] {
		assert v.safe_parse(schema, input).success, input
	}
	for input in ['', 'undefined', '[1,]', '{"a":1,}', '1 trailing', 'NaN', '01', '\ufeff{}'] {
		assert !v.safe_parse(schema, input).success, input
	}
	roundtrip := v.pipe_to(schema, v.stringify_json_value[json2.Any]())
	encoded := v.parse(roundtrip, '[1, false, null]') or { panic(err) }
	assert encoded == '[1,false,null]'
}

fn test_conversions_preserve_errors_and_output_types() {
	number := v.pipe_to(v.pipe(v.string(), v.min_length(2)), v.to_number())
	result := v.safe_parse(number, 'a')
	assert result.output == none
	assert result.issues[0].code == 'min_length'
	// A failed conversion must not run a downstream predicate on a default value.
	failed := v.pipe(v.pipe_to(v.string(), v.to_number()), v.check(fn (value f64) bool {
		panic('A downstream check ran after a fatal conversion')
	}, 'Unexpected'))
	assert !v.safe_parse(failed, 'abc').success
	custom := v.pipe_to(v.string(), v.transform_to(fn (input string) int {
		return input.len
	}))
	assert v.parse(custom, 'abc') or { panic(err) } == 3
	checked := v.pipe(custom, v.check(fn (value int) bool {
		return value > 2
	}, 'Too short'))
	assert v.safe_parse(checked, 'abc').success
	assert !v.safe_parse(checked, 'a').success
	raw := v.pipe_to(v.string(), v.raw_transform_to(fn (input string) types.Dataset[int] {
		return types.Dataset[int]{ value: input.len }
	}))
	assert v.parse(raw, 'abc') or { panic(err) } == 3
}

fn test_custom_fatal_failure_cannot_expose_output() {
	failed := v.pipe(v.string(), v.raw_transform(fn (input string) types.Dataset[string] {
		return types.Dataset[string]{ typed: false, value: input }
	}))
	converted := v.pipe_to(failed, v.transform_to(fn (input string) int {
		panic('Transformation ran after an untyped custom result')
	}))
	result := v.safe_parse(converted, 'abc')
	assert !result.success
	assert result.output == none
	assert result.issues.len == 1
	v.parse(failed, 'abc') or {
		assert err.msg() == 'Schema did not produce a typed output'
		return
	}
	assert false, 'Expected a fatal parse error'
}
