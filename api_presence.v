module valibro

import valibro.methods
import valibro.types

pub fn fallback[I, O](schema types.Schema[I, O], value O) types.Schema[I, O] {
	return methods.fallback(schema, value)
}

pub fn fallback_fn[I, O](schema types.Schema[I, O], getter fn (I, []types.Issue) O) types.Schema[I, O] {
	return methods.fallback_fn(schema, getter)
}
