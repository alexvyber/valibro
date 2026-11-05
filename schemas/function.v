module schemas

import valibro.types

pub fn function_schema[I, O]() types.Schema[types.Function[I, O], types.Function[I, O]] {
	return native_schema[types.Function[I, O]]('function', [])
}
