module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct PartialCalls {
mut:
	values []json2.Any
}

fn test_partial_check_readiness_wildcards_and_guard_fields_match_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/custom_check_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	shape := j.object({
		'a':   j.string()
		'b':   j.string()
		'arr': j.array(j.object({
			'x': j.number()
			'y': j.string()
		}))
	})
	mut failures := 0
	for raw in rows {
		row := raw.as_map()
		mode := row['mode']!.str()
		mut calls := &PartialCalls{}
		factory := if mode == 'factory' {
			[types.ErrorMessage('Factory message')]
		} else {
			[]types.ErrorMessage{}
		}
		mut config := v.Config{
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
		}
		if mode == 'config' { config = v.Config{
				...config
				message: 'Config message'
			} }
		mut paths := [][]types.PathSegment{}
		for path in row['paths']!.as_array() {
			mut segments := []types.PathSegment{}
			for part in path.as_array() {
				match part {
					string { segments << types.PathSegment(part) }
					else { segments << types.PathSegment(part.int()) }
				}
			}
			paths << segments
		}
		schema := if row['action']!.str() in ['partial', 'forward_partial'] {
			base := if row['action']!.str() == 'forward_partial' {
				j.pipe(j.array(j.number()), v.forward(v.check[json2.Any](fn (value json2.Any) bool {
					return false
				}, ...factory), [types.PathSegment(0)]), v.transform[json2.Any](fn (value json2.Any) json2.Any {
					return value
				}))
			} else {
				shape
			}
			j.native(j.partial_check(base, paths, fn [mut calls] (value json2.Any) bool {
				calls.values << value
				return false
			}, ...factory))
		} else {
			v.pipe(v.unknown[json2.Any](), v.guard[json2.Any](fn (value json2.Any) bool {
				if value is string { return value.len >= 2 }
				return false
			}, ...factory))
		}
		result := types.run(schema, row['input']!, config)
		mut details := []json2.Any{}
		for issue in result.issues {
			mut path := []json2.Any{}
			for part in issue.path {
				match part {
					string { path << json2.Any(part) }
					int { path << json2.Any(part) }
				}
			}
			details << json2.Any({
				'code':     json2.Any(issue.code)
				'kind':     json2.Any(issue.kind.str())
				'expected': json2.Any(issue.expected)
				'received': json2.Any(issue.received)
				'message':  json2.Any(issue.message)
				'path':     json2.Any(path)
			})
		}
		if result.typed != row['typed']!.bool() || !j.equal(result.value, row['output']!)
			|| !j.equal(json2.Any(details), row['issues']!)
			|| !j.equal(json2.Any(calls.values), row['calls']!) {
			failures++
			if failures <= 6 {
				eprintln('${row}: typed ${result.typed}, value ${result.value}, issues ${details}, calls ${calls.values}')
			}
		}
	}
	assert failures == 0, '${failures} partial/guard mismatches'
}
