module valibro_test

import valibro as v
import valibro.json as j
import valibro.types
import x.json2
import os
import math

fn describe_schema(d map[string]json2.Any) j.Schema {
	kind := d['kind'] or { panic('kind') }.str()
	if kind == 'convertNumber' { return j.from_schema(v.pipe_to(v.string(), v.to_number())) }
	if kind == 'string' {
		mut actions := []types.Action[string]{}
		for a in (d['actions'] or { json2.Any([]json2.Any{}) }).as_array() {
			action := a.as_map()
			name := (action['name'] or { panic('name') }).str()
			actions << match name {
				'trim' { v.trim() }
				'toLowerCase' { v.to_lower_case() }
				'minLength' { v.min_length((action['value'] or { panic('value') }).int()) }
				'maxLength' { v.max_length((action['value'] or { panic('value') }).int()) }
				else { panic(name) }
			}
		}
		return j.from_schema(v.pipe(v.string(), ...actions))
	}
	if kind == 'number' {
		mut actions := []types.Action[f64]{}
		for a in (d['actions'] or { json2.Any([]json2.Any{}) }).as_array() {
			action := a.as_map()
			name := (action['name'] or { panic('name') }).str()
			actions << match name {
				'integer' { v.integer() }
				'minValue' { v.min_value((action['value'] or { panic('value') }).f64()) }
				else { panic(name) }
			}
		}
		return j.from_schema(v.pipe(v.number(), ...actions))
	}
	if kind in ['object', 'strictObject', 'looseObject', 'objectWithRest'] {
		mut entries := map[string]j.Schema{}
		for key, child in (d['entries'] or { panic('entries') }).as_map() {
			entries[key] = describe_schema(child.as_map())
		}
		return match kind {
			'object' {
				j.object(entries)
			}
			'strictObject' {
				j.strict_object(entries)
			}
			'looseObject' {
				j.loose_object(entries)
			}
			else {
				j.object_with_rest(entries,
					describe_schema((d['rest'] or { panic('rest') }).as_map()))
			}
		}
	}
	if kind == 'array' { return j.array(describe_schema((d['item'] or { panic('item') }).as_map())) }
	if kind in ['tuple', 'strictTuple', 'looseTuple', 'tupleWithRest'] {
		mut items := []j.Schema{}
		for item in (d['items'] or { panic('items') }).as_array() {
			items << describe_schema(item.as_map())
		}
		return match kind {
			'tuple' {
				j.tuple(items)
			}
			'strictTuple' {
				j.strict_tuple(items)
			}
			'looseTuple' {
				j.loose_tuple(items)
			}
			else {
				j.tuple_with_rest(items, describe_schema((d['rest'] or { panic('rest') }).as_map()))
			}
		}
	}
	if kind in ['union', 'intersect', 'variant'] {
		mut items := []j.Schema{}
		for item in (d['options'] or { panic('options') }).as_array() {
			items << describe_schema(item.as_map())
		}
		return match kind {
			'union' { j.union(items) }
			'intersect' { j.intersect(items) }
			else { j.variant((d['key'] or { panic('key') }).str(), items) }
		}
	}
	if kind == 'record' { return j.record(describe_schema((d['key'] or { panic('key') }).as_map()), describe_schema((d['value'] or {
			panic('value')}).as_map())) }
	if kind in ['optional', 'exactOptional', 'nullable', 'nullish'] {
		child := describe_schema((d['wrapped'] or { panic('wrapped') }).as_map())
		mut defaults := []json2.Any{}
		if value := d['default'] { defaults << value }
		return match kind {
			'optional' { j.optional(child, ...defaults) }
			'exactOptional' { j.exact_optional(child, ...defaults) }
			'nullable' { j.nullable(child, ...defaults) }
			else { j.nullish(child, ...defaults) }
		}
	}
	if kind in ['nonOptional', 'nonNullable', 'nonNullish', 'partial', 'required', 'pick', 'omit',
		'keyof', 'fallback'] {
		child := describe_schema((d['wrapped'] or { panic('wrapped') }).as_map())
		mut keys := []string{}
		for key in (d['keys'] or { json2.Any([]json2.Any{}) }).as_array() {
			keys << key.str()
		}
		return match kind {
			'nonOptional' {
				j.non_optional(child)
			}
			'nonNullable' {
				j.non_nullable(child)
			}
			'nonNullish' {
				j.non_nullish(child)
			}
			'partial' {
				if 'keys' in d {
					j.partial(child, keys)
				} else {
					j.partial(child)
				}
			}
			'required' {
				if 'keys' in d {
					j.required(child, keys)
				} else {
					j.required(child)
				}
			}
			'pick' {
				j.pick(child, keys)
			}
			'omit' {
				j.omit(child, keys)
			}
			'keyof' {
				j.keyof(child)
			}
			else {
				j.fallback(child, d['value'] or { panic('value') })
			}
		}
	}
	return match kind {
		'boolean' { j.boolean() }
		'unknown' { j.unknown() }
		'never' { j.never() }
		'null' { j.null_value() }
		'literal' { j.literal(d['value'] or { panic('value') }) }
		'picklist' { j.picklist((d['values'] or { panic('values') }).as_array()) }
		else { panic(kind) }
	}
}

