module valibro_test

import math
import math.big
import valibro as v
import valibro.types

fn test_number_multiple_of_zero_nan_and_infinity_are_execution_checks() {
	for divisor in [0.0, -0.0, math.nan()] {
		action := v.multiple_of(divisor)
		for input in [0.0, 1.0, -1.0, math.inf(1)] {
			result := v.safe_parse(v.pipe(v.number(), action), input)
			assert !result.success
			assert result.issues[0].code == 'multiple_of'
		}
	}
	for divisor in [math.inf(1), math.inf(-1)] {
		schema := v.pipe(v.number(), v.multiple_of(divisor))
		assert v.safe_parse(schema, 0.0).success
		assert v.safe_parse(schema, -0.0).success
		assert !v.safe_parse(schema, 1.0).success
	}
	assert !v.safe_parse(v.pipe(v.number_of[int](), v.multiple_of(0)), 0).success
	issue := v.safe_parse(v.pipe(v.number(), v.multiple_of(0.0)), 1.0).issues[0]
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
	v.safe_parse_checked(schema, zero) or {
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
	future := v.parse_async(schema, zero)
	future.await() or {
		assert err is types.RangeError
		exceptions++
		assert exceptions > 0
	}
	future.await() or {
		assert err is types.RangeError
		exceptions++
		assert exceptions > 0
	}
	awaited := v.pipe_to(v.promise[big.Integer](), v.await_future[big.Integer]())
	v.parse(awaited, future) or {
		assert err is types.RangeError
		exceptions++
		assert exceptions > 0
	}
	assert exceptions == 7
}

fn test_awaited_validation_rejections_are_exceptions_not_recoverable_issues() {
	future := v.parse_async(v.pipe(v.string(), v.min_length(5)), 'no')
	awaited := v.pipe_to(v.promise[string](), v.await_future[string]())
	data := awaited.run(future, v.Config{})
	assert data.issues.len == 0
	exception := data.exception or { panic('Expected rejected future') }
	assert exception is types.ValidationError
	v.parse(v.fallback(awaited, 'fallback'), future) or {
		assert err is types.ValidationError
		return
	}
	assert false, 'Fallback must not swallow rejected futures'
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
