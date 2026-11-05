module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct ArrayCalls {
mut:
	values []json2.Any
}

fn array_predicate(mut calls ArrayCalls, item f64, index int, array []f64) bool {
	array_value := array.map(json2.Any(it))
	calls.values << json2.Any({
		'item':  json2.Any(item)
		'index': json2.Any(index)
		'array': json2.Any(array_value)
	})
	return array.index(item) == index && item > 0
}

fn test_array_callback_arguments_traces_and_results_match_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/collections/array_callback_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		name := row['name']!.str()
		input := row['input']!.as_array().map(it.f64())
		config := v.Config{
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
		}
		mut calls := &ArrayCalls{}
		predicate := fn [mut calls] (item f64, index int, array []f64) bool {
			return array_predicate(mut calls, item, index, array)
		}
		mut output := json2.Any(json2.Null{})
		mut issues := []v.Issue{}
		mut success := false
		if name == 'map' {
			result := types.run(v.pipe_to(v.array(v.number()), v.map_items_with_array[f64, f64](fn [mut calls] (item f64, index int, array []f64) f64 {
				array_predicate(mut calls, item, index, array)
				return item + array.len + index
			})), input, config)
			output = json2.Any(result.value.map(json2.Any(it)))
			issues = result.issues.clone()
			success = result.issues.len == 0
		} else if name == 'reduce' {
			result := types.run(v.pipe_to(v.array(v.number()), v.reduce_items_with_array[f64, f64](fn [mut calls] (acc f64, item f64, index int, array []f64) f64 {
				array_predicate(mut calls, item, index, array)
				return acc + item * array.len + index
			}, 10)), input, config)
			output = json2.Any(result.value)
			issues = result.issues.clone()
			success = result.issues.len == 0
		} else if name == 'find' {
			result := types.run(v.pipe_to(v.array(v.number()),
				v.find_item_with_array[f64](predicate)), input, config)
			if result.value.state == .value { output = json2.Any(result.value.value) }
			issues = result.issues.clone()
			success = result.issues.len == 0
		} else {
			action := match name {
				'filter' { v.filter_items_with_array[f64](predicate) }
				'every' { v.every_item_with_array[f64](predicate) }
				'some' { v.some_item_with_array[f64](predicate) }
				else { v.check_items_with_array[f64](predicate) }
			}

			result := types.run(v.pipe(v.array(v.number()), action), input, config)
			output = json2.Any(result.value.map(json2.Any(it)))
			issues = result.issues.clone()
			success = result.issues.len == 0
		}
		mut details := []json2.Any{}
		for issue in issues {
			mut path := []json2.Any{}
			for part in issue.path {
				match part {
					int { path << json2.Any(part) }
					string { path << json2.Any(part) }
				}
			}
			details << json2.Any({
				'code':    json2.Any(issue.code)
				'message': json2.Any(issue.message)
				'path':    json2.Any(path)
			})
		}
		assert success == row['success']!.bool(), row.str()
		assert j.equal(output, row['output']!), row.str()
		assert j.equal(json2.Any(details), row['issues']!), row.str()
		assert j.equal(json2.Any(calls.values), row['calls']!), row.str()
	}
}
