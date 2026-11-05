module schemas

import valibro.types

pub fn blob() types.Schema[types.Blob, types.Blob] {
	return native_schema[types.Blob]('blob', [])
}

pub fn file() types.Schema[types.File, types.File] {
	return native_schema[types.File]('file', [])
}

// Native V functions are checked by the compiler; no JS runtime typeof check is needed.
pub fn instance[T]() types.Schema[T, T] {
	return native_schema[T]('instance', [])
}
