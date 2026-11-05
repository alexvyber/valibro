module json

import x.json2
import valibro.types

pub fn optional(schema Schema, defaults ...json2.Any) Schema {
	return presence(schema, 'optional', defaults)
}

pub fn exact_optional(schema Schema, defaults ...json2.Any) Schema {
	return presence(schema, 'exact_optional', defaults)
}

pub fn nullable(schema Schema, defaults ...json2.Any) Schema {
	return presence(schema, 'nullable', defaults)
}

pub fn nullish(schema Schema, defaults ...json2.Any) Schema {
	return presence(schema, 'nullish', defaults)
}

fn presence(schema Schema, kind string, defaults []json2.Any) Schema {
	assert defaults.len <= 1, 'Expected at most one default'
	mut default_value := ?json2.Any(none)
	if defaults.len > 0 { default_value = defaults[0] }
	return Schema{
		type_name:     kind
		expects:       presence_expects(schema.expects, kind)
		wrapped:       [schema]
		optional:      kind != 'nullable'
		default_value: default_value
		run:           fn [schema, kind, default_value] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			if input is json2.Null && kind in ['nullable', 'nullish'] {
				if default := default_value {
					if default is json2.Null { return types.Dataset[json2.Any]{
							value: default
						} }
					return run_json(schema, default, config)
				}
				return types.Dataset[json2.Any]{
					value: input
				}
			}
			return run_json(schema, input, config)
		}
	}
}

pub fn non_optional(schema Schema, messages ...types.ErrorMessage) Schema {
	return Schema{
		message:   if messages.len > 0 {
			messages[0]
		} else {
			types.ErrorMessage(types.DefaultMessage{})
		}
		type_name: 'non_optional'
		expects:   '!undefined'
		wrapped:   [schema]
		run:       schema.run
	}
}

pub fn non_nullable(schema Schema, messages ...types.ErrorMessage) Schema {
	return non_presence(schema, 'non_nullable', messages)
}

pub fn non_nullish(schema Schema, messages ...types.ErrorMessage) Schema {
	return non_presence(schema, 'non_nullish', messages)
}

fn non_presence(schema Schema, kind string, messages []types.ErrorMessage) Schema {
	text := if messages.len > 0 { messages[0] } else { types.ErrorMessage(types.DefaultMessage{}) }
	return Schema{
		message:   text
		type_name: kind
		expects:   if kind == 'non_nullable' { '!null' } else { '(!null & !undefined)' }
		wrapped:   [schema]
		run:       fn [schema, kind, text] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			if input is json2.Null { return type_issue(kind, input, if kind == 'non_nullable' {
					'!null'
				} else {
					'(!null & !undefined)'
				}, text)
			 }
			result := run_json(schema, input, config)
			if result.exception != none { return result }
			if result.value is json2.Null {
				mut issues := result.issues.clone()
				issues << type_issue(kind, result.value, if kind == 'non_nullable' {
					'!null'
				} else {
					'(!null & !undefined)'
				}, text).issues
				return types.Dataset[json2.Any]{
					typed:  false
					value:  result.value
					issues: issues
				}
			}
			return result
		}
	}
}

pub fn unwrap(schema Schema) Schema {
	assert schema.wrapped.len == 1, 'Schema has no wrapped schema'
	return schema.wrapped[0]
}

pub fn get_default(schema Schema, configs ...types.Config) ?json2.Any {
	assert configs.len <= 1, 'Expected at most one config'
	config := if configs.len == 1 { configs[0] } else { types.Config{} }
	if schema.has_default_provider { return schema.default_provider(config) }
	return schema.default_value
}

pub fn get_fallback(schema Schema) ?json2.Any {
	return schema.fallback_value
}

pub fn get_defaults(schema Schema, configs ...types.Config) json2.Any {
	if value := get_default(schema, ...configs) { return value }
	if schema.mode in ['object', 'strict_object', 'loose_object', 'object_with_rest']
		|| schema.entries.len > 0 {
		mut output := map[string]json2.Any{}
		for key, child in schema.entries {
			output[key] = get_defaults(child, ...configs)
		}
		return json2.Any(output)
	}
	if schema.type_name in ['tuple', 'strict_tuple', 'loose_tuple', 'tuple_with_rest'] {
		mut output := []json2.Any{}
		for child in schema.items {
			output << get_defaults(child, ...configs)
		}
		return json2.Any(output)
	}
	return json2.Null{}
}

pub fn fallback(schema Schema, value json2.Any) Schema {
	return Schema{
		...schema
		shape_rebuilder:  none
		fallback_value:   value
		fallback_wrapped: [schema]
		run:              fn [schema, value] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			result := run_json(schema, input, config)
			if exception := result.exception { return types.Dataset[json2.Any]{
					typed:     false
					exception: exception
				} }
			if result.typed && result.issues.len == 0 { return result }
			return types.Dataset[json2.Any]{
				value: value
			}
		}
	}
}

pub fn get_fallbacks(schema Schema) json2.Any {
	if schema.mode in ['object', 'strict_object', 'loose_object', 'object_with_rest']
		|| schema.entries.len > 0 {
		mut output := map[string]json2.Any{}
		for key, child in schema.entries {
			output[key] = get_fallbacks(child)
		}
		return json2.Any(output)
	}
	if schema.type_name in ['tuple', 'strict_tuple', 'loose_tuple', 'tuple_with_rest'] {
		mut output := []json2.Any{}
		for child in schema.items {
			output << get_fallbacks(child)
		}
		return json2.Any(output)
	}
	if value := schema.fallback_value { return value }
	return json2.Null{}
}

pub fn optional_with_default(schema Schema, getter fn (types.Config) json2.Any) Schema {
	return presence_with_default(schema, 'optional', getter)
}

pub fn nullable_with_default(schema Schema, getter fn (types.Config) json2.Any) Schema {
	return presence_with_default(schema, 'nullable', getter)
}

pub fn nullish_with_default(schema Schema, getter fn (types.Config) json2.Any) Schema {
	return presence_with_default(schema, 'nullish', getter)
}

pub fn exact_optional_with_default(schema Schema, getter fn (types.Config) json2.Any) Schema {
	return presence_with_default(schema, 'exact_optional', getter)
}

fn presence_with_default(schema Schema, kind string, getter fn (types.Config) json2.Any) Schema {
	base := presence(schema, kind, []json2.Any{})
	return Schema{
		...base
		has_default_provider: true
		default_provider:     getter
		run:                  fn [schema, base, kind, getter] (input json2.Any, config types.Config) types.Dataset[json2.Any] {
			if input is json2.Null && kind in ['nullable', 'nullish'] {
				value := getter(config)
				if value is json2.Null { return types.Dataset[json2.Any]{
						value: value
					} }
				return run_json(schema, value, config)
			}
			return run_json(base, input, config)
		}
	}
}

fn presence_expects(wrapped string, kind string) string {
	return match kind {
		'optional' { '(' + wrapped + ' | undefined)' }
		'nullable' { '(' + wrapped + ' | null)' }
		'nullish' { '(' + wrapped + ' | null | undefined)' }
		else { wrapped }
	}
}
