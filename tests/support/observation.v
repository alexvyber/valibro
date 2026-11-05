module support

import valibro as v
import valibro.json as j
import valibro.types
import x.json2

// Test-only records retain the observation shape of checked-in reference data.
// The library exposes native ! results and Dataset inspection, not this struct.
pub struct Observation[T] {
pub:
	success    bool
	typed      bool
	output     ?T
	raw_output types.NativeValue
	exception  ?IError
	issues     []types.Issue
}

pub fn observe[I, O](schema types.Schema[I, O], input I, config types.Config) Observation[O] {
	dataset := v.inspect[I, O](schema, input, config) or { panic(err) }
	raw := dataset.raw_value or { types.value_of[O](dataset.value) }
	if !dataset.typed || dataset.issues.len > 0 {
		return Observation[O]{
			typed:      dataset.typed
			raw_output: raw
			issues:     dataset.issues
		}
	}
	return Observation[O]{
		success:    true
		typed:      dataset.typed
		output:     dataset.value
		raw_output: raw
	}
}

pub fn observe_json(schema j.Schema, input json2.Any, config types.Config) Observation[json2.Any] {
	return observe[json2.Any, json2.Any](j.native(schema), input, config)
}

pub fn accepts[I, O](schema types.Schema[I, O], input I, config types.Config) bool {
	return v.is_valid[I, O](schema, input, config) or { panic(err) }
}

pub fn accepts_json(schema j.Schema, input json2.Any, config types.Config) bool {
	return j.is_valid(schema, input, config) or { panic(err) }
}
