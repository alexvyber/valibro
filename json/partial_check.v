module json

import valibro.methods
import valibro.types
import x.json2

pub fn partial_check(schema Schema, paths [][]types.PathSegment, predicate fn (json2.Any) bool, messages ...types.ErrorMessage) Schema {
	combined := methods.partial_check(native(schema), paths, predicate, ...messages)
	return Schema{
		...schema
		run: combined.run
	}
}
