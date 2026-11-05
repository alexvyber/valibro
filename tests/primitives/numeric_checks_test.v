module valibro_test

import math
import math.big
import time
import valibro as v
import valibro.types

fn test_finite_integer_and_safe_integer_boundaries() {
	finite := v.pipe(v.number(), v.finite())
	integer := v.pipe(v.number(), v.integer())
	safe := v.pipe(v.number(), v.safe_integer())
	for input in [0.0, -0.0, 1.0, -1.0, 9007199254740991.0, -9007199254740991.0] {
		assert v.safe_parse(finite, input).success
		assert v.safe_parse(integer, input).success
		assert v.safe_parse(safe, input).success
	}
	for input in [9007199254740992.0, -9007199254740992.0, 1e100] {
		assert v.safe_parse(finite, input).success
		assert v.safe_parse(integer, input).success
		assert !v.safe_parse(safe, input).success
	}
	for input in [0.5, -1.5, 1e-300] {
		assert v.safe_parse(finite, input).success
		assert !v.safe_parse(integer, input).success
		assert !v.safe_parse(safe, input).success
	}
	for input in [math.inf(1), math.inf(-1)] {
		assert v.safe_parse(finite, input).issues[0].code == 'finite'
		assert v.safe_parse(integer, input).issues[0].code == 'integer'
		assert v.safe_parse(safe, input).issues[0].code == 'safe_integer'
	}
	// Actions are safe even when called outside a number schema.
	for action in [v.finite(), v.integer(), v.safe_integer(),
		v.multiple_of(2.0)] {
		assert action.run(math.nan()).issues.len == 1
	}
}

fn test_numeric_bounds_equality_membership_and_clamps() {
	for action in [v.min_value(5.0), v.max_value(5.0), v.gt_value(4.0),
		v.lt_value(6.0), v.value(5.0), v.not_value(4.0), v.values([4.0, 5.0]),
		v.not_values([4.0])] {
		assert v.safe_parse(v.pipe(v.number(), action), 5.0).success, action.type_name
	}
	for action in [v.min_value(6.0), v.max_value(4.0), v.gt_value(5.0),
		v.lt_value(5.0), v.value(4.0), v.not_value(5.0), v.values([4.0]),
		v.not_values([5.0])] {
		result := v.safe_parse(v.pipe(v.number(), action), 5.0)
		assert !result.success, action.type_name
		assert result.output == none
		assert result.issues[0].code == action.type_name
	}
	assert v.safe_parse(v.pipe(v.number(), v.min_value(math.inf(1))), math.inf(1)).success
	assert !v.safe_parse(v.pipe(v.number(), v.gt_value(math.inf(1))), math.inf(1)).success
	assert !v.safe_parse(v.pipe(v.number(), v.lt_value(0.0)), math.inf(1)).success
	assert !v.safe_parse(v.pipe(v.number(), v.min_value(math.nan())), 5.0).success
	assert !v.safe_parse(v.pipe(v.number(), v.values([]f64{})), 5.0).success
	assert v.safe_parse(v.pipe(v.number(), v.not_values([]f64{})), 5.0).success
	clamp := v.pipe(v.number(), v.to_min_value(0.0), v.to_max_value(10.0))
	for input, expected in {
		-1.0: 0.0
		0.0:  0.0
		5.0:  5.0
		10.0: 10.0
		11.0: 10.0
	} {
		assert v.parse(clamp, input) or { panic(err) } == expected
	}
	assert math.signbit(v.parse(clamp, -0.0) or { panic(err) })
}

fn check_native_numeric_actions[T](input T, lower T, upper T, divisor T) {
	schema := v.pipe(v.number_of[T](), v.min_value(lower), v.max_value(upper), v.gt_value(lower),
		v.lt_value(upper), v.value(input), v.not_value(lower), v.values([input]), v.not_values([
		lower,
	]), v.multiple_of(divisor), v.to_min_value(input), v.to_max_value(input))
	assert v.parse(schema, input) or { panic(err) } == input
	assert !v.safe_parse(v.pipe(v.number_of[T](), v.gt_value(input)), input).success
	assert v.parse(v.pipe(v.number_of[T](), v.to_min_value(input)), lower) or { panic(err) } == input
	assert v.parse(v.pipe(v.number_of[T](), v.to_max_value(input)), upper) or { panic(err) } == input
}

fn test_native_numeric_actions_without_precision_loss() {
	check_native_numeric_actions[i8](4, 2, 6, 2)
	check_native_numeric_actions[i16](4, 2, 6, 2)
	check_native_numeric_actions[i32](4, 2, 6, 2)
	check_native_numeric_actions[int](4, 2, 6, 2)
	check_native_numeric_actions[i64](9007199254740994, 9007199254740993, 9007199254740995, 2)
	check_native_numeric_actions[u8](4, 2, 6, 2)
	check_native_numeric_actions[u16](4, 2, 6, 2)
	check_native_numeric_actions[u32](4, 2, 6, 2)
	check_native_numeric_actions[u64](18446744073709551614, 18446744073709551613,
		18446744073709551615, 2)
	check_native_numeric_actions[f32](4, 2, 6, 2)
	check_native_numeric_actions[f64](4, 2, 6, 2)
	for action in [v.multiple_of(i64(-1)), v.multiple_of(i64(2))] {
		assert v.safe_parse(v.pipe(v.number_of[i64](), action), i64(-9223372036854775807 - 1)).success
	}
	assert v.safe_parse(v.pipe(v.number_of[int](), v.multiple_of(-1)), -2147483647 - 1).success
}

