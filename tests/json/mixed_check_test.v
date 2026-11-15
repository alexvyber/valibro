module valibro_test

import valibro as v
import valibro.json as j
import x.json2

fn test_json_and_native_checks_keep_independent_function_signatures() ! {
	text := v.pipe(v.string(), v.check(fn (value string) bool {
		return value == 'valid'
	}))
	integer := v.pipe(v.number(), v.check(fn (value f64) bool {
		return value == 7
	}))
	array := j.pipe(j.array(j.string()), v.check(fn (value json2.Any) bool {
		return value.as_array().len == 1
	}))
	assert v.parse(text, 'valid')! == 'valid'
	assert v.parse(integer, 7.0)! == 7
	assert j.parse(array, json2.Any([json2.Any('valid')]))!.as_array().len == 1
	mut rejected_text := false
	v.parse(text, 'invalid') or { rejected_text = true }
	assert rejected_text
	mut rejected_number := false
	v.parse(integer, 8.0) or { rejected_number = true }
	assert rejected_number
	mut rejected_json := false
	j.parse(array, json2.Any([]json2.Any{})) or { rejected_json = true }
	assert rejected_json
}
