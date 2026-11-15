module valibro_test

import valibro as v
import valibro.json as j
import x.json2

fn test_json_schema_preserves_rules_and_enum_values_without_running_callbacks() {
	schema := j.from_schema(v.pipe(v.string(), v.min_length(2), v.max_length(20)))
	assert schema.rules.len == 2
	assert schema.rules[0].type_name == 'min_length'
	assert schema.rules[0].requirement_text == '2'
	assert schema.rules[1].requirement_text == '20'
	enum_schema := j.picklist([json2.Any('draft'), json2.Any('active')])
	assert enum_schema.literal_values == [json2.Any('draft'), json2.Any('active')]
	assert j.literal(json2.Any(1)).literal_values == [json2.Any(1)]
}

fn test_string_length_and_trim_follow_ecmascript_boundaries() ! {
	assert j.parse(j.from_schema(v.pipe(v.string(), v.max_length(2))), json2.Any('😀'))! == json2.Any('😀')
	mut rejected := false
	j.parse(j.from_schema(v.pipe(v.string(), v.max_length(1))), json2.Any('😀')) or {
		rejected = true
	}
	assert rejected
	assert j.parse(j.from_schema(v.pipe(v.string(), v.trim())), json2.Any('\ufeff a \ufeff'))! == json2.Any('a')
	assert j.parse(j.from_schema(v.pipe(v.string(), v.trim())), json2.Any('\u0085a\u0085'))! == json2.Any('\u0085a\u0085')
}
