module main

import valibro.json as j
import x.json2

fn main() {
	schema := j.object({
		'name':    j.string()
		'enabled': j.optional(j.boolean(), default_value: json2.Any(true))
	})
	output := j.parse_text(schema, '{"name":"Alex"}') or {
		eprintln(err)
		return
	}
	println(output)
}
