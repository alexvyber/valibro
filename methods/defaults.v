module methods

import valibro.types

pub fn get_default[I, O](schema types.Schema[I, O], configs ...types.Config) ?I {
	return get_default_with_context(schema, none, ...configs)
}

pub fn get_default_with_context[I, O](schema types.Schema[I, O], dataset ?types.Dataset[I], configs ...types.Config) ?I {
	assert configs.len <= 1, 'Expected at most one config'
	config := if configs.len == 1 { configs[0] } else { types.Config{} }
	if schema.default_context_provider.available {
		return schema.default_context_provider.get(dataset, config)
	}
	if schema.default_provider.available { return schema.default_provider.get(config) }
	return schema.default_value
}

pub fn get_fallback[I, O](schema types.Schema[I, O], configs ...types.Config) ?O {
	return get_fallback_with_context(schema, none, ...configs)
}

pub fn get_fallback_with_context[I, O](schema types.Schema[I, O], dataset ?types.Dataset[O], configs ...types.Config) ?O {
	assert configs.len <= 1, 'Expected at most one config'
	config := if configs.len == 1 { configs[0] } else { types.Config{} }
	if schema.fallback_provider.available { return schema.fallback_provider.get(dataset, config) }
	return schema.fallback_value
}

pub fn unwrap[I, O](schema types.Schema[types.Maybe[I], types.Maybe[O]]) types.Schema[I, O] {
	return types.unwrap_schema[types.Maybe[I], types.Maybe[O], I, O](schema) or { panic(err) }
}

pub fn unwrap_as[I, O, P, Q](schema types.Schema[I, O]) !types.Schema[P, Q] {
	return types.unwrap_schema[I, O, P, Q](schema)
}

pub fn entries_from_list[T](keys []string, value T) map[string]T {
	mut result := map[string]T{}
	for key in keys {
		result[key] = value
	}
	return result
}

pub fn entries_from_objects[T](objects ...map[string]T) map[string]T {
	mut result := map[string]T{}
	for object in objects {
		for key, value in object {
			result[key] = value
		}
	}
	return result
}
