module valibro_test

import valibro.tests.support
import os
import math
import x.json2
import valibro as v
import valibro.types
import valibro.json as j

struct EqualityValue {
	value int
}

fn equality_number(input string) int {
	return if input in ['two', 'dos'] {
		2
	} else if input.starts_with('nan') {
		3
	} else if input in ['zero', 'negative_zero'] {
		0
	} else {
		1
	}
}

fn equality_output[T](input string) T {
	number := equality_number(input)
	$if T is f32 || T is f64 {
		if input.starts_with('nan') { return T(math.nan()) }
		if input == 'negative_zero' { return T(math.copysign(0, -1)) }
		return T(number)
	} $else $if T is bool {
		return number != 0
	} $else $if T is EqualityValue {
		return EqualityValue{
			value: number
		}
	} $else $if T is []int {
		return [number]
	} $else $if T is map[string]int {
		return {
			'value': number
		}
	} $else $if T is json2.Any {
		if input.starts_with('nan') { return json2.Any(math.nan()) }
		if input == 'negative_zero' { return json2.Any(math.copysign(0, -1)) }
		return json2.Any(number)
	} $else {
		return T(number)
	}
}

fn equality_encode[T](raw types.NativeValue) json2.Any {
	if types.value_is[string](raw) {
		return json2.Any(types.value_as[string](raw) or { panic(err) })
	}
	value := types.value_as[T](raw) or { panic(err) }
	$if T is f32 || T is f64 {
		if math.is_nan(f64(value)) { return json2.Any('NaN') }
		return json2.Any(f64(value))
	} $else $if T is json2.Any {
		if value is f64 && math.is_nan(value) { return json2.Any('NaN') }
		return value
	} $else {
		return json2.decode[json2.Any](json2.encode(value)) or { panic(err) }
	}
}

fn check_partial_equality[T](row map[string]json2.Any) {
	input := (row['input'] or { panic('input') }).as_array().map(it.str())
	config := v.Config{
		abort_early:      (row['abort_early'] or { panic('abort') }).bool()
		abort_pipe_early: (row['abort_pipe_early'] or { panic('abort') }).bool()
	}
	item := v.pipe_to(v.custom[string](fn (value string) bool {
		return value != 'bad'
	}), v.transform_to[string, T](equality_output[T]))
	mut output := []json2.Any{}
	mut issues := []v.Issue{}
	mut typed := false
	if (row['family'] or { panic('family') }).str() == 'set' {
		result := support.observe(v.set(item), types.new_set(input), config)
		typed = result.typed
		issues = result.issues.clone()
		if types.value_is[types.RawSet](result.raw_output) {
			raw := types.value_as[types.RawSet](result.raw_output) or { panic(err) }
			for value in raw.items {
				output << equality_encode[T](value)
			}
		} else {
			value := types.value_as[types.Set[T]](result.raw_output) or { panic(err) }
			for entry in value.values {
				output << equality_encode[T](types.value_of(entry))
			}
		}
	} else {
		mut entries := []types.MapEntry[string, string]{}
		for index, key in input {
			entries << types.MapEntry[string, string]{
				key:   key
				value: index.str()
			}
		}
		result := support.observe(v.entry_map(item, v.string(), fn [T](left T, right T) bool {
			return types.native_set_equal[T](left, right)
		}), types.entry_map(entries, fn (left string, right string) bool {
			return left == right
		}), config)
		typed = result.typed
		issues = result.issues.clone()
		if types.value_is[types.RawMap](result.raw_output) {
			raw := types.value_as[types.RawMap](result.raw_output) or { panic(err) }
			for entry in raw.entries {
				value := types.value_as[string](entry.value) or { panic(err) }
				output << json2.Any([equality_encode[T](entry.key), json2.Any(value)])
			}
		} else {
			value := types.value_as[types.EntryMap[T, string]](result.raw_output) or { panic(err) }
			for entry in value.entries {
				output << json2.Any([equality_encode[T](types.value_of(entry.key)), json2.Any(entry.value)])
			}
		}
	}
	expected := row['output'] or { panic('output') }
	assert j.equal(json2.Any(output), expected), '${row}: ${output}'
	assert typed == (row['typed'] or { panic('typed') }).bool(), row.str()
	actual := issues.map(json2.Any({
		'code':    json2.Any(it.code)
		'message': json2.Any(it.message)
	}))
	assert j.equal(json2.Any(actual), row['issues'] or { panic('issues') }), row.str()
}

