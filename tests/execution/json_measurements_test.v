module main

import valibro as v
import valibro.json as j
import x.json2

fn test_json_string_lengths_count_javascript_utf16_units() ! {
	assert j.parse(j.pipe(j.string(), j.min_length(2), j.max_length(2)), json2.Any('😀'))! == json2.Any('😀')
	if _ := j.parse(j.pipe(j.string(), j.max_length(1)), json2.Any('😀')) { assert false
	 }
	assert j.parse(j.pipe(j.array(j.string()), j.min_length(1)), json2.Any([json2.Any('x')]))!.as_array().len == 1
}

fn test_records_accept_enumerable_array_keys_like_valibot() ! {
	assert j.parse(j.record(j.string(), j.string()), json2.Any([]json2.Any{}))!.as_map().len == 0
	assert j.parse(j.record(j.string(), j.string()), json2.Any([json2.Any('x')]))!.as_map()['0']! == json2.Any('x')
}

fn test_number_coercion_uses_ecmascript_whitespace() ! {
	assert v.parse(v.pipe_to(v.string(), v.to_number()), '\ufeff2\ufeff')! == 2
	if _ := v.parse(v.pipe_to(v.string(), v.to_number()), '\u00852') { assert false
	 }
}
