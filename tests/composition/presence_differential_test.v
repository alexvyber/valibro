module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

fn test_native_presence_fields_defaults_and_failed_values_match_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/presence_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	mut failures := 0
	for raw in rows {
		row := raw.as_map()
		name := row['name']!.str()
		base := v.pipe(v.string(), v.trim(), v.min_length(3))
		defaults := if row['use_default']!.bool() { [' xx '] } else { []string{} }
		wrapped := v.nullish(base, ...defaults)
		schema := match name {
			'optional' { v.optional(base, ...defaults) }
			'exactOptional' { v.exact_optional(base, ...defaults) }
			'nullable' { v.nullable(base, ...defaults) }
			'nullish' { wrapped }
			'undefinedable' { v.undefinedable(base, ...defaults) }
			'nonOptional' { v.non_optional(wrapped) }
			'nonNullable' { v.non_nullable(wrapped) }
			else { v.non_nullish(wrapped) }
		}

		input := match row['input_state']!.str() {
			'null' { types.null_value[string]() }
			'undefined' { types.undefined_value[string]() }
			else { types.some(row['input']!.str()) }
		}

		result := types.run(schema, input, v.Config{
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
		})
		safe := v.safe_parse_with_config(schema, input, v.Config{
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
		})
		assert safe.typed == result.typed
		mut issues := []json2.Any{}
		for issue in result.issues {
			issues << json2.Any({
				'code':     json2.Any(issue.code)
				'expected': json2.Any(issue.expected)
				'received': json2.Any(issue.received)
				'message':  json2.Any(issue.message)
			})
		}
		value_matches := result.value.state != .value || result.value.value == row['output']!.str()
		if schema.expects != row['expects']!.str() || result.typed != row['typed']!.bool()
			|| result.value.state.str() != row['output_state']!.str() || !value_matches
			|| !j.equal(json2.Any(issues), row['issues']!) {
			failures++
			if failures <= 6 {
				eprintln('${row}: expects ${schema.expects}, typed ${result.typed}, value ${result.value}, issues ${issues}')
			}
		}
	}
	assert failures == 0, '${failures} native presence mismatches'
}
