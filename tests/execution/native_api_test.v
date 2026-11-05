module valibro_test

import math
import math.big
import time
import valibro as v
import valibro.json as j
import valibro.jsoncodec
import valibro.types
import x.json2

fn test_native_results_preserve_validation_issues_and_execution_errors() {
	schema := v.pipe(v.string(), v.min_length(3), v.ends_with('z'))
	assert v.parse(schema, 'abz')! == 'abz'
	if _ := v.parse(schema, 'a') {
		assert false
	} else {
		assert err is types.ValidationError
		if err is types.ValidationError { assert err.issues.map(it.code) == [
				'min_length',
				'ends_with',
			]
		 }
	}
	dataset := v.inspect(schema, 'a')!
	assert dataset.typed
	assert dataset.value == 'a'
	assert dataset.issues.len == 2
	assert !v.is_valid(schema, 'a')!
	assert v.inspect(schema, 'a', abort_early: true)!.issues.len == 1
	fallible := v.pipe_to(v.string(), v.try_transform[string, int](fn (input string) !int {
		if input == 'io' { return error('callback failed') }
		return input.len
	}))
	assert v.parse(fallible, 'hello')! == 5
	for _ in 0 .. 1 {
		if _ := v.is_valid(fallible, 'io') {
			assert false
		} else {
			assert err.msg() == 'callback failed'
		}
		if _ := v.parse(v.fallback(fallible, 42), 'io') {
			assert false
		} else {
			assert err.msg() == 'callback failed'
		}
	}
}

fn test_native_options_and_domain_types_need_no_library_wrappers() {
	schema := v.pipe(v.string(), v.trim(), v.min_length(2))
	present := ?string(' Alex ')
	absent := ?string(none)
	if input := present {
		assert v.parse(schema, input)! == 'Alex'
	} else {
		assert false
	}
	assert absent or { 'guest' } == 'guest'
	mut calls := 0
	if input := absent {
		v.parse(schema, input)!
		calls++
	}
	assert calls == 0
}

fn test_json_presence_distinguishes_missing_null_and_value() {
	schema := j.object({
		'name': j.optional(j.string(), default_value: json2.Any('guest'))
		'note': j.optional(j.nullable(j.string()))
	})
	output := j.parse_text(schema, '{}')!.as_map()
	assert output['name']! == json2.Any('guest')
	assert 'note' !in output
	null := j.parse_text(schema, '{"note":null}')!.as_map()
	assert null['note']! is json2.Null
	assert !j.is_valid(schema, json2.Any({
		'name': json2.Any(json2.Null{})
	}))!
	assert !j.is_valid(j.nullable(j.string()), json2.Any(1))!
	missing := j.inspect(j.object({
		'name': j.string()
	}), json2.Any(map[string]json2.Any{}))!
	assert missing.issues[0].received == 'missing'
	strict := j.strict_object({
		'name': j.string()
	})
	assert !j.is_valid(strict, json2.Any({
		'name':  json2.Any('Alex')
		'extra': json2.Any(1)
	}))!
	tuple := j.tuple([j.string(), j.number()])
	assert j.is_valid(tuple, json2.Any([json2.Any('Alex'), json2.Any(1)]))!
	alternative := j.union([j.string(), j.number()])
	assert j.is_valid(alternative, json2.Any('Alex'))!
	assert !j.is_valid(alternative, json2.Any(true))!
	picked := j.pick(j.object({
		'name': j.string()
		'age':  j.number()
	}), ['name'])
	assert j.parse_text(picked, '{"name":"Alex"}')!.as_map().len == 1
	partial := j.partial(strict)
	assert j.is_valid(partial, json2.Any(map[string]json2.Any{}))!
	required := j.required(partial)
	assert !j.is_valid(required, json2.Any(map[string]json2.Any{}))!
}

struct NativeJsonRecord {
	count         i64
	label         string @[json: 'name']
	absent        ?string
	explicit_null ?string @[json_null]
	hidden        string  @[skip]
	zero          int     @[omitempty]
	instant       time.Time
}

fn test_native_json_encoding_preserves_fields_options_and_integer_precision() {
	input := NativeJsonRecord{
		count:   9223372036854775807
		label:   'Alex'
		hidden:  'private'
		instant: time.unix_nanosecond(0, 1)
	}
	encoded := v.parse(v.pipe_to(v.schema[NativeJsonRecord](),
		v.stringify_json_value[NativeJsonRecord]()), input)!
	assert encoded.contains('9223372036854775807')
	assert encoded.contains('"name":"Alex"')
	assert encoded.contains('"explicit_null":null')
	assert !encoded.contains('absent')
	assert !encoded.contains('hidden')
	assert !encoded.contains('zero')
	assert encoded.contains('1970-01-01T00:00:00.000000001Z')
	assert jsoncodec.stringify(json2.Any(u64(18446744073709551615)))! == '18446744073709551615'
	assert !v.is_valid(v.pipe_to(v.bigint(), v.stringify_json_value[big.Integer]()),
		big.integer_from_int(1))!
}

fn test_json_number_options_round_once_and_default_encoding_stays_exact() {
	for text, bits in {
		'9007199254740993':        u64(4845873199050653696)
		'1e23':                    u64(4950912855330343670)
		'2.4703282292062328e-324': u64(1)
		'-0.0':                    u64(9223372036854775808)
	} {
		output := jsoncodec.decode(text, binary64_numbers: true)!
		assert math.f64_bits(output.f64()) == bits, text
	}
	value := json2.Any({
		'x': json2.Any([json2.Any(1), json2.Any(2)])
	})
	pretty := jsoncodec.stringify(value, space: 2)!
	assert pretty.contains('\n  "x": [\n    1,\n    2\n  ]')
	if _ := jsoncodec.stringify(value, max_depth: 1) {
		assert false
	} else {
		assert err.msg() == 'JSON serialization depth exceeded'
	}
	for text in ['01', '1 trailing', 'NaN', 'Infinity', '{"x":[1,]}'] {
		if _ := jsoncodec.decode(text) { assert false, text
		 }
	}
}