fn check_partial_native_map[T](row map[string]json2.Any) {
	if (row['family'] or { panic('family') }).str() != 'map' { return }
	input_keys := (row['input'] or { panic('input') }).as_array().map(it.str())
	mut input := map[string]string{}
	for index, key in input_keys {
		input[key] = index.str()
	}
	config := v.Config{
		abort_early:      (row['abort_early'] or { panic('abort') }).bool()
		abort_pipe_early: (row['abort_pipe_early'] or { panic('abort') }).bool()
	}
	item := v.pipe_to(v.custom[string](fn (value string) bool {
		return value != 'bad'
	}), v.transform_to[string, T](equality_output[T]))
	result := support.observe(v.map_schema(item, v.string()), input, config)
	mut output := []json2.Any{}
	if types.value_is[types.RawMap](result.raw_output) {
		raw := types.value_as[types.RawMap](result.raw_output) or { panic(err) }
		for entry in raw.entries {
			value := types.value_as[string](entry.value) or { panic(err) }
			output << json2.Any([equality_encode[T](entry.key), json2.Any(value)])
		}
	} else {
		value := types.value_as[map[T]string](result.raw_output) or { panic(err) }
		for key, entry in value {
			output << json2.Any([equality_encode[T](types.value_of[T](T(key))), json2.Any(entry)])
		}
	}
	assert j.equal(json2.Any(output), row['output'] or { panic('output') }), '${row}: ${output}'
	assert result.typed == (row['typed'] or { panic('typed') }).bool(), row.str()
}

fn test_partial_collection_equality_matches_valibot() {
	rows := (json2.decode[json2.Any](os.read_file(os.join_path(@VMODROOT,
		'tests/fixtures/collections/partial_equality_differential.json')) or { panic(err) }) or {
		panic(err)
	}).as_array()
	for raw in rows {
		row := raw.as_map()
		match row['kind'] or { panic('kind') }.str() {
			'f32' {
				check_partial_equality[f32](row)
			}
			'f64' {
				check_partial_equality[f64](row)
			}
			'i8' {
				check_partial_equality[i8](row)
				check_partial_native_map[i8](row)
			}
			'i16' {
				check_partial_equality[i16](row)
				check_partial_native_map[i16](row)
			}
			'int' {
				check_partial_equality[int](row)
				check_partial_native_map[int](row)
			}
			'i64' {
				check_partial_equality[i64](row)
				check_partial_native_map[i64](row)
			}
			'isize' {
				check_partial_equality[isize](row)
			}
			'u8' {
				check_partial_equality[u8](row)
				check_partial_native_map[u8](row)
			}
			'u16' {
				check_partial_equality[u16](row)
				check_partial_native_map[u16](row)
			}
			'u32' {
				check_partial_equality[u32](row)
				check_partial_native_map[u32](row)
			}
			'u64' {
				check_partial_equality[u64](row)
				check_partial_native_map[u64](row)
			}
			'usize' {
				check_partial_equality[usize](row)
			}
			'bool' {
				check_partial_equality[bool](row)
			}
			'struct' {
				check_partial_equality[EqualityValue](row)
			}
			'array' {
				check_partial_equality[[]int](row)
			}
			'map' {
				check_partial_equality[map[string]int](row)
			}
			else {
				check_partial_equality[json2.Any](row)
			}
		}
	}
}
