module valibro_test

import valibro.tests.support
import valibro as v
import valibro.types
import math

fn test_array_transforms_and_nested_paths() {
	schema := v.array(v.pipe(v.pipe_to(v.string(), v.to_number()), v.integer(), v.min_value(0.0)))
	assert v.parse(schema, ['1', '2']) or { panic(err) } == [1.0, 2.0]
	result := support.observe(schema, ['1', '-2', '3.5', 'bad'])
	assert !result.success
	assert result.issues.map(it.code) == ['min_value', 'integer', 'to_number']
	assert result.issues[0].path == [types.PathSegment(1)]
	assert support.observe(schema, ['-1', 'bad'], v.Config{ abort_early: true }).issues.len == 1
	nested := v.array(v.array(v.pipe(v.string(), v.min_length(2))))
	assert support.observe(nested, [['a']]).issues[0].path == [types.PathSegment(0), types.PathSegment(0)]
	assert support.observe(schema, []string{}).success
}

fn test_record_and_union() {
	schema := v.record(v.pipe(v.string(), v.to_lower_case()), v.pipe(v.string(), v.trim()))
	assert v.parse(schema, {
		'A': ' hi '
	}) or { panic(err) } == {
		'a': 'hi'
	}
	choice := v.union([v.literal('a'), v.literal('b')])
	assert support.accepts(choice, 'a')
	assert !support.accepts(choice, 'c')
	failure := support.observe(choice, 'c')
	assert failure.issues[0].code == 'union'
	assert failure.issues[0].issues.len == 2
	assert support.accepts(v.nan(), math.nan())
	assert !support.accepts(v.nan(), 1.0)
	assert support.accepts(v.picklist([1, 2]), 1)
	assert !support.accepts(v.never[int](), 1)
	assert support.accepts(v.schema[int](), 1)
}
