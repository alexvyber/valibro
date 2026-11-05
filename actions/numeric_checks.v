module actions

import valibro.internal.coercion as coerce
import math
import valibro.internal.number as numbers
import math.big
import valibro.types

pub fn finite(messages ...types.ErrorMessage) types.Action[f64] {
	return value_predicate[f64]('finite', 'finite number', fn (input f64) bool {
		return !math.is_nan(input) && !math.is_inf(input, 0)
	}, messages)
}

pub fn integer(messages ...types.ErrorMessage) types.Action[f64] {
	return value_predicate[f64]('integer', 'integer', fn (input f64) bool {
		return !math.is_nan(input) && !math.is_inf(input, 0) && math.trunc(input) == input
	}, messages)
}

pub fn binary64_integer(messages ...types.ErrorMessage) types.Action[f64] {
	return value_predicate[f64]('safe_integer', 'safe integer', fn (input f64) bool {
		return !math.is_nan(input) && !math.is_inf(input, 0) && math.trunc(input) == input
			&& input >= -9007199254740991.0 && input <= 9007199254740991.0
	}, messages)
}

pub fn finite_of[T](messages ...types.ErrorMessage) types.Action[T] {
	return value_predicate[T]('finite', 'finite number', fn [T](input T) bool {
		$if T is f32 || T is f64 {
			return !math.is_nan(f64(input)) && !math.is_inf(f64(input), 0)
		} $else $if T is i8 || T is i16 || T is int || T is i32 || T is i64 || T is u8 || T is u16
			|| T is u32 || T is u64 || T is isize || T is usize {
			return true
		} $else {
			$compile_error('finite_of requires a native numeric type')
		}
	}, messages)
}

pub fn integer_of[T](messages ...types.ErrorMessage) types.Action[T] {
	return value_predicate[T]('integer', 'integer', fn [T](input T) bool {
		$if T is f32 || T is f64 {
			return !math.is_nan(f64(input)) && !math.is_inf(f64(input), 0)
				&& math.trunc(f64(input)) == f64(input)
		} $else $if T is i8 || T is i16 || T is int || T is i32 || T is i64 || T is u8 || T is u16
			|| T is u32 || T is u64 || T is isize || T is usize {
			return true
		} $else {
			$compile_error('integer_of requires a native numeric type')
		}
	}, messages)
}

pub fn binary64_integer_of[T](messages ...types.ErrorMessage) types.Action[T] {
	return value_predicate[T]('safe_integer', 'safe integer', fn [T](input T) bool {
		$if T is i64 || T is isize {
			return i64(input) >= i64(-9007199254740991) && i64(input) <= i64(9007199254740991)
		} $else $if T is u64 || T is usize {
			return u64(input) <= u64(9007199254740991)
		} $else $if T is f32 || T is f64 {
			return !math.is_nan(f64(input)) && !math.is_inf(f64(input), 0)
				&& math.trunc(f64(input)) == f64(input) && f64(input) >= -9007199254740991.0
				&& f64(input) <= 9007199254740991.0
		} $else $if T is i8 || T is i16 || T is int || T is i32 || T is u8 || T is u16 || T is u32 {
			return true
		} $else {
			$compile_error('safe_integer_of requires a native numeric type')
		}
	}, messages)
}

pub fn multiple_of[T](requirement T, messages ...types.ErrorMessage) types.Action[T] {
	$if T is f32 || T is f64 || T is big.Integer || T is i8 || T is i16 || T is i32 || T is int
		|| T is i64 || T is u8 || T is u16 || T is u32 || T is u64 || T is isize || T is usize {
	} $else {
		$compile_error('multiple_of requires a builtin numeric type or big.Integer')
	}
	modulo := numbers.remainder
	text := custom_message(messages, '')
	expected := '%' + coerce.native_string(requirement)
	return types.Action[T]{
		kind:      .validation
		type_name: 'multiple_of'
		run:       fn [requirement, text, expected, modulo] [T](input T) types.Dataset[T] {
			mut valid := false
			$if T is f32 || T is f64 {
				if requirement != 0 && !math.is_nan(f64(requirement)) && !math.is_nan(f64(input))
					&& !math.is_inf(f64(input), 0) {
					valid = modulo(f64(input), f64(requirement)) == 0
				}
			} $else $if T is big.Integer {
				if requirement == big.integer_from_int(0) { return types.Dataset[T]{
						typed:     false
						exception: types.RangeError{
							message: 'Division by zero'
						}
					} }
				valid = input % requirement == big.integer_from_int(0)
			} $else {
				$if T is i8 || T is i16 || T is i32 || T is int || T is i64 || T is isize {
					if requirement == T(-1) { return types.Dataset[T]{
							value: input
						} }
				}
				if requirement != 0 { valid = input % requirement == 0 }
			}
			if valid { return types.Dataset[T]{
					value: input
				} }
			received := coerce.native_string(input)
			resolved_message := if text is types.DefaultMessage { types.ErrorMessage(types.DefaultMessage{
					text: 'Invalid multiple: Expected ' + expected + ' but received ' + received
				}) } else { text }
			return types.Dataset[T]{
				value:  input
				issues: [
					types.new_issue('multiple_of', resolved_message, expected, received,

						'Invalid multiple: Expected ' + expected + ' but received ' + received),
				]
			}
		}
	}
}
