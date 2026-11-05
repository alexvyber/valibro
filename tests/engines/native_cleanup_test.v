module valibro_test

import valibro.internal.number as impl_number
import valibro.internal.coercion as impl_coercion
import math
import time
import valibro as v
import valibro.json as j
import valibro.types
import valibro.jsoncodec
import x.json2

fn test_exact_native_decimal_rounding() {
	for text, bits in {
		'9007199254740993':                                        '4845873199050653696'
		'9007199254740995':                                        '4845873199050653698'
		'1e23':                                                    '4950912855330343670'
		'1.00000000000000011102230246251565404236316680908203125': '4607182418800017408'
		'1.00000000000000011102230246251565404236316680908203126': '4607182418800017409'
		'4.9406564584124654e-324':                                 '1'
		'2.4703282292062327e-324':                                 '0'
		'2.4703282292062328e-324':                                 '1'
		'-1e-999999999999999999999999999999':                      '9223372036854775808'
		'1e999999999999999999999999999999':                        '9218868437227405312'
	} {
		value := impl_number.number_from_string(text) or { panic(err) }
		assert math.f64_bits(value).str() == bits, text
	}
	long := '1' + '0'.repeat(10000) + 'e-10000'
	assert impl_number.number_from_string(long) or { panic(err) } == 1.0
	assert math.is_inf(impl_number.number_from_string('1.7976931348623159e308') or { panic(err) },
		1)
	for text in ['', ' ', '\ufeff42', '42garbage'] {
		assert !v.safe_parse(v.pipe_to(v.string(), v.to_number()), text).success
	}
	for text in ['9007199254740993', '1e23',
		'1.00000000000000011102230246251565404236316680908203125'] {
		parsed := jsoncodec.parse(text, v.ParseJsonConfig{ binary64_numbers: true }) or {
			panic(err)
		}
		assert math.f64_bits(parsed.value.f64()) == math.f64_bits(impl_number.number_from_string(text) or {
			panic(err)
		})
	}
}

fn test_native_strings_and_scalar_conversions() {
	assert v.is_valid(v.pipe(v.string(), v.length(1), v.code_points(1), v.bytes(4)), '🙂')
	assert v.is_valid(v.pipe(v.string(), v.gt_value('\ue000')), '🙂')
	assert v.safe_parse(v.pipe(v.string(), v.starts_with('a')), '🙂').issues[0].received == '"🙂"'
	assert v.safe_parse(v.pipe(v.string(), v.ends_with('a')), '🙂').issues[0].received == '"🙂"'
	assert v.parse(v.pipe_to(v.string(), v.to_boolean()), 'true') or { panic(err) }
	assert !(v.parse(v.pipe_to(v.string(), v.to_boolean()), 'false') or { panic(err) })
	assert !(v.parse(v.pipe_to(v.string(), v.to_boolean()), 'anything') or { panic(err) })
	for input in [json2.Any(json2.Null{}), json2.Any([]json2.Any{}),
		json2.Any({
			'toString': json2.Any('42')
		})] {
		assert !v.safe_parse(v.pipe_to(v.unknown[json2.Any](), v.to_number_from[json2.Any]()),
			input).success
	}
	object := json2.Any({
		'toString': json2.Any(42)
	})
	assert impl_coercion.json_string(object) or { panic(err) } == object.str()
	for input in [1e6, 1e-7, 1e23, -0.0] {
		expected := input.str()
		compact := if expected.ends_with('.0') { expected[..expected.len - 2] } else { expected }
		assert v.parse(v.pipe_to(v.number(), v.to_string_from[f64]()), input) or { panic(err) } == compact
	}
}

fn test_native_json_keys_order_and_indentation() {
	input := json2.Any({
		'2':           json2.Any(2)
		'1':           json2.Any(1)
		'constructor': json2.Any(3)
		'__proto__':   json2.Any(4)
		'prototype':   json2.Any(5)
	})
	for schema in [j.loose_object({}), j.object_with_rest({}, j.number()),
		j.record(j.string(), j.number())] {
		output := j.parse(schema, input) or { panic(err) }
		assert output.as_map().keys() == input.as_map().keys()
		assert j.equal(output, input)
	}
	encoded := jsoncodec.stringify(input, v.StringifyJsonConfig{}) or { panic(err) }
	assert encoded == '{"2":2,"1":1,"constructor":3,"__proto__":4,"prototype":5}'
	assert jsoncodec.stringify(json2.Any([json2.Any(1)]), v.StringifyJsonConfig{ space: 12 }) or {
		panic(err)
	} == '[\n            1\n]'
	gap := 'abcdefghijkl🙂'
	assert jsoncodec.stringify(json2.Any([json2.Any(1)]), v.StringifyJsonConfig{ space: gap }) or {
		panic(err)
	} == '[\n${gap}1\n]'
}

