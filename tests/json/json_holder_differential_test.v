module valibro_test

import valibro.tests.support
import os
import x.json2
import valibro as v
import valibro.types
import valibro.jsoncodec
import valibro.json as j

struct HolderCalls {
mut:
	values []json2.Any
}

fn holder_operation(mut calls HolderCalls, key string, value json2.Any, holder json2.Any, source ?string, mode string) types.Maybe[json2.Any] {
	source_value := if text := source { json2.Any(text) } else { json2.Any(json2.Null{}) }
	calls.values << json2.Any({
		'key':    json2.Any(key)
		'value':  value
		'holder': holder
		'source': source_value
	})
	if mode == 'drop' && key == 'drop' { return types.undefined_value[json2.Any]() }
	if mode == 'siblings' && (value is int || value is i64 || value is f64 || value is u64) {
		if key == 'value' {
			factor := if holder is map[string]json2.Any {
				holder['factor'] or { json2.Any(1) }
			} else {
				json2.Any(1)
			}
			return types.some(json2.Any(value.f64() * factor.f64()))
		}
		return types.some(json2.Any(value.f64() + 1))
	}
	return types.some(value)
}

fn test_json_holder_snapshots_and_sibling_transformations_match_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/json/json_holder_differential.json')) or { panic(err) }) or { panic(err) }).as_array()
	for raw in rows {
		row := raw.as_map()
		text := row['text']!.str()
		mode := row['mode']!.str()
		mut calls := &HolderCalls{}
		if row['action']!.str() == 'parse' {
			result := types.run_transformation(v.parse_json_with_config(v.ParseJsonConfig{
				reviver: fn [mut calls, mode] (key string, value json2.Any, context jsoncodec.ReviverContext) !types.Maybe[json2.Any] {
					return holder_operation(mut calls, key, value, context.holder, context.source, mode)
				}
			}), text)
			assert result.issues.len == 0
			assert result.value.state == .value
			assert j.equal(result.value.value, row['output']!), row.str()
		} else {
			input := json2.decode[json2.Any](text) or { panic(err) }
			callback := fn [mut calls, mode] (key string, value json2.Any, context jsoncodec.ReplacerContext) !types.Maybe[json2.Any] {
				return holder_operation(mut calls, key, value, context.holder, none, mode)
			}
			result := types.run_transformation(v.stringify_json_with_config(v.StringifyJsonConfig{
				replacer_with_context: jsoncodec.ContextReplacer(callback)
			}), input)
			assert result.issues.len == 0
			assert support.equal_json_text(result.value, row['output']!.str()), row.str()
		}
		assert j.equal(json2.Any(calls.values), row['calls']!), '${row}: ${calls.values}'
	}
}
