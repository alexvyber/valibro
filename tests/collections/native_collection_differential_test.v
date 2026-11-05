module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

fn test_native_collections_failure_outputs_abort_and_flatten_match_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/collections/native_collection_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	mut failures := 0
	for raw in rows {
		row := raw.as_map()
		domain := row['domain']!.str()
		values := row['values']!.as_array().map(it.f64())
		config := v.Config{
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
		}
		transform := row['transform']!.bool()
		items := if transform {
			v.pipe(v.number(), v.min_value(0.0), v.to_min_value(1.0), v.integer())
		} else {
			v.pipe(v.number(), v.min_value(0.0), v.integer())
		}
		keys := if transform {
			v.pipe(v.string(), v.min_length(3), v.trim())
		} else {
			v.pipe(v.string(), v.min_length(3))
		}
		mut input := map[string]f64{}
		for entry in row['entries']!.as_array() {
			pair := entry.as_array()
			input[pair[0].str()] = pair[1].f64()
		}
		mut output := json2.Any(json2.Null{})
		mut issues := []v.Issue{}
		mut typed := false
		if domain == 'array' {
			result := types.run(v.array(items), values, config)
			output = json2.Any(result.value.map(json2.Any(it)))
			issues = result.issues.clone()
			typed = result.typed
		} else if domain == 'set' {
			result := types.run(v.set(items), types.new_set(values), config)
			output = json2.Any(result.value.values.map(json2.Any(it)))
			issues = result.issues.clone()
			typed = result.typed
		} else {
			schema := if domain == 'map' { v.map_schema(keys, items) } else { v.record(keys, items) }
			result := types.run(schema, input, config)
			if domain == 'map' {
				mut entries := []json2.Any{}
				for k, value in result.value {
					entries << json2.Any([json2.Any(k), json2.Any(value)])
				}
				output = json2.Any(entries)
			} else {
				mut object := map[string]json2.Any{}
				for k, value in result.value {
					object[k] = json2.Any(value)
				}
				output = json2.Any(object)
			}
			issues = result.issues.clone()
			typed = result.typed
		}
		mut details := []json2.Any{}
		for issue in issues {
			details << json2.Any({
				'code':     json2.Any(issue.code)
				'expected': json2.Any(issue.expected)
				'received': json2.Any(issue.received)
				'message':  json2.Any(issue.message)
				'dot':      json2.Any(v.get_dot_path(issue))
			})
		}
		flat := v.flatten(issues)
		mut nested := map[string]json2.Any{}
		for key, messages in flat.nested {
			nested[key] = json2.Any(messages.map(json2.Any(it)))
		}
		actual_flat := json2.Any({
			'root':   json2.Any(flat.root.map(json2.Any(it)))
			'nested': json2.Any(nested)
			'other':  json2.Any(flat.other.map(json2.Any(it)))
		})
		if typed != row['typed']!.bool() || !j.equal(output, row['output']!)
			|| !j.equal(json2.Any(details), row['issues']!) || !j.equal(actual_flat, row['flat']!) {
			failures++
			if failures <= 6 {
				eprintln('${row}: output ${output}, typed ${typed}, issues ${details}, flat ${actual_flat}')
			}
		}
	}
	assert failures == 0, '${failures} native collection mismatches'
}