fn test_native_date_range_and_float_remainders() {
	for year in [-999999, -300000, 300000, 999999] {
		input := time.Time{
			year:  year
			month: 1
			day:   1
		}
		parsed := v.parse(v.date(), input) or { panic(err) }
		assert parsed.year == year
	}
	assert !v.is_valid(v.date(), time.Time{ year: 1000000, month: 1, day: 1 })
	assert !v.safe_parse(v.pipe_to(v.boolean(), v.to_date_from[bool]()), true).success
	assert v.is_valid(v.pipe(v.number(), v.multiple_of(0.5)), 1.5)
	assert !v.is_valid(v.pipe(v.number(), v.multiple_of(0.1)), 0.3)
	assert !v.is_valid(v.pipe(v.number(), v.multiple_of(0.0)), 1.0)
	assert v.is_valid(v.pipe(v.number(), v.multiple_of(math.inf(1))), 0.0)
	assert !v.is_valid(v.pipe(v.number(), v.multiple_of(1.0)), math.inf(1))
	assert v.is_valid(v.pipe(v.number(), v.multiple_of(5e-324)), 1e-323)
	assert !v.is_valid(v.pipe(v.number(), v.multiple_of(1e308)), 5e-324)
}

fn test_native_struct_containers_and_precise_date_json() {
	set := types.new_set([1, 2])
	encoded := v.parse(v.pipe_to(v.unknown[types.Set[int]](),
		v.stringify_json_value[types.Set[int]]()), set) or { panic(err) }
	assert encoded == '{"values":[1,2]}'
	blob := types.Blob{
		data:      [u8(1), 2]
		mime_type: 'text/plain'
	}
	json := v.parse(v.pipe_to(v.unknown[types.Blob](), v.stringify_json_value[types.Blob]()), blob) or {
		panic(err)
	}
	assert json == '{"data":[1,2],"mime_type":"text/plain"}'
	date := time.unix_nanosecond(0, 1)
	assert v.parse(v.pipe_to(v.date(), v.stringify_json_value[time.Time]()), date) or { panic(err) } == '"1970-01-01T00:00:00.000000001Z"'
}

fn test_native_functions_and_futures_require_explicit_json_values() {
	callable := types.Function[int, int]{
		call: fn (n int) int {
			return n + 1
		}
	}
	result := v.safe_parse(v.pipe_to(v.unknown[types.Function[int, int]](),
		v.stringify_json_value[types.Function[int, int]]()), callable)
	assert !result.success
	assert result.issues[0].received == '"Functions cannot be encoded as JSON"'
	channel := chan types.SafeParseResult[int]{cap: 1}
	future := types.new_future(channel)
	waiting := v.safe_parse(v.pipe_to(v.unknown[types.Future[int]](),
		v.stringify_json_value[types.Future[int]]()), future)
	assert !waiting.success
	assert waiting.issues[0].received == '"Await a Future before JSON serialization"'
}

fn test_native_entry_map_and_file_json() {
	entries := types.entry_map([types.MapEntry[string, int]{ key: 'a', value: 1 }], fn (a string, b string) bool {
		return a == b
	})
	encoded := v.parse(v.pipe_to(v.unknown[types.EntryMap[string, int]](),
		v.stringify_json_value[types.EntryMap[string, int]]()), entries) or { panic(err) }
	assert encoded == '{"entries":[{"key":"a","value":1}]}'
	file := types.File{
		data:          [u8(1)]
		mime_type:     'text/plain'
		name:          'a.txt'
		last_modified: 42
	}
	output := v.parse(v.pipe_to(v.unknown[types.File](), v.stringify_json_value[types.File]()), file) or {
		panic(err)
	}
	assert output == '{"data":[1],"mime_type":"text/plain","name":"a.txt","last_modified":42}'
}

fn test_supplementary_letters_are_classified_as_whole_characters() {
	assert v.parse(v.pipe(v.string(), v.to_kebab_case()), 'a𐐀B') or { panic(err) } == 'a-𐐨b'
	assert v.parse(v.pipe(v.string(), v.to_camel_case()), 'a𐐀B') or { panic(err) } == 'a𐐀b'
}

struct NativeDateJsonProvider {
	value time.Time
}

pub fn (input NativeDateJsonProvider) to_json_value(key string) !types.Maybe[json2.Any] {
	return types.some(json2.Any(input.value))
}

fn test_native_provider_date_projection_retains_precision() {
	input := NativeDateJsonProvider{time.unix_nanosecond(0, 1)}
	result := v.parse(v.pipe_to(v.unknown[NativeDateJsonProvider](),
		v.stringify_json_value[NativeDateJsonProvider]()), input) or { panic(err) }
	assert result == '"1970-01-01T00:00:00.000000001Z"'
}

fn test_native_date_integer_milliseconds_remain_exact() {
	for stamp in [i64(9007199254740993), -9007199254740993, 31494784780799999, -31619087596800000] {
		typed := v.parse(v.pipe_to(v.number_of[i64](), v.to_date_from[i64]()), stamp) or {
			panic(err)
		}
		assert typed.unix_milli() == stamp
		boxed := v.parse(v.pipe_to(v.unknown[json2.Any](), v.to_date_from[json2.Any]()),
			json2.Any(stamp)) or { panic(err) }
		assert boxed.unix_milli() == stamp
	}
	assert !v.safe_parse(v.pipe_to(v.number_of[u64](), v.to_date_from[u64]()),
		u64(18446744073709551615)).success
}
