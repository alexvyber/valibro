module valibro_test

import valibro.tests.support
import os
import x.json2
import valibro as v
import valibro.json as j
import valibro.types
import valibro.unicode

struct PipelineCalls {
mut:
	entries []json2.Any
}

fn pipeline_trace(dataset types.Dataset[json2.Any], config v.Config) json2.Any {
	return json2.Any({
		'typed':  json2.Any(dataset.typed)
		'value':  dataset.value
		'issues': json2.Any(dataset.issues.len)
		'lang':   json2.Any(config.lang)
	})
}

fn test_raw_callbacks_typed_state_and_abort_settings_differential() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/execution/pipeline_differential.json')) or { panic(err) }) or { panic(err) }).as_array()
	mut failures := 0
	for raw in rows {
		row := raw.as_map()
		mode := row['mode']!.str()
		mut calls := &PipelineCalls{}
		raw_check := v.raw_check_with_context[json2.Any](fn [mut calls] (dataset types.Dataset[json2.Any], config v.Config) types.Dataset[json2.Any] {
			calls.entries << pipeline_trace(dataset, config)
			mut issues := dataset.issues.clone()
			if dataset.value is string && dataset.value == 'a' {
				issues << types.new_issue('raw_check', 'Raw custom', '', '')
			}
			return types.Dataset[json2.Any]{ ...dataset, issues: issues }
		})
		transform := v.raw_transform_with_context[json2.Any](fn [mut calls] (dataset types.Dataset[json2.Any], config v.Config) types.Dataset[json2.Any] {
			calls.entries << pipeline_trace(dataset, config)
			mut issues := dataset.issues.clone()
			if dataset.value is string && dataset.value == 'a' {
				issues << types.new_issue('raw_transform', 'Transform custom', '', '')
			}
			return types.Dataset[json2.Any]{
				...dataset
				value:  json2.Any(unicode.to_upper(dataset.value.str()))
				issues: issues
			}
		})
		schema := match mode {
			'validation' {
				j.from_schema(v.pipe(v.string(), v.min_length(3), v.ends_with('z')))
			}
			'transform_after' {
				j.from_schema(v.pipe(v.string(), v.min_length(3), v.trim()))
			}
			'raw_after' {
				j.pipe(j.from_schema(v.pipe(v.string(), v.min_length(3))), raw_check)
			}
			'raw_after_type' {
				j.pipe(j.number(), raw_check)
			}
			else {
				transformed := if mode == 'raw_transform_to' {
					j.from_schema(v.pipe_to(j.native(j.string()),
						v.raw_transform_to_with_context[json2.Any, json2.Any](transform.context_runner.run)))
				} else {
					j.pipe(j.string(), transform)
				}
				j.pipe(transformed, v.raw_check_with_context[json2.Any](fn (dataset types.Dataset[json2.Any], config v.Config) types.Dataset[json2.Any] {
					if !dataset.typed { return dataset }
					result := v.min_length(3).run(dataset.value.str())
					mut issues := dataset.issues.clone()
					issues << result.issues
					return types.Dataset[json2.Any]{ ...dataset, issues: issues }
				}))
			}
		}

		config := v.Config{
			lang:             row['lang']!.str()
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
			message:          types.ErrorMessage('Config ' + row['lang']!.str())
		}
		dataset := schema.run(row['input']!, config)
		parsed := support.observe_json(schema, row['input']!, config)
		// The second execution is only for native message-resolution boundaries.
		actual_calls := calls.entries[..calls.entries.len / 2].clone()
		codes := dataset.issues.map(json2.Any(it.code))
		messages := parsed.issues.map(json2.Any(it.message))
		if dataset.typed != row['typed']!.bool() || !j.equal(dataset.value, row['value']!)
			|| !j.equal(json2.Any(codes), row['codes']!)
			|| !j.equal(json2.Any(messages), row['messages']!)
			|| !j.equal(json2.Any(actual_calls), row['calls']!) {
			failures++
			if failures <= 8 {
				eprintln('Pipeline ${row}; actual typed=${dataset.typed} value=${dataset.value} codes=${codes} messages=${messages} calls=${actual_calls}')
			}
		}
	}
	assert failures == 0, '${failures} pipeline mismatches'
}

fn test_forward_paths_differential_including_existing_issue_paths() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/forward_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		prior := row['prior']!.bool()
		before := v.raw_check[json2.Any](fn [prior] (input json2.Any) []types.Issue {
			return if prior {
				[types.new_issue('raw_check', 'Before', '', '')]
			} else {
				[]types.Issue{}
			}
		})
		action := v.raw_check[json2.Any](fn (input json2.Any) []types.Issue {
			return [
				types.Issue{
					...types.new_issue('raw_check', 'Forwarded', '', '')
					path: [
						types.PathSegment('initial'),
					]
				},
			]
		})
		mut path := []types.PathSegment{}
		for key in row['path']!.as_array() {
			if key is string {
				path << types.PathSegment(key)
			} else {
				path << types.PathSegment(key.int())
			}
		}
		schema := j.pipe(j.unknown(), before, v.forward(action, path))
		result := j.inspect(schema, row['input']!) or {
			assert err is types.TypeError
			assert err.msg() == row['exception']!.str()
			continue
		}
		assert row['exception']!.str() == '', '${row}: missing execution error'
		mut paths := []json2.Any{}
		for issue in result.issues {
			mut keys := []json2.Any{}
			for key in issue.path {
				match key {
					int { keys << json2.Any(key) }
					string { keys << json2.Any(key) }
				}
			}
			paths << json2.Any(keys)
		}
		assert j.equal(json2.Any(paths), row['paths']!), '${row}; got ${paths}'
		actual_types := result.issues.map(json2.Any(it.path_types.map(json2.Any(it))))
		assert j.equal(json2.Any(actual_types), row['path_types']!), row.str()
		assert j.equal(json2.Any(result.issues.map(json2.Any(it.message))), row['messages']!)
	}
}
