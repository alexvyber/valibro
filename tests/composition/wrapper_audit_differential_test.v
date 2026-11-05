module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

fn wrapper_audit_issues(issues []v.Issue) json2.Any {
	mut output := []json2.Any{}
	for issue in issues {
		mut path := []json2.Any{}
		for part in issue.path {
			match part {
				string { path << json2.Any(part) }
				int { path << json2.Any(part) }
			}
		}
		output << json2.Any({
			'code':     json2.Any(issue.code)
			'expected': json2.Any(issue.expected)
			'received': json2.Any(issue.received)
			'message':  json2.Any(issue.message)
			'path':     json2.Any(path)
		})
	}
	return json2.Any(output)
}

fn test_wrapped_schema_identity_and_shape_operations_match_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/wrapper_audit_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	mut failures := 0
	for raw in rows {
		row := raw.as_map()
		mut issues := []v.Issue{}
		mut typed := false
		mut output := json2.Any('')
		mut type_name := ''
		mut expects := ''
		mut title := ''
		mut output_state := 'value'
		if row['family']!.str() == 'unwrap' {
			base := v.pipe(v.string(), v.trim(), v.min_length(2), v.title('inner'))
			name := row['wrapper']!.str()
			mut schema := match name {
				'optional' { v.optional(base, 'default') }
				'nullable' { v.nullable(base, 'default') }
				'nullish' { v.nullish(base, 'default') }
				'exactOptional' { v.exact_optional(base, 'default') }
				'undefinedable' { v.undefinedable(base, 'default') }
				'nonOptional' { v.non_optional(v.optional(base)) }
				'nonNullable' { v.non_nullable(v.optional(base)) }
				else { v.non_nullish(v.optional(base)) }
			}

			if row['outer']!.str() == 'pipe' { schema = v.pipe(schema, v.check[types.Maybe[string]](fn (value types.Maybe[string]) bool {
					return false}, 'Outer'), v.title_for[types.Maybe[string]]('outer')) }
			if row['outer']!.str() == 'fallback' {
				schema = v.fallback(schema, types.some('fallback'))
			}
			if name.starts_with('non') {
				unwrapped := v.unwrap_as[types.Maybe[string], types.Maybe[string], types.Maybe[string], types.Maybe[string]](schema) or {
					panic(err)
				}
				input := if row['input_state']!.str() == 'undefined' {
					types.undefined_value[string]()
				} else {
					types.some(row['input']!.str())
				}
				result := types.run(unwrapped, input, v.Config{})
				issues = result.issues.clone()
				typed = result.typed
				output_state = result.value.state.str()
				output = json2.Any(if result.value.state == .value { result.value.value } else { '' })
				type_name = unwrapped.type_name
				expects = unwrapped.expects
				title = v.get_title(unwrapped) or { '' }
			} else {
				unwrapped := v.unwrap(schema)
				result := types.run(unwrapped, row['input']!.str(), v.Config{})
				issues = result.issues.clone()
				typed = result.typed
				output = json2.Any(result.value)
				type_name = unwrapped.type_name
				expects = unwrapped.expects
				title = v.get_title(unwrapped) or { '' }
			}
			if type_name != row['type']!.str() || expects != row['expects']!.str()
				|| title != row['title']!.str() || output_state != row['output_state']!.str() {
				failures++
				if failures < 5 {
					eprintln('Metadata ${row}: ${type_name} ${expects} ${title} ${output_state}')
				}
			}
		} else {
			entries := {
				'a': j.string()
				'b': j.optional(j.string(), json2.Any('b'))
			}
			mut schema := match row['mode']!.str() {
				'object' { j.object(entries, 'Object factory') }
				'strictObject' { j.strict_object(entries, 'Object factory') }
				'looseObject' { j.loose_object(entries, 'Object factory') }
				else { j.object_with_rest(entries, j.number(), 'Object factory') }
			}

			if row['outer']!.str() == 'fallback' { schema = j.fallback(schema, json2.Any({
					'a': json2.Any('recovery')
				})) }
			if row['outer']!.str() == 'pipe' { schema = j.pipe(schema, v.check[json2.Any](fn (value json2.Any) bool {
					return false}, 'Outer')) }
			keys := row['keys']!.as_array().map(it.str())
			shaped := match row['operation']!.str() {
				'pick' { j.pick(schema, keys) }
				'omit' { j.omit(schema, keys) }
				'partial' { j.partial(schema, keys) }
				'required' { j.required(schema, keys) }
				else { j.required_with_message(schema, 'Required factory', keys) }
			}

			result := types.run(j.native(shaped), row['input']!, v.Config{
				abort_early: row['abort_early']!.bool()
			})
			issues = result.issues.clone()
			typed = result.typed
			output = result.value
			assert shaped.entries.keys() == row['entries']!.as_array().map(it.str()), row.str()
		}
		if typed != row['typed']!.bool() || !j.equal(output, row['output']!)
			|| !j.equal(wrapper_audit_issues(issues), row['issues']!) {
			failures++
			if failures < 6 {
				eprintln('${row}: typed ${typed}, value ${output}, issues ${wrapper_audit_issues(issues)}')
			}
		}
	}
	assert failures == 0, '${failures} wrapper audit mismatches'
}
