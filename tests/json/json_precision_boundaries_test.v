module valibro_test

import valibro.tests.support
import math
import valibro as v
import valibro.json as j
import valibro.types
import x.json2

struct JsonNumericEqualityCase {
	left  json2.Any
	right json2.Any
	equal bool
}

fn test_json_numeric_equality_preserves_integer_precision_and_float_boundaries() {
	cases := [
		JsonNumericEqualityCase{json2.Any(i64(9007199254740992)), json2.Any(i64(9007199254740993)), false},
		JsonNumericEqualityCase{json2.Any(u64(9007199254740992)), json2.Any(u64(9007199254740993)), false},
		JsonNumericEqualityCase{json2.Any(i64(9007199254740993)), json2.Any(9007199254740992.0), false},
		JsonNumericEqualityCase{json2.Any(i64(9007199254740992)), json2.Any(9007199254740992.0), true},
		JsonNumericEqualityCase{json2.Any(i64(9223372036854775807)), json2.Any(9223372036854775808.0), false},
		JsonNumericEqualityCase{json2.Any(i64(-9223372036854775807 - 1)), json2.Any(-9223372036854775808.0), true},
		JsonNumericEqualityCase{json2.Any(u64(9223372036854775808)), json2.Any(9223372036854775808.0), true},
		JsonNumericEqualityCase{json2.Any(u64(18446744073709551615)), json2.Any(18446744073709551616.0), false},
		JsonNumericEqualityCase{json2.Any(u64(18446744073709551615)), json2.Any(i64(-1)), false},
		JsonNumericEqualityCase{json2.Any(u64(9223372036854775807)), json2.Any(i64(9223372036854775807)), true},
		JsonNumericEqualityCase{json2.Any(0), json2.Any(-0.0), true},
		JsonNumericEqualityCase{json2.Any(0), json2.Any(math.f64_from_bits(1)), false},
		JsonNumericEqualityCase{json2.Any(1), json2.Any(1.5), false},
		JsonNumericEqualityCase{json2.Any(-1), json2.Any(-1.5), false},
		JsonNumericEqualityCase{json2.Any(u64(1)), json2.Any(-1.0), false},
		JsonNumericEqualityCase{json2.Any(0), json2.Any(math.inf(1)), false},
		JsonNumericEqualityCase{json2.Any(0), json2.Any(math.inf(-1)), false},
		JsonNumericEqualityCase{json2.Any(0), json2.Any(math.nan()), false},
		JsonNumericEqualityCase{json2.Any(math.inf(1)), json2.Any(math.inf(1)), true},
		JsonNumericEqualityCase{json2.Any(math.inf(1)), json2.Any(math.inf(-1)), false},
		JsonNumericEqualityCase{json2.Any(f32(16777216)), json2.Any(16777216), true},
		JsonNumericEqualityCase{json2.Any(f32(16777216)), json2.Any(16777217), false},
		JsonNumericEqualityCase{json2.Any(f32(0.5)), json2.Any(0.5), true},
	]
	for item in cases {
		assert j.equal(item.left, item.right) == item.equal, '${item}'
		assert j.equal(item.right, item.left) == item.equal, '${item}'
		assert types.native_set_equal(item.left, item.right) == item.equal, '${item}'
		assert types.native_set_equal(item.right, item.left) == item.equal, '${item}'
		assert support.accepts(v.literal(item.left), item.right) == item.equal, '${item}'
	}
	widths := [json2.Any(i8(42)), json2.Any(i16(42)), json2.Any(i32(42)), json2.Any(int(42)),
		json2.Any(i64(42)), json2.Any(u8(42)), json2.Any(u16(42)), json2.Any(u32(42)), json2.Any(u64(42)),
		json2.Any(f32(42)), json2.Any(f64(42))]
	for left in widths {
		for right in widths {
			assert j.equal(left, right)
			assert types.native_set_equal(left, right)
		}
	}
	assert !j.equal(json2.Any(math.nan()), json2.Any(math.nan()))
	assert types.native_set_equal(json2.Any(math.nan()), json2.Any(math.nan()))
	assert types.native_set_equal(json2.Any(f32(math.nan())), json2.Any(math.nan()))
	assert !j.equal(json2.Any(true), json2.Any(1))
	assert !j.equal(json2.Any('42'), json2.Any(42))
}

fn test_large_json_integers_remain_distinct_in_schemas_sets_and_nested_values() {
	left := json2.Any(i64(9007199254740992))
	right := json2.Any(i64(9007199254740993))
	assert !support.observe_json(j.literal(left), right).success
	assert !support.observe_json(j.picklist([left]), right).success
	assert !support.accepts(v.pipe(v.schema[json2.Any](), v.values([left])), right)
	assert !support.accepts(v.pipe(v.array(v.schema[json2.Any]()), v.includes_item(left)), [
		right,
	])
	assert types.new_set([left, right, left, right]).values == [left, right]
	assert types.new_set([json2.Any(i64(-1)), json2.Any(u64(18446744073709551615))]).values.len == 2
	assert !j.equal(json2.Any({
		'value': left
	}), json2.Any({
		'value': right
	}))
	assert !j.equal(json2.Any([left]), json2.Any([right]))
	assert j.equal(json2.Any({
		'value': json2.Any(42)
	}), json2.Any({
		'value': json2.Any(42.0)
	}))
	intersection := j.intersect([
		j.from_schema(v.pipe_to(v.schema[json2.Any](), v.transform_to[json2.Any, json2.Any](fn (input json2.Any) json2.Any {
			return json2.Any(i64(9007199254740992))
		}))),
		j.from_schema(v.pipe_to(v.schema[json2.Any](), v.transform_to[json2.Any, json2.Any](fn (input json2.Any) json2.Any {
			return json2.Any(i64(9007199254740993))
		}))),
	])
	assert !support.observe_json(intersection, json2.Any(0)).success
}

