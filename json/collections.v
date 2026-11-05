module json

import valibro.internal.diagnostics
import valibro.internal.number as numbers
import x.json2
import valibro.types

pub fn array(item Schema) Schema {
	return Schema{
		type_name: 'array'
		expects:   'Array'
		items:     [item]
		run:       fn [item] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			if input !is []json2.Any { return type_issue('array', input, 'array') }
			data := input as []json2.Any
			mut output := []json2.Any{}
			mut issues := []types.Issue{}
			mut typed := true
			for i, value in data {
				result := run_json(item, value, config)
				if exception := result.exception { return types.Dataset[json2.Any]{
						typed:     false
						exception: exception
					} }
				typed = typed && result.typed
				issues << diagnostics.prepend_path(result.issues, i)
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				output << result.value
			}
			return types.Dataset[json2.Any]{
				typed:  typed
				value:  json2.Any(output)
				issues: issues
			}
		}
	}
}

pub fn tuple(items []Schema) Schema {
	return tuple_mode(items, 'tuple', []Schema{})
}

pub fn strict_tuple(items []Schema) Schema {
	return tuple_mode(items, 'strict_tuple', []Schema{})
}

pub fn loose_tuple(items []Schema) Schema {
	return tuple_mode(items, 'loose_tuple', []Schema{})
}

pub fn tuple_with_rest(items []Schema, rest Schema) Schema {
	return tuple_mode(items, 'tuple_with_rest', [rest])
}

fn tuple_mode(items []Schema, mode string, rest []Schema) Schema {
	children := items.clone()
	return Schema{
		type_name: mode
		expects:   'Array'
		mode:      mode
		items:     children
		run:       fn [children, mode, rest] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			if input !is []json2.Any { return type_issue(mode, input, 'tuple') }
			data := input as []json2.Any
			mut output := []json2.Any{}
			mut issues := []types.Issue{}
			mut typed := true
			for i, schema in children {
				result := if i >= data.len {
					missing_result(schema, config)
				} else {
					run_json(schema, data[i], config)
				}
				if exception := result.exception { return types.Dataset[json2.Any]{
						typed:     false
						exception: exception
					} }
				typed = typed && result.typed
				issues << diagnostics.prepend_path(result.issues, i)
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				output << result.value
			}
			if !(config.abort_early && issues.len > 0) && data.len > children.len {
				if mode == 'strict_tuple' {
					typed = false
					issues << types.Issue{
						...types.schema_type_issue(mode, types.DefaultMessage{}, 'never',
							diagnostics.issue_value(data[children.len]), 'type')
						path:       [types.PathSegment(children.len)]
						path_types: ['array']
					}
				} else if mode == 'loose_tuple' {
					for value in data[children.len..] {
						output << value
					}
				} else if mode == 'tuple_with_rest' {
					for i := children.len; i < data.len; i++ {
						result := run_json(rest[0], data[i], config)
						if exception := result.exception { return types.Dataset[json2.Any]{
								typed:     false
								exception: exception
							} }
						typed = typed && result.typed
						issues << diagnostics.prepend_path(result.issues, i)
						if config.abort_early && issues.len > 0 {
							typed = false
							break
						}
						output << result.value
					}
				}
			}
			return types.Dataset[json2.Any]{
				typed:  typed
				value:  json2.Any(output)
				issues: issues
			}
		}
	}
}

pub fn record(key_schema Schema, value_schema Schema) Schema {
	return Schema{
		type_name: 'record'
		expects:   'Object'
		items:     [key_schema, value_schema]
		run:       fn [key_schema, value_schema] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			data := object_data(input) or { return type_issue('record', input, 'record') }
			mut output := map[string]json2.Any{}
			mut issues := []types.Issue{}
			mut typed := true
			for key in data.keys() {
				value := data[key] or { continue }
				k := run_json(key_schema, json2.Any(key), config)
				if exception := k.exception { return types.Dataset[json2.Any]{
						typed:     false
						exception: exception
					} }
				typed = typed && k.typed
				issues << diagnostics.prepend_path(k.issues, key)
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				v := run_json(value_schema, value, config)
				if exception := v.exception { return types.Dataset[json2.Any]{
						typed:     false
						exception: exception
					} }
				typed = typed && v.typed
				issues << diagnostics.prepend_path(v.issues, key)

				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				if k.typed {
					match k.value {
						string { output[k.value as string] = v.value }
						f64 { output[numbers.native_number_string(k.value as f64)] = v.value }
						f32 { output[numbers.native_number_string(f64(k.value as f32))] = v.value }
						int { output[(k.value as int).str()] = v.value }
						i64 { output[(k.value as i64).str()] = v.value }
						u64 { output[(k.value as u64).str()] = v.value }
						else {}
					}
				}
			}
			return types.Dataset[json2.Any]{
				typed:  typed
				value:  json2.Any(output)
				issues: issues
			}
		}
	}
}

fn missing_result(schema Schema, config types.Config) types.Dataset[json2.Any] {
	if schema.fallback_wrapped.len > 0 {
		result := missing_result(schema.fallback_wrapped[0], config)
		if result.exception != none { return result }
		if result.issues.len > 0 { return types.Dataset[json2.Any]{
				value: schema.fallback_value or { json2.Null{} }
			} }
		return result
	}
	if schema.type_name == 'optional' {
		if value := schema.default_value { return run_json(schema, value, config) }
		return types.Dataset[json2.Any]{
			value: json2.Null{}
		}
	}
	if schema.type_name in ['union', 'intersect'] {
		mut items := []Schema{}
		for child in schema.items {
			items << Schema{
				type_name: child.type_name
				expects:   child.expects
				message:   child.message
				run:       fn [child] (ignored json2.Any, settings types.Config) types.Dataset[json2.Any] {
					return missing_result(child, settings)
				}
			}
		}
		combined := if schema.type_name == 'union' { union_schema(items) } else { intersect(items) }
		result := run_json(combined, json2.Null{}, config)
		if result.issues.len == 1 && (result.issues[0].code == 'union'
			|| (schema.type_name == 'intersect' && schema.items.len == 0)) {
			issue := result.issues[0]
			replacement := types.schema_type_issue(issue.code, types.DefaultMessage{},
				schema.expects, 'missing', 'type')
			return types.Dataset[json2.Any]{
				...result
				issues: [
					types.Issue{
						...replacement
						path:   issue.path
						issues: issue.issues
					},
				]
			}
		}
		return result
	}
	if schema.type_name in ['unknown', 'any'] { return types.Dataset[json2.Any]{
			value: json2.Null{}
		} }
	if value := schema.fallback_value { return types.Dataset[json2.Any]{
			value: value
		} }
	if schema.wrapped.len == 1 { return missing_result(schema.wrapped[0], config) }
	return missing_type_issue(schema)
}

fn missing_type_issue(schema Schema) types.Dataset[json2.Any] {
	return types.Dataset[json2.Any]{
		typed:  false
		value:  json2.Null{}
		issues: [
			types.schema_type_issue(schema.type_name, schema.message or { types.DefaultMessage{} },
				schema.expects, 'missing', 'type'),
		]
	}
}
