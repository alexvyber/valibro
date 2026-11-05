module methods

import valibro.types

pub fn safe_parse[I, O](schema types.Schema[I, O], input I) types.SafeParseResult[O] {
	return safe_parse_with_config[I, O](schema, input, types.Config{})
}

pub fn safe_parse_with_config[I, O](schema types.Schema[I, O], input I, config types.Config) types.SafeParseResult[O] {
	return safe_parse_checked[I, O](schema, input, config) or { panic(err) }
}

pub fn safe_parse_checked[I, O](schema types.Schema[I, O], input I, configs ...types.Config) !types.SafeParseResult[O] {
	assert configs.len <= 1, 'Expected at most one config'
	settings := if configs.len == 1 { configs[0] } else { types.Config{} }
	dataset := run_schema[I, O](schema, input, settings)
	if exception := dataset.exception { return exception }
	raw_output := dataset.raw_value or { types.value_of[O](dataset.value) }
	if dataset.issues.len > 0 { return types.SafeParseResult[O]{
			raw_output: raw_output
			typed:      dataset.typed
			issues:     dataset.issues
		} }
	return types.SafeParseResult[O]{
		raw_output: raw_output
		success:    true
		typed:      dataset.typed
		output:     dataset.value
	}
}
