module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct StateDefaultAuditCalls {
mut:
	count int
}

fn test_computed_null_and_undefined_defaults_match_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/default_state_audit_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		kind := row['kind']!.str()
		default_kind := row['default_kind']!.str()
		mut calls := &StateDefaultAuditCalls{}
		getter := fn [default_kind, mut calls] (dataset ?types.Dataset[types.Maybe[string]], config v.Config) types.Maybe[string] {
			calls.count++
			return match default_kind {
				'valid' { types.some('  xx  ') }
				'invalid' { types.some('x') }
				'null' { types.null_value[string]() }
				else { types.undefined_value[string]() }
			}
		}
		base := v.pipe(v.string(), v.trim(), v.min_length(2))
		schema := match kind {
			'optional' { v.optional_with_default_state(base, getter) }
			'nullable' { v.nullable_with_default_state(base, getter) }
			'nullish' { v.nullish_with_default_state(base, getter) }
			'undefinedable' { v.undefinedable_with_default_state(base, getter) }
			else { v.exact_optional_with_default_state(base, getter) }
		}

		default := v.get_default(schema) or { panic('default') }
		assert default.state.str() == row['introspection_state']!.str(), row.str()
		input := match row['input_state']!.str() {
			'undefined' { types.undefined_value[string]() }
			'missing' { types.missing[string]() }
			'null' { types.null_value[string]() }
			else { types.some(row['input']!.str()) }
		}

		result := types.run(schema, input, v.Config{ abort_early: row['abort_early']!.bool() })
		assert result.typed == row['typed']!.bool(), row.str()
		assert result.value.state.str() == row['output_state']!.str(), row.str()
		if result.value.state == .value { assert result.value.value == row['output']!.str(), row.str()
		 }
		assert calls.count == row['calls']!.int(), row.str()
		mut details := []json2.Any{}
		for issue in result.issues {
			details << json2.Any({
				'code':     json2.Any(issue.code)
				'expected': json2.Any(issue.expected)
				'received': json2.Any(issue.received)
				'message':  json2.Any(issue.message)
			})
		}
		assert j.equal(json2.Any(details), row['issues']!), '${row}: ${details}'
	}
}
