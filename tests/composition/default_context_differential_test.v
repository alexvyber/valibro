module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct DefaultCalls {
mut:
	values []json2.Any
}

fn test_computed_default_context_inputs_introspection_and_failures_match_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/default_context_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		name := row['name']!.str()
		invalid := row['invalid']!.bool()
		mut calls := &DefaultCalls{}
		getter := fn [mut calls, invalid] (dataset ?types.Dataset[types.Maybe[string]], config v.Config) string {
			mut state := 'undefined'
			mut value := ''
			if d := dataset {
				state = d.value.state.str()
				if d.value.state == .value { value = d.value.value }
			}
			calls.values << json2.Any({
				'present':     json2.Any(dataset != none)
				'state':       json2.Any(state)
				'value':       json2.Any(value)
				'lang':        json2.Any(config.lang)
				'abort_early': json2.Any(config.abort_early)
			})
			return if invalid { ' x ' } else { ' xxx ' }
		}
		base := v.pipe(v.string(), v.trim(), v.min_length(3))
		schema := match name {
			'optional' { v.optional_with_default_context(base, getter) }
			'exactOptional' { v.exact_optional_with_default_context(base, getter) }
			'nullable' { v.nullable_with_default_context(base, getter) }
			'nullish' { v.nullish_with_default_context(base, getter) }
			else { v.undefinedable_with_default_context(base, getter) }
		}

		config := v.Config{
			lang:        row['lang']!.str()
			abort_early: row['abort_early']!.bool()
		}
		default := v.get_default(schema, config) or { panic('default') }
		assert default.state == .value
		assert default.value == row['introspection']!.str(), row.str()
		manual := v.get_default_with_context(schema, types.Dataset[types.Maybe[string]]{
			value: types.some('manual')
		}, config) or { panic('manual default') }
		assert manual == default
		input := match row['input_state']!.str() {
			'null' { types.null_value[string]() }
			'undefined' { types.undefined_value[string]() }
			else { types.some(row['input']!.str()) }
		}

		result := types.run(schema, input, config)
		assert result.typed == row['typed']!.bool(), row.str()
		assert result.value.state.str() == row['output_state']!.str(), row.str()
		if result.value.state == .value { assert result.value.value == row['output']!.str(), row.str()
		 }
		mut details := []json2.Any{}
		for issue in result.issues {
			details << json2.Any({
				'code':     json2.Any(issue.code)
				'expected': json2.Any(issue.expected)
				'received': json2.Any(issue.received)
				'message':  json2.Any(issue.message)
			})
		}
		assert j.equal(json2.Any(details), row['issues']!), row.str()
		assert j.equal(json2.Any(calls.values), row['calls']!), row.str()
	}
}
