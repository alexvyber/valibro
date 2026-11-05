module valibro_test

import valibro.internal.date as impl_date
import valibro.tests.support
import os
import math
import valibro.internal.number as impl_number
import math.big
import time
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct HookAuditCalls {
mut:
	values []string
}

struct PrimitiveAuditValue {
	kind  string
	calls &HookAuditCalls
}

// Operation labels normalize typed native calls for reference trace comparisons.
fn (value PrimitiveAuditValue) reference_call(label string) {
	mut calls := value.calls
	calls.values << label
}

pub fn (value PrimitiveAuditValue) to_number() !f64 {
	value.reference_call('number')
	return match value.kind {
		'text' {
			42.0
		}
		'invalid', 'date' {
			return error('Invalid number')
		}
		'number' {
			42.0
		}
		'fraction' {
			1.5
		}
		'nan' {
			math.nan()
		}
		'big' {
			impl_number.number_from_string('12345678901234567890')!
		}
		'undefined' {
			return error('NaN')
		}
		else {
			return types.TypeError{
				message: 'Unsupported reference conversion'
			}
		}
	}
}

pub fn (value PrimitiveAuditValue) to_bigint() !big.Integer {
	value.reference_call('number')
	if value.kind in ['text', 'number'] { return big.integer_from_int(42) }
	if value.kind == 'big' { return big.integer_from_string('12345678901234567890') }
	return types.TypeError{
		message: 'Unsupported reference integer'
	}
}

pub fn (value PrimitiveAuditValue) to_date() !time.Time {
	value.reference_call('default')
	if value.kind == 'date' { return impl_date.date_from_string('2020-01-02') }
	if value.kind == 'number' { return impl_date.date_from_milliseconds(42) }
	if value.kind == 'fraction' { return impl_date.date_from_milliseconds(1) }
	if value.kind in ['nan', 'undefined', 'invalid'] { return error('Invalid date') }
	return types.TypeError{
		message: 'Unsupported reference date'
	}
}

pub fn (value PrimitiveAuditValue) to_string() !string {
	value.reference_call('string')
	return match value.kind {
		'text', 'number' {
			'42'
		}
		'invalid' {
			'bad'
		}
		'date' {
			'2020-01-02'
		}
		'fraction' {
			'1.5'
		}
		'nan' {
			'NaN'
		}
		'big' {
			'12345678901234567890'
		}
		'null' {
			'null'
		}
		'undefined' {
			'undefined'
		}
		else {
			return types.TypeError{
				message: 'Unsupported reference string'
			}
		}
	}
}

pub fn (value PrimitiveAuditValue) to_boolean() !bool {
	return true
}

struct JsonAuditValue {
	kind  string
	calls &HookAuditCalls
}

pub fn (value JsonAuditValue) to_json_value(key string) !types.Maybe[json2.Any] {
	mut calls := value.calls
	calls.values << key
	if value.kind == 'error' { return error('JSON hook failed') }
	if value.kind == 'omit' { return types.undefined_value[json2.Any]() }
	if value.kind == 'null' { return types.null_value[json2.Any]() }
	return types.some(json2.Any({
		'key':   json2.Any(key)
		'value': json2.Any(42)
	}))
}

fn hook_audit_outcome[T](result types.SafeParseResult[T]) (string, []v.Issue) {
	if !result.success { return '', result.issues }
	value := hook_audit_value[T](result.output)
	$if T is time.Time {
		return value.unix_milli().str(), result.issues
	} $else {
		return support.reference_string(value), result.issues
	}
}