fn test_upstream_structural_fixtures() {
	data := os.read_file(os.join_path(@VMODROOT, 'tests', 'fixtures',
		'composition/structural_parity.json')) or { panic(err) }
	rows := (json2.decode[json2.Any](data) or { panic(err) }).as_array()
	for index, row in rows {
		sample := row.as_map()
		descriptor := (sample['schema'] or { panic('schema') }).as_map()
		input := sample['input'] or { panic('input') }
		result := j.safe_parse_with_config(describe_schema(descriptor), input, v.Config{
			abort_early: (sample['abort_early'] or { panic('abort') }).bool()
		})
		label := '${index}: ${descriptor} input=${input}'
		assert result.success == (sample['success'] or { panic('success') }).bool(), label
		if result.success {
			output := result.output or { panic('output') }
			expected := sample['output'] or { panic('expected') }
			assert j.equal(output, expected), '${label}: ${output} != ${expected}'
		} else {
			mut codes := []string{}
			for code in (sample['codes'] or { panic('codes') }).as_array() {
				codes << code.str()
			}
			assert result.issues.map(it.code) == codes, '${label}: ${result.issues.map(it.code)} != ${codes}'
			paths := (sample['paths'] or { panic('paths') }).as_array()
			for i, issue in result.issues {
				mut expected := []types.PathSegment{}
				for part in paths[i].as_array() {
					if part is string {
						expected << types.PathSegment(part)
					} else {
						expected << types.PathSegment(part.int())
					}
				}
				assert issue.path == expected, label
			}
		}
	}
}

fn issue_shape(issues []types.Issue) json2.Any {
	mut output := []json2.Any{}
	for issue in issues {
		mut path := []json2.Any{}
		for part in issue.path {
			match part {
				int { path << json2.Any(part) }
				string { path << json2.Any(part) }
			}
		}
		output << json2.Any({
			'code':   json2.Any(issue.code)
			'path':   json2.Any(path)
			'issues': issue_shape(issue.issues)
		})
	}
	return json2.Any(output)
}