fn test_json_object_schemas_reject_arrays_and_other_non_objects() {
	fields := {
		'0': j.literal(json2.Any('tag'))
	}
	schemas := [j.object(fields), j.strict_object(fields), j.loose_object(fields),
		j.object_with_rest(fields, j.unknown()), j.record(j.string(), j.unknown()),
		j.variant('0', [j.object(fields)])]
	invalid := [json2.Any([]json2.Any{}), json2.Any([json2.Any('tag')]), json2.Any(json2.Null{}),
		json2.Any('tag'), json2.Any(0), json2.Any(true)]
	for schema in schemas {
		assert support.observe_json(schema, json2.Any({
			'0': json2.Any('tag')
		})).success
		for input in invalid {
			result := support.observe_json(schema, input)
			assert !result.success, '${schema.type_name}: ${input}'
			assert !result.typed
			assert result.exception == none
			assert result.issues.len == 1
			assert result.issues[0].code == schema.type_name
			assert result.issues[0].expected == 'Object'
			assert result.issues[0].path.len == 0
		}
	}
	assert support.observe_json(j.object(map[string]j.Schema{}), json2.Any(map[string]json2.Any{})).success
	assert !support.observe_json(j.object(map[string]j.Schema{}), json2.Any([]json2.Any{})).success
	nested := support.observe_json(j.object({
		'child': j.object(fields)
	}), json2.Any({
		'child': json2.Any([json2.Any('tag')])
	}))
	assert !nested.success
	assert nested.issues[0].path == [types.PathSegment('child')]
}

fn test_json_parse_text_uses_exact_float_rounding_at_every_depth() {
	for text, bits in {
		'1e23':                                                    u64(4950912855330343670)
		'9007199254740993.0':                                      u64(4845873199050653696)
		'1.00000000000000011102230246251565404236316680908203125': u64(4607182418800017408)
		'1.00000000000000011102230246251565404236316680908203126': u64(4607182418800017409)
		'4.9406564584124654e-324':                                 u64(1)
		'2.4703282292062327e-324':                                 u64(0)
		'2.4703282292062328e-324':                                 u64(1)
		'-0.0':                                                    u64(9223372036854775808)
		'-1e-9999':                                                u64(9223372036854775808)
	} {
		unknown := j.parse_text(j.unknown(), text) or { panic(err) }
		assert math.f64_bits(unknown.f64()) == bits, text
		number := j.parse_text(j.number(), text) or { panic(err) }
		assert math.f64_bits(number.f64()) == bits, text
		nested := j.parse_text(j.object({
			'values': j.array(j.number())
		}), '{"values":[${text}]}') or { panic(err) }
		values := nested.as_map()['values'] or { panic('values') }
		assert math.f64_bits(values.as_array()[0].f64()) == bits, text
	}
	for text in ['01', 'NaN', 'Infinity', '1 trailing', '{"values":[1,]}'] {
		if _ := j.parse_text(j.unknown(), text) {
			assert false, 'Invalid JSON accepted: ${text}'
		}
	}
}

fn test_object_boundary_failures_compose_with_collections_alternatives_and_fallbacks() {
	object := j.object(map[string]j.Schema{})
	input := json2.Any([]json2.Any{})
	for abort_early in [false, true] {
		for abort_pipe_early in [false, true] {
			config := v.Config{
				abort_early:      abort_early
				abort_pipe_early: abort_pipe_early
			}
			for schema in [j.array(object), j.tuple([object])] {
				result := support.observe_json(schema, json2.Any([input]), config)
				assert !result.success
				assert result.issues.len == 1
				assert result.issues[0].code == 'object'
				assert result.issues[0].path == [types.PathSegment(0)]
			}
			choice := support.observe_json(j.union([object, j.array(j.string())]), input, config)
			assert choice.success
			assert choice.output or { panic('output') } == input
			fallback := json2.Any({
				'fallback': json2.Any(true)
			})
			assert support.observe_json(j.fallback(object, fallback), input, config).output or {
				panic('output')
			} == fallback
			intersection := support.observe_json(j.intersect([object, object]), input, config)
			assert !intersection.success
			assert intersection.issues.len == if abort_early {
				1
			} else {
				2
			}
		}
	}
}

struct JsonBoundaryCalls {
mut:
	values []json2.Any
}

fn test_partial_checks_observe_raw_array_boundary_failure_and_respect_readiness() {
	for abort_early in [false, true] {
		for abort_pipe_early in [false, true] {
			for paths in [[][]types.PathSegment{}, [[]types.PathSegment{}],
				[[types.PathSegment('value')]]] {
				mut calls := &JsonBoundaryCalls{}
				object := j.object({
					'value': j.string()
				})
				schema := j.partial_check(object, paths, fn [mut calls] (input json2.Any) bool {
					calls.values << input
					return false
				})
				input := json2.Any([]json2.Any{})
				result := support.observe_json(schema, input, v.Config{
					abort_early:      abort_early
					abort_pipe_early: abort_pipe_early
				})
				assert !result.success
				assert result.issues[0].expected == 'Object'
				assert result.issues[0].received == 'Array'
				should_call := paths.len == 0 && !abort_early && !abort_pipe_early
				assert calls.values.len == if should_call {
					1
				} else {
					0
				}
				assert result.issues.len == if should_call {
					2
				} else {
					1
				}
				if should_call { assert calls.values[0] == input
				 }
			}
		}
	}
}
