module methods

import valibro.types

pub fn parse[I, O](schema types.Schema[I, O], input I) !O {
	return parse_with_config[I, O](schema, input, types.Config{})
}

pub fn parse_with_config[I, O](schema types.Schema[I, O], input I, config types.Config) !O {
	dataset := run_schema[I, O](schema, input, config)
	if exception := dataset.exception { return exception }
	if dataset.issues.len > 0 {
		return types.ValidationError{
			issues: dataset.issues
		}
	}
	return dataset.value
}
