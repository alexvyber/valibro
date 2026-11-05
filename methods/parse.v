module methods

import valibro.types

// Parse returns a value or a native error; validation errors retain all issues.
pub fn parse[I, O](schema types.Schema[I, O], input I, config types.Config) !O {
	dataset := inspect[I, O](schema, input, config)!
	if dataset.issues.len > 0 { return types.ValidationError{
			issues: dataset.issues
		} }
	return dataset.value
}

// Inspect returns validation issues and partial output; execution errors propagate.
pub fn inspect[I, O](schema types.Schema[I, O], input I, config types.Config) !types.Dataset[O] {
	dataset := run_schema[I, O](schema, input, config)
	if exception := dataset.exception { return exception }
	return dataset
}

pub fn is_valid[I, O](schema types.Schema[I, O], input I, config types.Config) !bool {
	return inspect[I, O](schema, input, config)!.issues.len == 0
}
