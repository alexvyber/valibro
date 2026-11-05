module valibro_test

import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct FallbackCalls {
mut:
	values []json2.Any
}

fn test_fallback_context_and_introspection_match_reference() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/fallback_context_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		mut calls := &FallbackCalls{}
		config := v.Config{
			lang:             row['lang']!.str()
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
		}
		schema := v.fallback_with_context(v.pipe(v.string(), v.trim(), v.min_length(3),
			v.max_length(4)), fn [mut calls] (dataset ?types.Dataset[string], config v.Config) string {
			mut value := ''
			mut typed := false
			mut codes := []string{}
			present := dataset != none
			if d := dataset {
				value = d.value
				typed = d.typed
				codes = d.issues.map(it.code)
			}
			codes_value := codes.map(json2.Any(it))
			calls.values << json2.Any({
				'present': json2.Any(present)
				'value':   json2.Any(value)
				'typed':   json2.Any(typed)
				'codes':   json2.Any(codes_value)
				'lang':    json2.Any(config.lang)
			})
			if !present { return 'none:' + config.lang }
			return '${value}:${typed}:${codes.join(',')}:${config.lang}'
		})
		assert v.get_fallback(schema, config) or { panic('missing fallback') } == row['introspection']!.str(), row.str()
		output := v.parse_with_config(schema, row['input']!.str(), config) or { panic(err) }
		assert output == row['output']!.str(), row.str()
		assert j.equal(json2.Any(calls.values), row['calls']!), row.str()
		assert v.get_fallback(v.fallback(schema, 'static')) or { panic('missing') } == 'static'
	}
}
