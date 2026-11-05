module main

import valibro as v

fn main() {
	schema := v.pipe(v.string(), v.trim(), v.to_lower_case(), v.min_length(3), v.max_length(32))
	value := v.parse(schema, ' Alex ') or {
		eprintln(err)
		return
	}
	println(value)
}
