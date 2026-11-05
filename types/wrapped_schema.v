module types

// Private, immutable type erasure retains a differently typed wrapped schema.
// The pointer owns a GC-managed heap allocation; signature checks precede casts.
pub struct WrappedSchema {
	input_type  string
	output_type string
	data        voidptr = unsafe { nil }
}

pub fn wrap_schema[I, O](schema Schema[I, O]) WrappedSchema {
	boxed := &Schema[I, O]{
		...schema
	}
	return WrappedSchema{
		input_type:  typeof[I]().name
		output_type: typeof[O]().name
		data:        voidptr(boxed)
	}
}

pub fn unwrap_schema[I, O, P, Q](schema Schema[I, O]) !Schema[P, Q] {
	if wrapped := schema.wrapped_schema {
		if wrapped.input_type != typeof[P]().name || wrapped.output_type != typeof[Q]().name {
			return error('Wrapped schema has a different native input/output signature')
		}
		if wrapped.data == unsafe { nil } { return error('Schema has no wrapped schema') }
		boxed := unsafe { &Schema[P, Q](wrapped.data) }
		return *boxed
	}
	return error('Schema has no wrapped schema')
}
