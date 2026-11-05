module valibro_test

import valibro.tests.support
import math
import math.big
import valibro as v
import valibro.types

fn test_number_multiple_of_zero_nan_and_infinity_are_execution_checks() {
	for divisor in [0.0, -0.0, math.nan()] {
		action := v.multiple_of(divisor)
		for input in [0.0, 1.0, -1.0, math.inf(1)] {
			result := support.observe(v.pipe(v.number(), action), input)
			assert !result.success
			assert result.issues[0].code == 'multiple_of'
		}
	}
	for divisor in [math.inf(1), math.inf(-1)] {
		schema := v.pipe(v.number(), v.multiple_of(divisor))
		assert support.observe(schema, 0.0).success
		assert support.observe(schema, -0.0).success
		assert !support.observe(schema, 1.0).success
	}
	assert !support.observe(v.pipe(v.number_of[int](), v.multiple_of(0)), 0).success
	issue := support.observe(v.pipe(v.number(), v.multiple_of(0.0)), 1.0).issues[0]
	assert issue.message == 'Invalid multiple: Expected %0 but received 1'
}

fn test_bigint_division_by_zero_propagates_as_range_error() {
	mut exceptions := 0
	zero := big.integer_from_int(0)
	schema := v.pipe(v.bigint(), v.multiple_of(zero))
	dataset := schema.run(zero, v.Config{})
	assert dataset.issues.len == 0
	exception := dataset.exception or { panic('Expected execution exception') }
	assert exception is types.RangeError
	v.parse(schema, zero) or {
		assert err is types.RangeError
		exceptions++
		assert exceptions > 0
	}
	v.inspect(schema, zero) or {
		assert err is types.RangeError
		exceptions++
		assert exceptions > 0
	}
	v.parse(v.fallback(schema, big.integer_from_int(9)), zero) or {
		assert err is types.RangeError
		exceptions++
		assert exceptions > 0
	}
	v.parse(v.array(schema), [zero]) or {
		assert err is types.RangeError
		exceptions++
		assert exceptions > 0
	}
	assert exceptions == 4
}

fn test_set_float_membership_uses_same_value_zero() {
	values := types.new_set([math.nan(), math.nan(), 0.0, -0.0, 1.0, 1.0])
	assert values.count() == 3
	assert math.is_nan(values.values[0])
	assert values.values[1] == 0
	assert values.values[2] == 1
}

fn test_set_canonicalizes_negative_zero() {
	values := types.new_set([-0.0, 0.0])
	assert values.count() == 1
	assert !math.signbit(values.values[0])
}
