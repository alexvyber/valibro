module valibro_test

import valibro.tests.support
import valibro.internal.coercion as impl_coercion
import valibro as v
import valibro.types
import x.json2

fn check_native_array[T](input T) {
	number := support.observe(v.pipe_to(v.schema[T](), v.to_number_from[T]()), input)
	assert !number.success
	assert types.value_is[T](number.raw_output)
	assert !support.observe(v.pipe_to(v.schema[T](), v.to_bigint_from[T]()), input).success
	assert !support.observe(v.pipe_to(v.schema[T](), v.to_date_from[T]()), input).success
	assert v.parse(v.pipe_to(v.schema[T](), v.to_string_from[T]()), input) or { panic(err) } == input.str()
}

fn test_native_arrays_require_explicit_scalar_conversions() {
	check_native_array([]int{})
	check_native_array([42])
	check_native_array(['42'])
	check_native_array(['1', '2'])
	check_native_array([[42]])
	fixed := ['42']!
	if _ := impl_coercion.native_number(fixed) { assert false
	 }
	if _ := impl_coercion.native_bigint(fixed) { assert false
	 }
	if _ := impl_coercion.native_date(fixed) { assert false
	 }
	assert impl_coercion.native_string_checked(fixed) or { panic(err) } == fixed.str()
	assert !(impl_coercion.native_boolean([]int{}) or { panic(err) })
	assert impl_coercion.native_boolean([0]) or { panic(err) }
	assert !(impl_coercion.native_boolean(json2.Any([]json2.Any{})) or { panic(err) })
	assert impl_coercion.native_boolean(json2.Any([json2.Any(0)])) or { panic(err) }
}

struct ExplicitArrayHook {
	values []int
}

pub fn (input ExplicitArrayHook) to_number() !f64 {
	return f64(input.values[0])
}

fn test_application_can_supply_explicit_conversion() {
	input := ExplicitArrayHook{[42]}
	assert v.parse(v.pipe_to(v.schema[ExplicitArrayHook](), v.to_number_from[ExplicitArrayHook]()),
		input) or { panic(err) } == 42.0
}
