module json

import valibro.internal.diagnostics
import x.json2
import valibro.types

pub fn object(entries map[string]Schema, messages ...types.ErrorMessage) Schema {
	return object_mode(entries, 'object', []Schema{}, ...messages)
}

pub fn strict_object(entries map[string]Schema, messages ...types.ErrorMessage) Schema {
	return object_mode(entries, 'strict_object', []Schema{}, ...messages)
}

pub fn loose_object(entries map[string]Schema, messages ...types.ErrorMessage) Schema {
	return object_mode(entries, 'loose_object', []Schema{}, ...messages)
}

pub fn object_with_rest(entries map[string]Schema, rest Schema, messages ...types.ErrorMessage) Schema {
	return object_mode(entries, 'object_with_rest', [rest], ...messages)
}

fn object_mode(entries map[string]Schema, mode string, rest []Schema, messages ...types.ErrorMessage) Schema {
	assert messages.len <= 1, 'Expected at most one message'
	text := if messages.len > 0 { messages[0] } else { types.ErrorMessage(types.DefaultMessage{}) }
	fields := entries.clone()
	return Schema{
		message:         text
		shape_rebuilder: ShapeRebuilder(fn [mode, rest, text] (fields map[string]Schema) Schema {
			return object_mode(fields, mode, rest, text)
		})
		type_name:       mode
		expects:         'Object'
		mode:            mode
		entries:         fields
		items:           rest
		run:             fn [fields, mode, rest, text] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			data := object_data(input) or { return type_issue(mode, input, 'object', text) }
			mut output := map[string]json2.Any{}
			mut issues := []types.Issue{}
			mut typed := true
			for key in fields.keys() {
				schema := fields[key]
				mut value := json2.Any(json2.Null{})
				if found := data[key] {
					value = found
				} else {
					if schema.optional && schema.has_default_provider {
						value = schema.default_provider(config)
					} else if schema.optional && schema.default_value != none {
						value = schema.default_value or { json2.Null{} }
					} else if fallback := schema.fallback_value {
						output[key] = fallback
						continue
					} else if schema.optional {
						continue
					} else {
						issues << types.Issue{
							...types.schema_type_issue(mode, text, diagnostics.issue_value(key),
								'undefined', 'key')
							path: [types.PathSegment(key)]
						}
						typed = false
						if config.abort_early { break
						 }
						continue
					}
				}
				result := run_json(schema, value, config)
				if exception := result.exception { return types.Dataset[json2.Any]{
						typed:     false
						exception: exception
					} }
				typed = typed && result.typed
				issues << diagnostics.prepend_path(result.issues, key)
				if config.abort_early && issues.len > 0 {
					typed = false
					break
				}
				output[key] = result.value
			}
			if !(config.abort_early && issues.len > 0) {
				for key in data.keys() {
					value := data[key] or { continue }
					if key in fields { continue
					 }
					if mode == 'strict_object' {
						typed = false
						issues << types.Issue{
							...types.schema_type_issue(mode, text, 'never',
								diagnostics.issue_value(key), 'key')
							path: [types.PathSegment(key)]
						}
						// Match Valibot's one issue for the first unknown key.
						break
					} else if mode == 'loose_object' {
						output[key] = value
					} else if mode == 'object_with_rest' {
						result := run_json(rest[0], value, config)
						if exception := result.exception { return types.Dataset[json2.Any]{
								typed:     false
								exception: exception
							} }
						typed = typed && result.typed
						issues << diagnostics.prepend_path(result.issues, key)
						if config.abort_early && issues.len > 0 {
							typed = false
							break
						}
						output[key] = result.value
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

pub fn pick(schema Schema, keys []string) Schema {
	mut fields := map[string]Schema{}
	for key in keys {
		fields[key] = schema.entries[key] or { panic('Unknown object key: ' + key) }
	}
	return reshape_object(schema, fields)
}

pub fn omit(schema Schema, keys []string) Schema {
	mut fields := map[string]Schema{}
	for key, value in schema.entries {
		if key !in keys { fields[key] = value }
	}
	return reshape_object(schema, fields)
}

pub fn partial(schema Schema, keys ...[]string) Schema {
	assert keys.len <= 1, 'Expected at most one key list'
	mut fields := map[string]Schema{}
	for key, value in schema.entries {
		fields[key] = if keys.len == 0 || key in keys[0] { optional(value) } else { value }
	}
	return reshape_object(schema, fields)
}

pub fn required(schema Schema, keys ...[]string) Schema {
	assert keys.len <= 1, 'Expected at most one key list'
	mut fields := map[string]Schema{}
	for key, value in schema.entries {
		fields[key] = if keys.len == 0 || key in keys[0] { non_optional(value) } else { value }
	}
	return reshape_object(schema, fields)
}

pub fn keyof(schema Schema) Schema {
	mut keys := []json2.Any{}
	for key in schema.entries.keys() {
		keys << json2.Any(key)
	}
	return picklist(keys)
}

pub fn entries_from_list(keys []string, schema Schema) map[string]Schema {
	mut entries := map[string]Schema{}
	for key in keys {
		entries[key] = schema
	}
	return entries
}

pub fn entries_from_objects(objects ...map[string]Schema) map[string]Schema {
	mut entries := map[string]Schema{}
	for object in objects {
		for key, value in object {
			entries[key] = value
		}
	}
	return entries
}

// Shape operations retain schema annotations and factory error messages.
fn reshape_object(schema Schema, fields map[string]Schema) Schema {
	mut runner := schema.run
	if rebuild := schema.shape_rebuilder { runner = rebuild(fields).run }
	return Schema{
		...schema
		entries: fields
		run:     runner
	}
}

pub fn required_with_message(schema Schema, message types.ErrorMessage, keys ...[]string) Schema {
	assert keys.len <= 1, 'Expected at most one key list'
	mut fields := map[string]Schema{}
	for key, value in schema.entries {
		fields[key] = if keys.len == 0 || key in keys[0] {
			non_optional(value, message)
		} else {
			value
		}
	}
	return reshape_object(schema, fields)
}
