module valibro_test

import valibro as v
import valibro.json as j
import x.json2

fn test_json_objects_transform_and_report_runtime_types() {
	schema := j.object({
		'name':    j.from_schema(v.pipe(v.string(), v.trim()))
		'age':     j.from_schema(v.pipe(v.number(), v.integer(), v.min_value(0.0)))
		'enabled': j.optional(j.boolean(), json2.Any(true))
	})
	output := j.parse_text(schema, '{"name":" Alex ","age":42,"extra":true}') or { panic(err) }
	assert output.as_map()['name'] or { panic('missing') } == json2.Any('Alex')
	assert output.as_map()['enabled'] or { panic('missing') } == json2.Any(true)
	assert 'extra' !in output.as_map()
	result := j.safe_parse(schema, json2.decode[json2.Any]('{"name":1,"age":-1}') or { panic(err) })
	assert !result.success
	assert result.issues.len == 2
	assert v.get_dot_path(result.issues[0]) == 'name'
	assert v.get_dot_path(result.issues[1]) == 'age'
}

fn test_nested_variants_and_missing_default_provider() {
	schema := j.variant('type', [
		j.object({
			'type': j.literal(json2.Any('a'))
			'name': j.string()
		}),
		j.variant('subtype', [
			j.object({
				'type':    j.literal(json2.Any('b'))
				'subtype': j.literal(json2.Any('one'))
				'age':     j.number()
			}),
			j.object({
				'type':    j.literal(json2.Any('b'))
				'subtype': j.literal(json2.Any('two'))
				'name':    j.string()
			}),
		]),
	])
	assert j.parse_text(schema, '{"type":"b","subtype":"one","age":42}') or { panic(err) } == json2.Any({
		'type':    json2.Any('b')
		'subtype': json2.Any('one')
		'age':     json2.Any(42.0)
	})
	bad := j.safe_parse(schema, json2.Any({
		'type':    json2.Any('b')
		'subtype': json2.Any('bad')
	}))
	assert v.get_dot_path(bad.issues[0]) == 'subtype'
	defaults := j.object({
		'locale': j.optional_with_default(j.string(), fn (config v.Config) json2.Any {
			return json2.Any(config.lang)
		})
	})
	value := j.safe_parse_with_config(defaults, json2.Any(map[string]json2.Any{}), v.Config{
		lang: 'ru'
	}).output or { panic('output') }
	assert value.as_map()['locale'] or { panic('locale') } == json2.Any('ru')
}

fn test_missing_fallback_precedes_required_nullable_default() {
	schema := j.object({
		'value': j.fallback(j.nullable(j.string(), json2.Any('default')), json2.Any('fallback'))
	})
	output := j.parse_text(schema, '{}') or { panic(err) }
	assert output.as_map()['value'] or { panic('value') } == json2.Any('fallback')
}
