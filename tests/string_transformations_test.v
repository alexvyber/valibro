module valibro_test

import x.json2
import valibro as v

pub struct TransformationCase {
pub:
	action string
	input  string
	output string
}

fn test_string_transformations_match_upstream() {
	cases := json2.decode[[]TransformationCase]($embed_file('fixtures/string_transformations.json').to_string()) or {
		panic(err)
	}
	actions := {
		'trim':           v.trim()
		'trim_start':     v.trim_start()
		'trim_end':       v.trim_end()
		'to_lower_case':  v.to_lower_case()
		'to_upper_case':  v.to_upper_case()
		'to_camel_case':  v.to_camel_case()
		'to_pascal_case': v.to_pascal_case()
		'to_kebab_case':  v.to_kebab_case()
		'to_snake_case':  v.to_snake_case()
		'to_string':      v.to_string()
		'to_min_value':   v.to_min_value('m')
		'to_max_value':   v.to_max_value('m')
		'stringify_json': v.stringify_json()
	}
	for row in cases {
		action := actions[row.action] or { panic('Unknown action ${row.action}') }
		output := v.parse(v.pipe(v.string(), action), row.input) or { panic(err) }
		assert output == row.output, '${row.action}: ${row.input}: received ${output}, expected ${row.output}'
	}
}

fn test_native_simple_unicode_casing() {
	upper := v.pipe(v.string(), v.to_upper_case())
	lower := v.pipe(v.string(), v.to_lower_case())
	assert v.parse(upper, 'ёж') or { panic(err) } == 'ЁЖ'
	assert v.parse(lower, 'ПРИВЕТ') or { panic(err) } == 'привет'
	// Simple mappings intentionally do not expand ß/ligatures or apply final sigma.
	assert v.parse(upper, 'Straße') or { panic(err) } == 'STRAßE'
	assert v.parse(upper, 'ﬁ') or { panic(err) } == 'ﬁ'
	assert v.parse(lower, 'ΟΣ') or { panic(err) } == 'οσ'
	assert v.parse(lower, 'İSTANBUL') or { panic(err) } == 'istanbul'
}
