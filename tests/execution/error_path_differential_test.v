module valibro_test

import valibro.internal.diagnostics as impl_diagnostics
import valibro.tests.support
import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

fn test_dot_path_flatten_and_summary_match_upstream() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/execution/error_path_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		mut issues := []v.Issue{}
		for index, item in row['paths']!.as_array() {
			entry := item.as_map()
			mut path := []types.PathSegment{}
			mut unavailable := false
			for key in entry['keys']!.as_array() {
				match key {
					string { path << types.PathSegment(key) }
					int { path << types.PathSegment(key) }
					i64 { path << types.PathSegment(key.str()) }
					f64 { path << types.PathSegment(support.reference_number_string(key)) }
					else { unavailable = true }
				}
			}
			issues << v.Issue{
				message:              'Error ' + index.str()
				path:                 path
				path_present:         entry['present']!.bool()
				dot_path_unavailable: unavailable
			}
		}
		assert j.equal(json2.Any(issues.map(json2.Any(v.get_dot_path(it)))), row['dots']!), row.str()
		flat := v.flatten(issues)
		mut nested := map[string]json2.Any{}
		for key, messages in flat.nested {
			nested[key] = json2.Any(messages.map(json2.Any(it)))
		}
		actual := json2.Any({
			'root':   json2.Any(flat.root.map(json2.Any(it)))
			'nested': json2.Any(nested)
			'other':  json2.Any(flat.other.map(json2.Any(it)))
		})
		assert j.equal(actual, row['flat']!), row.str()
		assert v.summarize(issues) == row['summary']!.str(), row.str()
	}
	assert impl_diagnostics.prepend_map_path[bool]([v.Issue{ message: 'flag' }], true)[0].dot_path_unavailable
	assert v.get_dot_path(impl_diagnostics.prepend_map_path[f64]([
		v.Issue{ message: 'number' },
	], 1.0)[0]) == '1'
}