fn test_nested_composition_differential() {
	data := json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/composition_differential.json')) or { panic(err) }) or {
		panic(err)
	}
	corpus := data.as_map()
	details := corpus['issue_details']!.as_array()
	mut schemas := []j.Schema{}
	for descriptor in corpus['descriptors']!.as_array() {
		schemas << describe_schema(descriptor.as_map())
	}
	mut failures := 0
	mut categories := map[string]int{}
	mut diagnostics := []json2.Any{}
	for index, raw in corpus['rows']!.as_array() {
		row := raw.as_map()
		id := row['schema_id']!.int()
		result := schemas[id].run(row['input']!, v.Config{
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
		})
		success := result.typed && result.issues.len == 0
		reason := if success != row['success']!.bool() {
			'success'
		} else if result.typed != row['typed']!.bool() {
			'typed'
		} else if !j.equal(issue_shape(result.issues), row['issues']!) {
			'issues'
		} else if !j.equal(issue_detail_shape(result.issues), details[row['issue_detail']!.int()]) {
			'fields'
		} else if !j.equal(project_dataset_output(result.value), row['output'] or { json2.Null{} }) {
			'output'
		} else {
			''
		}
		if reason != '' {
			categories[reason]++
			diagnostics << json2.Any({
				'row':            json2.Any(row)
				'reason':         json2.Any(reason)
				'actual_issues':  issue_shape(result.issues)
				'actual_details': issue_detail_shape(result.issues)
				'actual_typed':   json2.Any(result.typed)
				'actual_value':   result.value
			})
			if failures < 12 {
				eprintln('${index} schema ${id} ${reason}: ${row}; got typed=${result.typed} issues=${issue_shape(result.issues)} value=${result.value}')
			}
			failures++
		}
	}
	if report := os.getenv_opt('VALIBRO_DIFFERENTIAL_REPORT') { os.write_file(report, json2.encode(diagnostics)) or {
			panic(err)} }
	assert failures == 0, '${failures} mismatches: ${categories}'
}

fn test_default_and_fallback_introspection_differential() {
	corpus := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/composition_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_map()
	descriptors := corpus['descriptors']!.as_array()
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/introspection_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	mut failures := 0
	for raw in rows {
		row := raw.as_map()
		descriptor := descriptors[row['schema_id']!.int()].as_map()
		schema := describe_schema(descriptor)
		default := j.get_default(schema)
		fallback := j.get_fallback(schema)
		if (default != none) != row['has_default']!.bool()
			|| (fallback != none) != row['has_fallback']!.bool()
			|| !j.equal(default or {
			json2.Null{}
		}, row['default']!)
			|| !j.equal(fallback or { json2.Null{} }, row['fallback']!)
			|| !j.equal(j.get_defaults(schema), row['defaults']!)
			|| !j.equal(j.get_fallbacks(schema), row['fallbacks']!) {
			failures++
			if failures <= 6 {
				eprintln('Introspection ${descriptor}: expected ${row}; actual ${j.get_defaults(schema)} / ${j.get_fallbacks(schema)}')
			}
		}
	}
	assert failures == 0, '${failures} introspection mismatches'
}

fn issue_detail_shape(issues []types.Issue) json2.Any {
	mut output := []json2.Any{}
	for issue in issues {
		mut path := []json2.Any{}
		for part in issue.path {
			match part {
				int { path << json2.Any(part) }
				string { path << json2.Any(part) }
			}
		}
		output << json2.Any({
			'code':     json2.Any(issue.code)
			'kind':     json2.Any(issue.kind.str())
			'expected': json2.Any(issue.expected)
			'received': json2.Any(issue.received)
			'message':  json2.Any(issue.message)
			'path':     json2.Any(path)
			'issues':   issue_detail_shape(issue.issues)
		})
	}
	return json2.Any(output)
}

// The fixture file uses JSON projection for unsupported JS output values.
fn project_dataset_output(value json2.Any) json2.Any {
	match value {
		f64 {
			if math.is_nan(value) || math.is_inf(value, 0) { return json2.Any(json2.Null{}) }
			return value
		}
		[]json2.Any {
			mut output := []json2.Any{}
			for item in value {
				output << project_dataset_output(item)
			}
			return json2.Any(output)
		}
		map[string]json2.Any {
			mut output := map[string]json2.Any{}
			for key, item in value {
				output[key] = project_dataset_output(item)
			}
			return json2.Any(output)
		}
		else {
			return value
		}
	}
}