fn test_native_coercion_json_hooks_and_date_serialization_match_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/native_hook_audit_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	mut failures := 0
	for raw in rows {
		row := raw.as_map()
		family := row['family']!.str()
		if family == 'json_order' {
			audit_json_hook_order(row)
			continue
		}
		if family == 'date_json' {
			input := row['input']!
			output := if input is string { v.parse(v.pipe_to(v.unknown[time.Time](), v.stringify_json_value[time.Time]()), time.Time{}) or {
					panic(err)} } else { v.parse(v.pipe_to(v.unknown[time.Time](), v.stringify_json_value[time.Time]()), impl_date.date_from_milliseconds(input.i64())) or {
					panic(err)} }
			assert output == row['output']!.str(), row.str()
			continue
		}
		if family == 'class_json' {
			placement := row['placement']!.str()
			result := match row['kind']!.str() {
				'set' {
					class_audit_json(types.new_set([1, 2]), placement)
				}
				'map' {
					class_audit_json(types.entry_map([
						types.MapEntry[string, int]{ key: 'x', value: 1 },
					], fn (a string, b string) bool {
						return a == b
					}), placement)
				}
				'blob' {
					class_audit_json(types.Blob{ data: 'x'.bytes() }, placement)
				}
				'file' {
					class_audit_json(types.File{ data: 'x'.bytes(), name: 'x' }, placement)
				}
				'promise' {
					class_audit_json(types.new_future(chan types.SafeParseResult[string]{cap: 1}),
						placement)
				}
				'function' {
					class_audit_json(types.Function[int, int]{
						call: fn (value int) int {
							return value
						}
					}, placement)
				}
				else {
					class_audit_json(types.FallibleFunction[int, int]{
						call: fn (value int) !int {
							return value
						}
					}, placement)
				}
			}

			assert result.success == row['success']!.bool(), row.str()
			assert (result.output or { '' }) == row['output']!.str(), row.str()
			if !result.success { assert result.issues[0].received == row['received']!.str(), row.str()
			 }
			continue
		}
		mode := row['mode']!.str()
		kind := row['kind']!.str()
		mut calls := &HookAuditCalls{}
		messages := if mode == 'factory' {
			[types.ErrorMessage('Factory message')]
		} else {
			[]types.ErrorMessage{}
		}
		config := if mode == 'config' {
			v.Config{
				message: 'Config message'
			}
		} else {
			v.Config{}
		}
		mut output := ''
		mut issues := []v.Issue{}
		if family == 'primitive' {
			input := PrimitiveAuditValue{
				kind:  kind
				calls: calls
			}
			base := v.unknown[PrimitiveAuditValue]()
			out, errors := match row['action']!.str() {
				'toNumber' {
					hook_audit_outcome(v.safe_parse_with_config(v.pipe_to(base,
						v.to_number_from[PrimitiveAuditValue](...messages)), input, config))
				}
				'toBigint' {
					hook_audit_outcome(v.safe_parse_with_config(v.pipe_to(base,
						v.to_bigint_from[PrimitiveAuditValue](...messages)), input, config))
				}
				'toString' {
					hook_audit_outcome(v.safe_parse_with_config(v.pipe_to(base,
						v.to_string_from[PrimitiveAuditValue](...messages)), input, config))
				}
				'toDate' {
					hook_audit_outcome(v.safe_parse_with_config(v.pipe_to(base,
						v.to_date_from[PrimitiveAuditValue](...messages)), input, config))
				}
				else {
					hook_audit_outcome(v.safe_parse_with_config(v.pipe_to(base,
						v.to_boolean_from[PrimitiveAuditValue]()), input, config))
				}
			}

			output = out
			issues = errors.clone()
		} else {
			item := JsonAuditValue{
				kind:  kind
				calls: calls
			}
			out, errors := match row['placement']!.str() {
				'array' {
					hook_audit_outcome(v.safe_parse_with_config(v.pipe_to(v.unknown[[]JsonAuditValue](),
						v.stringify_json_value[[]JsonAuditValue](...messages)), [item, item],
						config))
				}
				'map' {
					hook_audit_outcome(v.safe_parse_with_config(v.pipe_to(v.unknown[map[string]JsonAuditValue](),
						v.stringify_json_value[map[string]JsonAuditValue](...messages)), {
						'a': item
						'b': item
					}, config))
				}
				else {
					hook_audit_outcome(v.safe_parse_with_config(v.pipe_to(v.unknown[JsonAuditValue](),
						v.stringify_json_value[JsonAuditValue](...messages)), item, config))
				}
			}

			output = out
			issues = errors.clone()
		}
		mut details := []json2.Any{}
		for issue in issues {
			details << json2.Any({
				'code':     json2.Any(issue.code)
				'expected': json2.Any(issue.expected)
				'received': json2.Any(issue.received)
				'message':  json2.Any(issue.message)
			})
		}
		if output != row['output']!.str() || (issues.len == 0) != row['success']!.bool()
			|| !j.equal(json2.Any(details), row['issues']!)
			|| calls.values != row['calls']!.as_array().map(it.str()) {
			failures++
			if failures <= 7 { eprintln('${row}: ${output}, ${details}, ${calls.values}') }
		}
	}
	assert failures == 0, '${failures} native hook mismatches'
}

