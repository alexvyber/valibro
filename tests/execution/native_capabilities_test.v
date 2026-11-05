module valibro_test

import valibro.tests.support
import valibro as v
import valibro.types
import math

struct NumberTag {}

fn test_sets_maps_files_and_native_annotations() {
	trimmed := v.set(v.pipe(v.string(), v.trim()))
	output := v.parse(trimmed, types.new_set([' a ', 'a', ' b '])) or { panic(err) }
	assert output.values == ['a', 'b']
	assert support.accepts(v.pipe(trimmed, v.length_of[types.Set[string]](2)), types.new_set([
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
	assert support.accepts(v.pipe(v.blob(), v.length_of[types.Blob](3), v.mime_type[types.Blob]([
		'image/png',
	])), blob)
	assert !support.accepts(v.pipe(v.file(), v.mime_type[types.File](['image/png'])), file)
	tagged := v.pipe(v.number(), v.title[f64]('Number'), v.description[f64]('Description'))
	assert v.get_title(tagged) or { panic('title') } == 'Number'
}

fn test_numeric_actions_for_other_native_types() {
	assert support.accepts(v.pipe(v.number_of[f32](), v.finite_of[f32](), v.integer_of[f32]()),
		f32(42))
	assert !support.accepts(v.pipe(v.number_of[f32](), v.finite_of[f32]()), f32(math.inf(1)))
	assert !support.accepts(v.pipe(v.number_of[f32](), v.integer_of[f32]()), f32(1.5))
	assert !support.accepts(v.pipe(v.number_of[i64](), v.binary64_integer_of[i64]()),
		i64(9007199254740992))
	assert support.accepts(v.pipe(v.number_of[u64](), v.binary64_integer_of[u64]()),
		u64(9007199254740991))
	assert !support.accepts(v.pipe(v.number_of[u64](), v.binary64_integer_of[u64]()),
		u64(18446744073709551615))
}

struct EntryCountExample {
	a string
	b int
}
