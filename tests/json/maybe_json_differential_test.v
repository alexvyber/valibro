module valibro_test

import os
import time
import math.big
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

@[heap]
struct MaybeJsonCalls {
mut:
	values []string
}

struct MaybeJsonHook {
	calls &MaybeJsonCalls
}

pub fn (value MaybeJsonHook) to_json_value(key string) !types.Maybe[json2.Any] {
	mut calls := value.calls
	calls.values << 'H:' + key
	return types.some(json2.Any({
		'key':   json2.Any(key)
		'value': json2.Any(42)
	}))
}

struct MaybeJsonFields[T] {
	a types.Maybe[T]
	b types.Maybe[T]
}

fn maybe_json_result[T](input T, config v.StringifyJsonConfig) types.SafeParseResult[string] {
	return v.safe_parse(v.pipe_to(v.unknown[T](), v.stringify_json_value_with_config[T](config)),
		input)
}

fn maybe_json_case[T](row map[string]json2.Any, payload T, mut calls MaybeJsonCalls) {
	state := (row['state'] or { panic('state') }).str()
	placement := (row['placement'] or { panic('placement') }).str()
	mode := (row['mode'] or { panic('mode') }).str()

	mut input := types.Maybe[T]{}
	match state {
		'missing' { input = types.missing[T]() }
		'undefined' { input = types.undefined_value[T]() }
		'null' { input = types.null_value[T]() }
		else { input = types.some(payload) }
	}

	mut config := v.StringifyJsonConfig{}
	if mode == 'whitelist' { config = v.StringifyJsonConfig{
			property_list: ['b', 'key', 'value']
		} }
	if mode in ['recover', 'omit_root'] {
		config = v.StringifyJsonConfig{
			replacer_with_presence: fn [mut calls, mode] (key string, value types.Maybe[json2.Any], context v.JsonReplacerContext) !types.Maybe[json2.Any] {
				state := if value.state in [.missing, .undefined] {
					'undefined'
				} else if value.state == .null {
					'null'
				} else {
					'value'
				}
				calls.values << 'R:' + key + ':' + state
				if key == '' && mode == 'omit_root' { return types.undefined_value[json2.Any]() }
				if state == 'undefined' && mode == 'recover' {
					return types.some(json2.Any('recovered'))
				}
				return value
			}
		}
	}
	result := maybe_json_placed[T](input, placement, config)
	expected := row['success'] or { panic('success') }
	assert result.success == expected.bool(), row.str()
	expected_output := row['output'] or { panic('output') }
	assert (result.output or { '' }) == expected_output.str(), '${row}: ${result.output or { '' }}'
	expected_calls := row['calls'] or { panic('calls') }
	assert calls.values == expected_calls.as_array().map(it.str()), '${row}: ${calls.values}'
	details := result.issues.map(json2.Any({
		'code':     json2.Any(it.code)
		'message':  json2.Any(it.message)
		'received': json2.Any(it.received)
	}))
	assert j.equal(json2.Any(details), row['issues'] or { panic('issues') }), '${row}: ${details}'
}

fn test_native_maybe_serialization_matches_valibot_values() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/maybe_json_differential.json')) or { panic(err) }) or { panic(err) }).as_array()
	for raw in rows {
		row := raw.as_map()
		if 'family' in row {
			maybe_json_pipeline_case(row)
			continue
		}
		mut calls := &MaybeJsonCalls{}
		match row['payload']!.str() {
			'string' { maybe_json_case(row, 'hello', mut calls) }
			'number' { maybe_json_case(row, 42.0, mut calls) }
			'date' { maybe_json_case(row, time.unix(0), mut calls) }
			'bigint' { maybe_json_case(row, big.integer_from_int(42), mut calls) }
			else { maybe_json_case(row, MaybeJsonHook{ calls: calls }, mut calls) }
		}
	}
}

fn maybe_json_placed[T](input types.Maybe[T], placement string, config v.StringifyJsonConfig) types.SafeParseResult[string] {
	if placement == 'array' {
		mut values := []types.Maybe[T]{}
		values << input
		values << input
		return maybe_json_result(values, config)
	}
	if placement == 'map' {
		mut values := map[string]types.Maybe[T]{}
		values['a'] = input
		values['b'] = input
		return maybe_json_result(values, config)
	}
	if placement == 'field' {
		return maybe_json_result(MaybeJsonFields[T]{ a: input, b: input }, config)
	}
	if placement == 'nested' { return maybe_json_result(types.some(input), config) }
	return maybe_json_result(input, config)
}

fn maybe_json_pipeline_case(row map[string]json2.Any) {
	reviver_mode := (row['reviver_mode'] or { panic('reviver') }).str()
	mode := (row['mode'] or { panic('mode') }).str()
	mut calls := &MaybeJsonCalls{}
	parse_config := v.ParseJsonConfig{
		reviver: fn [mut calls, reviver_mode] (key string, value json2.Any, context v.JsonReviverContext) !types.Maybe[json2.Any] {
			calls.values << 'V:' + key
			if reviver_mode == 'remove_root' && key == '' {
				return types.undefined_value[json2.Any]()
			}
			if reviver_mode == 'remove_a' && key == 'a' { return types.undefined_value[json2.Any]() }
			if reviver_mode == 'increment' && types.is_json_number(value) {
				return types.some(json2.Any(value.f64() + 1))
			}
			return types.some(value)
		}
	}
	mut config := v.StringifyJsonConfig{}
	if mode == 'recover' {
		config = v.StringifyJsonConfig{
			replacer_with_presence: fn [mut calls] (key string, value types.Maybe[json2.Any], context v.JsonReplacerContext) !types.Maybe[json2.Any] {
				state := if value.state in [.missing, .undefined] {
					'undefined'
				} else if value.state == .null {
					'null'
				} else {
					'value'
				}
				calls.values << 'R:' + key + ':' + state
				if state == 'undefined' { return types.some(json2.Any('recovered')) }
				return value
			}
		}
	}
	schema := v.pipe_to(v.pipe_to(v.string(), v.parse_json_with_config(parse_config)),
		v.stringify_json_value_with_config[types.Maybe[json2.Any]](config))
	result := v.safe_parse(schema, (row['input'] or { panic('input') }).str())
	assert result.success == (row['success'] or { panic('success') }).bool(), row.str()
	assert (result.output or { '' }) == (row['output'] or { panic('output') }).str(), row.str()
	assert calls.values == (row['calls'] or { panic('calls') }).as_array().map(it.str()), row.str()
	details := result.issues.map(json2.Any({
		'code':     json2.Any(it.code)
		'message':  json2.Any(it.message)
		'received': json2.Any(it.received)
	}))
	assert j.equal(json2.Any(details), row['issues'] or { panic('issues') }), '${row}: ${details}'
	if !result.success {
		raw := types.value_as[types.Maybe[json2.Any]](result.raw_output) or { panic(err) }
		assert raw.state == .undefined
	}
}