fn hook_audit_value[T](value ?T) T {
	return value or { panic('output') }
}

fn class_audit_json[T](input T, placement string) types.SafeParseResult[string] {
	if placement == 'array' {
		mut values := []T{}
		values << input
		values << input
		return v.safe_parse(v.pipe_to(v.unknown[[]T](), v.stringify_json_value[[]T]()), values)
	}
	if placement == 'map' {
		mut values := map[string]T{}
		values['a'] = input
		values['b'] = input
		return v.safe_parse(v.pipe_to(v.unknown[map[string]T](),
			v.stringify_json_value[map[string]T]()), values)
	}
	return v.safe_parse(v.pipe_to(v.unknown[T](), v.stringify_json_value[T]()), input)
}

struct OrderedJsonAuditValue {
	calls &HookAuditCalls
}

pub fn (value OrderedJsonAuditValue) to_json_value(key string) !types.Maybe[json2.Any] {
	mut calls := value.calls
	calls.values << 'H:' + key
	return types.some(json2.Any(42))
}

fn audit_json_hook_order(row map[string]json2.Any) {
	mut calls := &HookAuditCalls{}
	mode := row['mode'] or { panic('mode') }
	name := mode.str()
	item := OrderedJsonAuditValue{
		calls: calls
	}
	mut config := v.StringifyJsonConfig{
		replacer: fn [mut calls, name] (key string, value json2.Any) !types.Maybe[json2.Any] {
			calls.values << 'R:' + key
			if key == '' && name == 'omit_root' { return types.undefined_value[json2.Any]() }
			if key == '' && name == 'replace_root' { return types.some(json2.Any({
					'done': json2.Any(true)
				})) }
			first := key == 'a' || key == '0'
			if first && name == 'omit_first' { return types.undefined_value[json2.Any]() }
			if first && name == 'error_first' { return error('Replacer stopped') }
			return types.some(value)
		}
	}
	if name == 'whitelist' { config = v.StringifyJsonConfig{
			property_list: ['b']
		} }
	if name == 'reverse_whitelist' { config = v.StringifyJsonConfig{
			property_list: ['b', 'a']
		} }
	placement := row['placement'] or { panic('placement') }
	result := if placement.str() == 'array' {
		v.safe_parse(v.pipe_to(v.unknown[[]OrderedJsonAuditValue](),
			v.stringify_json_value_with_config[[]OrderedJsonAuditValue](config)), [
			item,
			item,
		])
	} else {
		v.safe_parse(v.pipe_to(v.unknown[map[string]OrderedJsonAuditValue](),
			v.stringify_json_value_with_config[map[string]OrderedJsonAuditValue](config)), {
			'a': item
			'b': item
		})
	}
	expected_success := row['success'] or { panic('success') }
	expected_output := row['output'] or { panic('output') }
	expected_calls := row['calls'] or { panic('calls') }
	assert result.success == expected_success.bool(), row.str()
	assert (result.output or { '' }) == expected_output.str(), row.str()
	assert calls.values == expected_calls.as_array().map(it.str()), '${row}: ${calls.values}'
}
