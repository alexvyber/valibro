module main

import valibro as v
import valibro.json as j
import valibro.types
import x.json2

fn main() {
	schema := j.object({
		'name':    j.from_schema(v.pipe(v.string(), v.trim(), v.min_length(2)))
		'age':     j.from_schema(v.pipe(v.number(), v.integer(), v.min_value(0.0)))
		'enabled': j.optional(j.boolean(), json2.Any(true))
	})
	output := j.parse_text(schema, '{"name":" Alex ","age":42,"extra":"removed"}') or { panic(err) }
	println(output)
	bad := j.safe_parse(schema, json2.Any({
		'name': json2.Any(1)
		'age':  json2.Any(-1)
	}))
	println(v.summarize(bad.issues))

	numbers := v.array(v.pipe_to(v.string(), v.to_number()))
	println(v.parse(numbers, ['1', '2']) or { panic(err) })
	maybe := v.optional(v.pipe(v.string(), v.trim()), ' fallback ')
	println((v.parse(maybe, types.missing[string]()) or { panic(err) }).value)
	future := v.parse_async(v.pipe(v.string(), v.normalize(), v.to_upper_case()), 'Straße')
	println(future.await() or { panic(err) })
}
