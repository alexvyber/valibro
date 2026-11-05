module valibro_test

import valibro.tests.support
import math
import math.big
import time
import valibro as v
import valibro.types
import valibro.json as j
import valibro.jsoncodec
import valibro.internal.date as dates
import valibro.internal.number as numbers
import valibro.internal.diagnostics
import x.json2

struct TypedConversions {
	stamp i64
}

pub fn (input TypedConversions) to_number() !f64 {
	return numbers.number_from_string(input.stamp.str())
}

pub fn (input TypedConversions) to_bigint() !big.Integer {
	return big.integer_from_i64(input.stamp)
}

pub fn (input TypedConversions) to_date() !time.Time {
	return dates.date_from_milliseconds(input.stamp)
}

pub fn (input TypedConversions) to_string() !string {
	return input.stamp.str()
}

pub fn (input TypedConversions) to_boolean() !bool {
	return input.stamp != 0
}

struct Unconvertible {}

struct BrokenDateProvider {}

pub fn (input BrokenDateProvider) to_date() !time.Time {
	return time.Time{
		year:  2024
		month: 2
		day:   30
	}
}

struct FailingStringProvider {}

pub fn (input FailingStringProvider) to_string() !string {
	return error('conversion failed')
}

fn test_typed_providers_preserve_native_precision() {
	stamp := i64(9007199254740993)
	input := TypedConversions{stamp}
	base := v.schema[TypedConversions]()
	date := v.parse(v.pipe_to(base, v.to_date_from[TypedConversions]()), input) or { panic(err) }
	assert date.unix_milli() == stamp
	integer := v.parse(v.pipe_to(base, v.to_bigint_from[TypedConversions]()), input) or {
		panic(err)
	}
	assert integer.str() == stamp.str()
	floating := v.parse(v.pipe_to(base, v.to_number_from[TypedConversions]()), input) or {
		panic(err)
	}
	assert math.f64_bits(floating) == math.f64_bits(9007199254740992.0)
	assert v.parse(v.pipe_to(base, v.to_string_from[TypedConversions]()), input) or { panic(err) } == stamp.str()
	assert v.parse(v.pipe_to(base, v.to_boolean_from[TypedConversions]()), input) or { panic(err) }
	assert !support.observe(v.pipe_to(v.schema[BrokenDateProvider](),
		v.to_date_from[BrokenDateProvider]()), BrokenDateProvider{}).success
	failure := support.observe(v.pipe_to(v.schema[FailingStringProvider](),
		v.to_string_from[FailingStringProvider]('Custom')), FailingStringProvider{})
	assert !failure.success
	assert failure.issues[0].message == 'Custom'
	assert types.value_is[FailingStringProvider](failure.raw_output)
}

fn test_boolean_conversions_require_supported_native_values() {
	unsupported := support.observe(v.pipe_to(v.schema[Unconvertible](),
		v.to_boolean_from[Unconvertible]('Choose a boolean explicitly')), Unconvertible{})
	assert !unsupported.success
	assert unsupported.issues[0].message == 'Choose a boolean explicitly'
	assert !support.observe(v.pipe_to(v.date(), v.to_boolean_from[time.Time]()), time.unix(0)).success
	boxed := support.observe(v.pipe_to(v.schema[json2.Any](), v.to_boolean_from[json2.Any]()),
		json2.Any(time.unix(0)))
	assert !boxed.success
	assert types.value_is[json2.Any](boxed.raw_output)
	assert !(v.parse(v.pipe_to(v.number(), v.to_boolean_from[f64]()), 0.0) or { panic(err) })
	assert v.parse(v.pipe_to(v.number(), v.to_boolean_from[f64]()), 1.0) or { panic(err) }
	assert !(v.parse(v.pipe_to(v.schema[[]int](), v.to_boolean_from[[]int]()), []int{}) or {
		panic(err)
	})
	assert v.parse(v.pipe_to(v.schema[[]int](), v.to_boolean_from[[]int]()), [0]) or { panic(err) }
}

fn test_forwarding_uses_presence_and_real_container_access() {
	keys := [types.PathSegment('a'), types.PathSegment('b'), types.PathSegment('c')]
	for child in [json2.Any(0), json2.Any(1), json2.Any(false), json2.Any(''), json2.Any(json2.Null{})] {
		input := json2.Any({
			'a': child
		})
		assert diagnostics.forward_keys(input, keys) == [types.PathSegment('a')]
		action := v.forward(v.check[json2.Any](fn (input json2.Any) bool {
			return false
		}), keys)
		issue := support.observe_json(j.pipe(j.unknown(), action), input).issues[0]
		assert issue.path == [types.PathSegment('a')]
	}
	assert diagnostics.forward_keys(json2.Any(json2.Null{}), keys) == []
	assert diagnostics.forward_keys(json2.Any('abc'), [types.PathSegment('length')]) == []
	assert diagnostics.forward_keys(json2.Any([json2.Any(1)]), [types.PathSegment('length')]) == []
	assert diagnostics.forward_keys(json2.Any([json2.Any(1)]), [types.PathSegment('0')]) == []
	assert diagnostics.forward_keys(json2.Any([json2.Any(1)]), [types.PathSegment(0)]) == [
		types.PathSegment(0),
	]
	assert diagnostics.forward_keys(json2.Any({
		'0': json2.Any(1)
	}), [types.PathSegment(0)]) == []
	assert diagnostics.forward_keys(json2.Any({
		'length': json2.Any(1)
	}), [types.PathSegment('length')]) == [types.PathSegment('length')]
}

fn test_f32_formatting_keeps_its_native_shortest_representation() {
	for value in [f32(0.1), f32(1.234567), f32(1e-7), f32(-0.0)] {
		text := value.str()
		expected := if text.ends_with('.0') { text[..text.len - 2] } else { text }
		assert v.parse(v.pipe_to(v.number_of[f32](), v.to_string_from[f32]()), value) or {
			panic(err)
		} == expected
		assert jsoncodec.stringify(json2.Any(value), v.StringifyJsonConfig{}) or { panic(err) } == expected
	}
	assert v.parse(v.pipe_to(v.number_of[f32](), v.to_string_from[f32]()), f32(0.1)) or {
		panic(err)
	} == '0.1'
	assert numbers.number_from_string('9007199254740993') or { panic(err) } == 9007199254740992.0
}

fn test_simple_json_float_decoding_retains_exact_rounding() {
	for text in ['1e23', '9007199254740993.0',
		'1.00000000000000011102230246251565404236316680908203125'] {
		output := v.parse(v.pipe_to(v.string(), v.parse_json()), text) or { panic(err) }
		expected := numbers.number_from_string(text) or { panic(err) }
		assert math.f64_bits(output.f64()) == math.f64_bits(expected), text
	}
	input := '[1e23,9007199254740993.0]'
	output := v.parse(v.pipe_to(v.string(), v.parse_json()), input) or { panic(err) }
	assert math.f64_bits(output.as_array()[0].f64()) == math.f64_bits(numbers.number_from_string('1e23') or {
		panic(err)
	})
}
