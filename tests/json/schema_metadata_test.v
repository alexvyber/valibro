module valibro_test

import valibro as v
import valibro.json as j
import x.json2
import valibro.jsoncodec

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

fn test_nested_pipeline_metadata_keeps_direct_actions_and_all_validators() ! {
	base := v.pipe(v.string(), v.non_empty(), v.check(fn (value string) bool {
		return value == value.trim_space()
	}))
	schema := j.from_schema(v.pipe(base, v.max_length(5)))
	assert schema.rules.len == 3
	assert (schema.pipeline_rules or { panic('Missing pipeline metadata') }).len == 1
	assert (schema.pipeline_rules or { [] })[0].type_name == 'max_length'
	mut empty_rejected := false
	j.parse(schema, json2.Any('')) or { empty_rejected = true }
	assert empty_rejected
	mut untrimmed_rejected := false
	j.parse(schema, json2.Any(' a')) or { untrimmed_rejected = true }
	assert untrimmed_rejected
	assert j.parse(schema, json2.Any('ok'))! == json2.Any('ok')
	array := j.pipe(j.array(j.string()), j.min_length(1), j.max_length(2))
	assert array.rules[0].requirement_text == '1'
	mut short_rejected := false
	j.parse(array, json2.Any([]json2.Any{})) or { short_rejected = true }
	assert short_rejected
	assert j.parse(array, json2.Any([json2.Any('x')]))!.as_array().len == 1
	mut long_rejected := false
	j.parse(array, json2.Any([json2.Any('a'), json2.Any('b'), json2.Any('c')])) or {
		long_rejected = true
	}
	assert long_rejected
}

fn test_regex_retains_original_pattern_and_flags_for_wire_export() {
	schema := j.from_schema(v.pipe(v.string(), v.regex_with_flags('^clinic/[a-z]+$', 'i')))
	assert schema.rules[0].type_name == 'regex'
	metadata := jsoncodec.decode(schema.rules[0].requirement_text) or { panic(err) }
	assert metadata.as_map()['pattern']! == json2.Any('^clinic\\/[a-z]+$')
	assert metadata.as_map()['flags']! == json2.Any('i')
}

fn test_ecmascript_regex_unicode_sets_sticky_global_and_named_groups() ! {
	for pattern in ['(?<clinic>\\p{Letter}+)', '[[a-z]--[aeiou]]+'] {
		flags := if pattern.starts_with('[') { 'v' } else { 'u' }
		schema := j.from_schema(v.pipe(v.string(), v.regex_with_flags(pattern, flags)))
		assert j.parse(schema, json2.Any('clinic'))! == json2.Any('clinic')
	}
	global := j.from_schema(v.pipe(v.string(), v.regex_with_flags('a', 'g')))
	assert regex_accepts(global, 'a')
	assert !regex_accepts(global, 'a')
	assert regex_accepts(global, 'a')
	sticky := j.from_schema(v.pipe(v.string(), v.regex_with_flags('a', 'y')))
	assert !regex_accepts(sticky, 'ba')
}

fn regex_accepts(schema j.Schema, input string) bool {
	j.parse(schema, json2.Any(input)) or { return false }
	return true
}
