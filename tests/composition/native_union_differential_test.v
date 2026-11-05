module valibro_test

import valibro.tests.support
import os
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct NativeUnionCalls {
mut:
	values []string
}

struct NativeUnionStructInput {
	a string
	b string
}

struct NativeUnionStructOutput {
	a f64
	b f64
}

struct NativeUnionNestedInput {
	details NativeUnionStructInput
}

struct NativeUnionNestedOutput {
	details NativeUnionStructOutput
}

fn native_union_struct_schema(item types.Schema[string, f64]) types.Schema[NativeUnionStructInput, NativeUnionStructOutput] {
	return v.object_from(fn (input NativeUnionStructInput) NativeUnionStructOutput {
		return NativeUnionStructOutput{}
	}, [
		v.field('a', fn (input NativeUnionStructInput) string {
			return input.a
		}, fn (output NativeUnionStructOutput, value f64) NativeUnionStructOutput {
			return NativeUnionStructOutput{
				...output
				a: value
			}
		}, item),
		v.field('b', fn (input NativeUnionStructInput) string {
			return input.b
		}, fn (output NativeUnionStructOutput, value f64) NativeUnionStructOutput {
			return NativeUnionStructOutput{
				...output
				b: value
			}
		}, item),
	])
}

fn native_union_struct_output(raw types.NativeValue, nested bool) json2.Any {
	mut output := []json2.Any{}
	if nested {
		if types.value_is[types.RawStruct[NativeUnionNestedOutput]](raw) {
			view := types.value_as[types.RawStruct[NativeUnionNestedOutput]](raw) or { panic(err) }
			for key in view.keys {
				child := view.fields[key] or {
					types.value_of[NativeUnionStructOutput](view.value.details)
				}
				output << json2.Any([json2.Any(key), native_union_struct_output(child, false)])
			}
		} else {
			view := types.value_as[NativeUnionNestedOutput](raw) or { panic(err) }
			output << json2.Any([json2.Any('details'),
				native_union_struct_output(types.value_of[NativeUnionStructOutput](view.details),
					false)])
		}
	} else {
		mut snapshot := NativeUnionStructOutput{}
		mut keys := ['a', 'b']
		mut fields := map[string]types.NativeValue{}
		if types.value_is[types.RawStruct[NativeUnionStructOutput]](raw) {
			view := types.value_as[types.RawStruct[NativeUnionStructOutput]](raw) or { panic(err) }
			snapshot = view.value
			keys = view.keys.clone()
			fields = view.fields.clone()
		} else {
			snapshot = types.value_as[NativeUnionStructOutput](raw) or { panic(err) }
		}
		for key in keys {
			fallback := if key == 'a' { snapshot.a } else { snapshot.b }
			value := fields[key] or { types.value_of[f64](fallback) }
			output << json2.Any([json2.Any(key), json2.Any(native_union_scalar(value))])
		}
	}
	return json2.Any(output)
}

fn native_union_scalar(raw types.NativeValue) string {
	if types.value_is[string](raw) { return 's:' + (types.value_as[string](raw) or { panic(err) }) }
	if types.value_is[f64](raw) { return 'n:' + support.reference_number_string(types.value_as[f64](raw) or {
			panic(err)}) }
	panic('Unexpected union scalar')
}

fn native_union_output(raw types.NativeValue, placement string) json2.Any {
	if placement == 'root' { return json2.Any(native_union_scalar(raw)) }
	if placement in ['struct', 'nested_struct'] {
		return native_union_struct_output(raw, placement == 'nested_struct')
	}
	mut items := []types.NativeValue{}
	if types.value_is[types.RawArray](raw) {
		items = (types.value_as[types.RawArray](raw) or { panic(err) }).items.clone()
	} else if types.value_is[types.RawSet](raw) {
		items = (types.value_as[types.RawSet](raw) or { panic(err) }).items.clone()
	} else if types.value_is[[]f64](raw) {
		values := types.value_as[[]f64](raw) or { panic(err) }
		for value in values {
			items << types.value_of(value)
		}
	} else if types.value_is[types.Set[f64]](raw) {
		values := types.value_as[types.Set[f64]](raw) or { panic(err) }
		for value in values.values {
			items << types.value_of(value)
		}
	} else if placement == 'map' {
		mut entries := []types.RawEntry{}
		if types.value_is[types.RawMap](raw) {
			entries = (types.value_as[types.RawMap](raw) or { panic(err) }).entries.clone()
		} else {
			values := types.value_as[map[string]f64](raw) or { panic(err) }
			for key, value in values {
				entries << types.RawEntry{
					key:   types.value_of(key)
					value: types.value_of(value)
				}
			}
		}
		mut output := []json2.Any{}
		for entry in entries {
			key := types.value_as[string](entry.key) or { panic(err) }
			output << json2.Any([json2.Any(key), json2.Any(native_union_scalar(entry.value))])
		}
		return json2.Any(output)
	} else {
		panic('Unexpected union collection')
	}
	return json2.Any(items.map(json2.Any(native_union_scalar(it))))
}

