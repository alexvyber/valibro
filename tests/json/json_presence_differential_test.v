module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct PresenceCalls {
mut:
	values []string
}

struct PresenceJsonValue {
	kind  string
	calls &PresenceCalls
}

pub fn (value PresenceJsonValue) to_json_value(key string) !types.Maybe[json2.Any] {
	mut calls := value.calls
	calls.values << 'H:' + key
	if value.kind == 'hook_error' { return error('Hook failed') }
	if value.kind == 'hook_undefined' { return types.undefined_value[json2.Any]() }
	if value.kind == 'hook_null' { return types.null_value[json2.Any]() }
	return types.some(json2.Any(42))
}

fn presence_json_result[T](item T, placement string, config v.StringifyJsonConfig) types.SafeParseResult[string] {
	if placement == 'array' {
		mut input := []T{}
		input << item
		input << item
		return v.safe_parse(v.pipe_to(v.unknown[[]T](),
			v.stringify_json_value_with_config[[]T](config)), input)
	}
	if placement == 'map' {
		mut input := map[string]T{}
		input['a'] = item
		input['b'] = item
		return v.safe_parse(v.pipe_to(v.unknown[map[string]T](),
			v.stringify_json_value_with_config[map[string]T](config)), input)
	}
	return v.safe_parse(v.pipe_to(v.unknown[T](), v.stringify_json_value_with_config[T](config)),
		item)
}

fn test_presence_aware_replacers_match_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/json_presence_differential.json')) or { panic(err) }) or { panic(err) }).as_array()
	for raw in rows {
		row := raw.as_map()
		kind := row['kind']!.str()
		placement := row['placement']!.str()
		mode := row['mode']!.str()
		mut calls := &PresenceCalls{}
		config := v.StringifyJsonConfig{
			replacer_with_presence: fn [mut calls, mode] (key string, value types.Maybe[json2.Any], context v.JsonReplacerContext) !types.Maybe[json2.Any] {
				state := if value.state in [.missing, .undefined] {
					'undefined'
				} else if value.state == .null {
					'null'
				} else {
					'value'
				}
				calls.values << 'R:' + key + ':' + state
				if state != 'value' {
					match mode {
						'recover' {
							return types.some(json2.Any('recovered'))
						}
						'null' {
							return types.null_value[json2.Any]()
						}
						'omit' {
							return types.undefined_value[json2.Any]()
						}
						'object' {
							return types.some(json2.Any({
								'recovered': json2.Any(true)
							}))
						}
						'error' {
							return error('Replacer failed')
						}
						else {}
					}
				}
				assert context.holder is map[string]json2.Any || context.holder is []json2.Any
				return value
			}
			// Verify precedence: neither lower-priority callback should execute.
			replacer_with_context: fn (key string, value json2.Any, context v.JsonReplacerContext) !types.Maybe[json2.Any] {
				return error('Unexpected contextual replacer')
			}
			replacer:              fn (key string, value json2.Any) !types.Maybe[json2.Any] {
				return error('Unexpected replacer')
			}
		}
		result := if kind == 'undefined' {
			presence_json_result(types.Undefined{}, placement, config)
		} else if kind == 'null' {
			presence_json_result(types.Null{}, placement, config)
		} else {
			presence_json_result(PresenceJsonValue{ kind: kind, calls: calls }, placement, config)
		}
		assert result.success == row['success']!.bool(), row.str()
		assert (result.output or { '' }) == row['output']!.str(), row.str()
		assert calls.values == row['calls']!.as_array().map(it.str()), '${row}: ${calls.values}'
		details := result.issues.map(json2.Any({
			'code':     json2.Any(it.code)
			'message':  json2.Any(it.message)
			'received': json2.Any(it.received)
		}))
		assert j.equal(json2.Any(details), row['issues']!), '${row}: ${details}'
	}
}