fn test_multiples_use_exact_float_remainders() {
	schema := v.pipe(v.number(), v.multiple_of(0.5))
	for input in [0.0, -0.0, 0.5, -0.5, 1.5] {
		assert v.safe_parse(schema, input).success
	}
	for input in [0.25, -0.25, math.inf(1), math.inf(-1)] {
		assert !v.safe_parse(schema, input).success
	}
	assert v.safe_parse(v.pipe(v.number(), v.multiple_of(-2.0)), -4.0).success
	// No epsilon: decimal fractions have normal IEEE-754 remainder behavior.
	assert !v.safe_parse(v.pipe(v.number(), v.multiple_of(0.1)), 0.3).success
	assert !v.safe_parse(v.pipe(v.number_of[int](), v.multiple_of(2)), 3).success
}

fn test_bigint_ordering_multiples_and_clamps() {
	base := big.integer_from_string('123456789012345678901234567890') or { panic(err) }
	one := big.integer_from_int(1)
	lower := base - one
	upper := base + one
	schema := v.pipe(v.bigint(), v.min_value(base), v.max_value(base), v.gt_value(lower),
		v.lt_value(upper), v.value(base), v.not_value(lower), v.values([base]), v.not_values([
		lower,
	]), v.multiple_of(big.integer_from_int(10)))
	assert v.parse(schema, base) or { panic(err) } == base
	assert !v.safe_parse(schema, lower).success
	assert v.safe_parse(v.pipe(v.bigint(), v.multiple_of(big.integer_from_int(-10))), base.neg()).success
	assert v.parse(v.pipe(v.bigint(), v.to_min_value(base)), lower) or { panic(err) } == base
	assert v.parse(v.pipe(v.bigint(), v.to_max_value(base)), upper) or { panic(err) } == base
	assert v.safe_parse(v.pipe(v.bigint(), v.multiple_of(one)), big.integer_from_int(0)).success
}

fn test_date_bounds_and_clamps_include_nanoseconds() {
	base := time.unix_nanosecond(1700000000, 500)
	lower := time.unix_nanosecond(1700000000, 499)
	upper := time.unix_nanosecond(1700000000, 501)
	schema := v.pipe(v.date(), v.min_value(base), v.max_value(base), v.gt_value(lower),
		v.lt_value(upper), v.value(base), v.values([base]))
	assert v.safe_parse(schema, base).success
	assert !v.safe_parse(schema, lower).success
	assert !v.safe_parse(schema, upper).success
	assert v.parse(v.pipe(v.date(), v.to_min_value(base)), lower) or { panic(err) } == base
	assert v.parse(v.pipe(v.date(), v.to_max_value(base)), upper) or { panic(err) } == base
}

fn test_numeric_error_messages_collection_and_conversion_composition() {
	schema := v.pipe(v.number(), v.integer(), v.multiple_of(2.0))
	result := v.safe_parse(schema, 3.5)
	assert result.output == none
	assert result.issues.map(it.code) == ['integer', 'multiple_of']
	assert v.safe_parse_with_config(schema, 3.5, v.Config{ abort_early: true }).issues.len == 1
	assert v.safe_parse(v.pipe(v.number(), v.integer('Whole numbers only')), 1.5).issues[0].message == 'Whole numbers only'
	dynamic := v.pipe(v.number(), v.min_value(10.0, v.message_fn(fn (issue v.Issue) string {
		return '${issue.code}: ${issue.expected} / ${issue.received}'
	})))
	issue := v.safe_parse(dynamic, 5.0).issues[0]
	assert issue.message == 'min_value: ${issue.expected} / ${issue.received}'
	assert issue.expected == '>=10'
	assert issue.received == '5'
	assert v.safe_parse(v.pipe(v.number(), v.message(v.finite(), 'Finite only')), math.inf(1)).issues[0].message == 'Finite only'
	converted := v.pipe(v.pipe_to(v.string(), v.to_number()), v.finite(), v.integer(),
		v.min_value(1.0), v.max_value(100.0))
	assert v.parse(converted, '42') or { panic(err) } == 42.0
	assert !v.safe_parse(converted, 'Infinity').success
	assert !v.safe_parse(converted, '1.5').success
	assert !v.safe_parse(converted, '0').success
	stopped := v.pipe(v.number(), v.integer(), v.transform(fn (input f64) f64 {
		panic('Transform ran after invalid integer')
	}), v.max_value(0.0))
	assert v.safe_parse(stopped, 1.5).issues.map(it.code) == ['integer']
	v.parse(schema, 3.5) or {
		assert err is types.ValidationError
		if err is types.ValidationError { assert err.issues.len == 2
		 }
		return
	}
	assert false, 'Expected validation error'
}

fn test_nan_value_membership_and_literal_semantics() {
	schema := v.nan()
	assert v.is_valid(v.pipe(schema, v.value(math.nan())), math.nan())
	assert !v.is_valid(v.pipe(schema, v.not_value(math.nan())), math.nan())
	assert v.is_valid(v.pipe(schema, v.values([math.nan(), 1.0])), math.nan())
	assert !v.is_valid(v.pipe(schema, v.not_values([math.nan()])), math.nan())
	assert v.is_valid(v.literal(math.nan()), math.nan())
	assert v.is_valid(v.picklist([math.nan(), 1.0]), math.nan())
}