fn native_union_issues(issues []types.Issue) json2.Any {
	mut output := []json2.Any{}
	for issue in issues {
		output << json2.Any({
			'code':     json2.Any(issue.code)
			'kind':     json2.Any(issue.kind.str())
			'expected': json2.Any(issue.expected)
			'received': json2.Any(issue.received)
			'message':  json2.Any(issue.message)
			'dot':      json2.Any(v.get_dot_path(issue))
			'issues':   native_union_issues(issue.issues)
		})
	}
	return json2.Any(output)
}

fn native_union_assert[T](row map[string]json2.Any, result types.SafeParseResult[T], calls []string) {
	placement := (row['placement'] or { panic('placement') }).str()
	assert result.success == (row['success'] or { panic('success') }).bool(), row.str()
	assert result.typed == (row['typed'] or { panic('typed') }).bool(), row.str()
	actual := native_union_output(result.raw_output, placement)
	assert j.equal(actual, row['output'] or { panic('output') }), '${row}: ${actual}'
	details := native_union_issues(result.issues)
	assert j.equal(details, row['issues'] or { panic('issues') }), '${row}: ${details}'
	assert calls == (row['calls'] or { panic('calls') }).as_array().map(it.str()), row.str()
}

fn test_native_type_changing_unions_match_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/composition/native_union_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		mut calls := &NativeUnionCalls{}
		messages := if row['mode']!.str() == 'factory' { [
				types.ErrorMessage('Factory message'),
			] } else { []types.ErrorMessage{} }
		mut config := v.Config{
			abort_early:      row['abort_early']!.bool()
			abort_pipe_early: row['abort_pipe_early']!.bool()
		}
		if row['mode']!.str() == 'config' { config = v.Config{
				...config
				message: 'Config message'
			} }
		mut options := []types.Schema[string, f64]{}
		for index, branch in row['branches']!.as_array() {
			kind := branch.str()
			mut base := v.string()
			if kind == 'gate' {
				base = v.pipe(base, v.check[string](fn [index, mut calls] (input string) bool {
					calls.values << '${index}:gate:${input}'
					return false
				}, ...messages))
			}
			mut option := v.pipe_to(base, v.to_number())
			if messages.len > 0 { option = v.pipe_to(base, v.to_number(...messages)) }
			if kind in ['positive', 'negative'] {
				option = v.pipe(option, v.check[f64](fn [index, kind, mut calls] (input f64) bool {
					calls.values << '${index}:${kind}:' + support.reference_number_string(input)
					return if kind == 'positive' { input > 0 } else { input < 0 }
				}, ...messages))
			}
			options << option
		}
		mut item := v.union(options, ...messages)
		after := row['after']!.str()
		if after == 'transform' {
			item = v.pipe(item, v.transform[f64](fn [mut calls] (input f64) f64 {
				calls.values << 'after:' + support.reference_number_string(input)
				return input + 100
			}))
		} else if after == 'fallback' {
			item = v.fallback(item, -99.0)
		}
		input := row['input']!.str()
		match row['placement']!.str() {
			'struct' {
				schema := native_union_struct_schema(item)
				native_union_assert(row, v.safe_parse_with_config(schema, NativeUnionStructInput{
					a: input
					b: '2'
				}, config), calls.values)
			}
			'nested_struct' {
				child := native_union_struct_schema(item)
				schema := v.object_from(fn (input NativeUnionNestedInput) NativeUnionNestedOutput {
					return NativeUnionNestedOutput{}
				}, [
					v.field('details', fn (input NativeUnionNestedInput) NativeUnionStructInput {
						return input.details
					}, fn (output NativeUnionNestedOutput, value NativeUnionStructOutput) NativeUnionNestedOutput {
						return NativeUnionNestedOutput{
							details: value
						}
					}, child),
				])
				native_union_assert(row, v.safe_parse_with_config(schema, NativeUnionNestedInput{
					details: NativeUnionStructInput{
						a: input
						b: '2'
					}
				}, config), calls.values)
			}
			'root' {
				native_union_assert(row, v.safe_parse_with_config(item, input, config),
					calls.values)
			}
			'array' {
				native_union_assert(row, v.safe_parse_with_config(v.array(item), [
					input,
					'2',
				], config), calls.values)
			}
			'map' {
				native_union_assert(row, v.safe_parse_with_config(v.map_schema(v.string(), item), {
					'a': input
					'b': '2'
				}, config), calls.values)
			}
			else {
				native_union_assert(row, v.safe_parse_with_config(v.set(item), types.new_set([
					input,
					'2',
				]), config), calls.values)
			}
		}
	}
}
