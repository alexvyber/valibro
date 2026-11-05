module valibro_test

import valibro as v
import valibro.types
import math

struct NumberTag {}

fn test_sets_maps_files_and_native_annotations() {
	trimmed := v.set(v.pipe(v.string(), v.trim()))
	output := v.parse(trimmed, types.new_set([' a ', 'a', ' b '])) or { panic(err) }
	assert output.values == ['a', 'b']
	assert v.is_valid(v.pipe(trimmed, v.size[types.Set[string]](2)), types.new_set([
		'a',
		'b',
	]))
	mapped := v.map_schema(v.number_of[int](), v.pipe(v.string(), v.trim()))
	assert v.parse(mapped, {
		1: ' hi '
	}) or { panic(err) } == {
		1: 'hi'
	}
	blob := types.Blob{
		data:      [u8(1), 2, 3]
		mime_type: 'image/png'
	}
	file := types.File{
		data:      [u8(1), 2]
		mime_type: 'text/plain'
		name:      'hi.txt'
	}
	assert v.is_valid(v.pipe(v.blob(), v.size[types.Blob](3), v.mime_type[types.Blob]([
		'image/png',
	])), blob)
	assert !v.is_valid(v.pipe(v.file(), v.mime_type[types.File](['image/png'])), file)
	tagged := v.pipe(v.number(), v.title_for[f64]('Number'), v.description_for[f64]('Description'))
	assert v.get_title(tagged) or { panic('title') } == 'Number'
	branded := v.pipe_to(tagged, v.brand_for[f64, NumberTag]())
	assert (v.parse(branded, 42.0) or { panic(err) }).value == 42.0
}

fn test_numeric_actions_for_other_native_types() {
	assert v.is_valid(v.pipe(v.number_of[f32](), v.finite_of[f32](), v.integer_of[f32]()), f32(42))
	assert !v.is_valid(v.pipe(v.number_of[f32](), v.finite_of[f32]()), f32(math.inf(1)))
	assert !v.is_valid(v.pipe(v.number_of[f32](), v.integer_of[f32]()), f32(1.5))
	assert !v.is_valid(v.pipe(v.number_of[i64](), v.safe_integer_of[i64]()), i64(9007199254740992))
	assert v.is_valid(v.pipe(v.number_of[u64](), v.safe_integer_of[u64]()), u64(9007199254740991))
	assert !v.is_valid(v.pipe(v.number_of[u64](), v.safe_integer_of[u64]()),
		u64(18446744073709551615))
}

fn test_native_conversions_and_examples() {
	assert v.parse(v.pipe_to(v.boolean(), v.to_number_from[bool]()), true) or { panic(err) } == 1.0
	assert v.parse(v.pipe_to(v.number_of[u64](), v.to_bigint_from[u64]()),
		u64(18446744073709551615)) or { panic(err) }.str() == '18446744073709551615'
	assert v.parse(v.pipe_to(v.number(), v.to_bigint_from[f64]()), 1e20) or { panic(err) }.str() == '100000000000000000000'
	assert !v.safe_parse(v.pipe_to(v.number(), v.to_bigint_from[f64]()), 1.5).success
	assert !(v.parse(v.pipe_to(v.number(), v.to_boolean_from[f64]()), 0.0) or { panic(err) })
	assert v.parse(v.pipe_to(v.number(), v.to_string_from[f64]()), 42.0) or { panic(err) } == '42'
	assert (v.parse(v.pipe_to(v.number(), v.to_date_from[f64]()), 1000.0) or { panic(err) }).unix() == 1
	example := v.pipe(v.number(), v.examples_for([1.0, 2.0]))
	assert v.get_examples_for(example) or { panic('examples') } == [1.0, 2.0]
}

fn test_native_sentinel_conversions() {
	assert !(v.parse(v.pipe_to(v.null_schema(), v.to_boolean_from[types.Null]()), types.Null{}) or {
		panic(err)
	})
	assert !v.safe_parse(v.pipe_to(v.null_schema(), v.to_number_from[types.Null]()), types.Null{}).success
	assert v.parse(v.pipe_to(v.null_schema(), v.to_string_from[types.Null]()), types.Null{}) or {
		panic(err)
	} == 'null'
}

struct EntryCountExample {
	a string
	b int
}

fn test_native_struct_entry_counts_use_declared_fields() {
	value := EntryCountExample{
		a: 'x'
		b: 2
	}
	schema := v.pipe(v.any_value[EntryCountExample](), v.entries[EntryCountExample](2),
		v.min_entries[EntryCountExample](2), v.max_entries[EntryCountExample](2),
		v.not_entries[EntryCountExample](3))
	assert v.is_valid(schema, value)
	failure := v.safe_parse(v.pipe(schema, v.entries[EntryCountExample](1)), value)
	assert failure.issues[0].expected == '1'
	assert failure.issues[0].received == '2'
	assert failure.typed
}
