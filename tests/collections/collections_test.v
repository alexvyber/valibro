module valibro_test

import valibro as v
import valibro.types
import math

fn test_array_transforms_and_nested_paths() {
	schema := v.array(v.pipe(v.pipe_to(v.string(), v.to_number()), v.integer(), v.min_value(0.0)))
	assert v.parse(schema, ['1', '2']) or { panic(err) } == [1.0, 2.0]
	result := v.safe_parse(schema, ['1', '-2', '3.5', 'bad'])
	assert !result.success
	assert result.issues.map(it.code) == ['min_value', 'integer', 'to_number']
	assert result.issues[0].path == [types.PathSegment(1)]
	assert v.safe_parse_with_config(schema, ['-1', 'bad'], v.Config{ abort_early: true }).issues.len == 1
	nested := v.array(v.array(v.pipe(v.string(), v.min_length(2))))
	assert v.safe_parse(nested, [['a']]).issues[0].path == [types.PathSegment(0), types.PathSegment(0)]
	assert v.safe_parse(schema, []string{}).success
}

fn test_record_and_union() {
	schema := v.record(v.pipe(v.string(), v.to_lower_case()), v.pipe(v.string(), v.trim()))
	assert v.parse(schema, {
		'A': ' hi '
	}) or { panic(err) } == {
		'a': 'hi'
	}
	choice := v.union([v.literal('a'), v.literal('b')])
	assert v.is_valid(choice, 'a')
	assert !v.is_valid(choice, 'c')
	failure := v.safe_parse(choice, 'c')
	assert failure.issues[0].code == 'union'
	assert failure.issues[0].issues.len == 2
	assert v.is_valid(v.nan(), math.nan())
	assert !v.is_valid(v.nan(), 1.0)
	assert v.is_valid(v.picklist([1, 2]), 1)
	assert !v.is_valid(v.never[int](), 1)
	assert v.is_valid(v.any_value[int](), 1)
}

fn test_maybe_semantics_and_defaults() {
	schema := v.optional(v.pipe(v.string(), v.trim()))
	assert v.parse(schema, types.some(' hi ')) or { panic(err) } == types.some('hi')
	assert v.is_valid(schema, types.missing[string]())
	assert v.is_valid(schema, types.undefined_value[string]())
	assert !v.is_valid(schema, types.null_value[string]())
	assert !v.is_valid(v.exact_optional(v.string()), types.undefined_value[string]())
	assert v.is_valid(v.nullable(v.string()), types.null_value[string]())
	assert !v.is_valid(v.nullable(v.string()), types.missing[string]())
	assert v.is_valid(v.nullish(v.string()), types.null_value[string]())
	assert v.parse(v.optional(v.pipe(v.string(), v.trim()), ' hi '), types.missing[string]()) or {
		panic(err)
	} == types.some('hi')
	assert !v.is_valid(v.non_optional(v.optional(v.string())), types.missing[string]())
	assert !v.is_valid(v.non_nullable(v.nullable(v.string())), types.null_value[string]())
	assert !v.is_valid(v.non_nullish(v.nullish(v.string())), types.null_value[string]())
}

fn test_convenience_methods_and_forwarding() {
	schema := v.pipe(v.string(), v.min_length(3))
	assert v.parse(v.fallback(schema, 'default'), 'x') or { panic(err) } == 'default'
	parse := v.parser(schema)
	assert parse('abc') or { panic(err) } == 'abc'
	safe := v.safe_parser(schema)
	assert !safe('a').success
	v.assert_valid(schema, 'abc') or { panic(err) }
	result := v.safe_parse(v.pipe(v.string(), v.forward(v.min_length(3), [
		types.PathSegment('user'),
		types.PathSegment(0),
	])), 'x')
	assert v.get_dot_path(result.issues[0]) == 'user.0'
	assert v.flatten(result.issues).nested['user.0'].len == 1
	assert v.summarize(result.issues).contains('user.0')
}

fn test_collection_measurements_and_item_actions() {
	schema := v.pipe(v.array(v.string()), v.min_length_of[[]string](1),
		v.max_length_of[[]string](3), v.includes_item('a'), v.excludes_item('b'))
	assert v.is_valid(schema, ['a'])
	assert !v.is_valid(schema, []string{})
	assert !v.is_valid(schema, ['a', 'b'])
	assert v.is_valid(v.pipe(v.record(v.string(), v.string()), v.entries[map[string]string](1)), {
		'a': 'b'
	})
	mapped := v.pipe_to(v.array(v.number_of[int]()), v.map_items(fn (x int, index int) string {
		return '${index}:${x}'
	}))
	assert v.parse(mapped, [2, 3]) or { panic(err) } == ['0:2', '1:3']
	even := fn (x int, index int) bool {
		return x % 2 == 0
	}
	items := v.array(v.number_of[int]())
	assert v.parse(v.pipe(items, v.filter_items(even)), [1, 2, 3, 4]) or { panic(err) } == [
		2,
		4,
	]
	assert v.is_valid(v.pipe(items, v.every_item(even)), [2, 4])
	assert !v.is_valid(v.pipe(items, v.every_item(even)), [2, 3])
	assert v.is_valid(v.pipe(items, v.some_item(even)), [1, 2])
	assert !v.is_valid(v.pipe(items, v.some_item(even)), []int{})
	checks := v.safe_parse(v.pipe(items, v.check_items(even)), [1, 2, 3])
	assert checks.issues.len == 2
	assert checks.issues[1].path == [types.PathSegment(2)]
	found := v.parse(v.pipe_to(items, v.find_item(even)), [1, 2, 4]) or { panic(err) }
	assert found == types.some(2)
	assert (v.parse(v.pipe_to(items, v.find_item(even)), [1, 3]) or { panic(err) }).state == .undefined
	sum := v.pipe_to(items, v.reduce_items(fn (total int, item int, index int) int {
		return total + item
	}, 0))
	assert v.parse(sum, [1, 2, 3]) or { panic(err) } == 6
	sorted := v.pipe(items, v.sort_items(fn (a int, b int) int {
		return if a < b {
			-1
		} else if a > b {
			1
		} else {
			0
		}
	}))
	original := [3, 1, 2, 1]
	assert v.parse(sorted, original) or { panic(err) } == [1, 1, 2, 3]
	assert original == [3, 1, 2, 1]
}
