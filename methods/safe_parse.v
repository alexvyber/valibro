module methods

import valibro.types

pub fn safe_parse[I, O](schema types.Schema[I, O], input I) types.SafeParseResult[O] {
	return safe_parse_with_config[I, O](schema, input, types.Config{})
}

pub fn safe_parse_with_config[I, O](schema types.Schema[I, O], input I, config types.Config) types.SafeParseResult[O] {
	dataset := run_schema[I, O](schema, input, config)
	if dataset.issues.len > 0 {
		return types.SafeParseResult[O]{
			output: none
			issues: dataset.issues
		}
	}
	return types.SafeParseResult[O]{
		success: true
		output:  dataset.value
	}
}
