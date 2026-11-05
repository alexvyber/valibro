module schemas

import math
import valibro.types

// number uses f64, matching the output of to_number.
pub fn number(messages ...types.ErrorMessage) types.Schema[f64, f64] {
	return number_of[f64](...messages)
}

// number_of preserves a native numeric type without converting through f64.
pub fn number_of[T](messages ...types.ErrorMessage) types.Schema[T, T] {
	$if T is i8 || T is i16 || T is i32 || T is int || T is i64 || T is u8 || T is u16 || T is u32
		|| T is u64 || T is isize || T is usize || T is f32 || T is f64 {
	} $else {
		$compile_error('number_of requires a builtin integer or floating-point type')
	}
	text := schema_message(messages, 'Expected a number other than NaN')
	return types.Schema[T, T]{
		type_name: 'number'
		expects:   'number'
		message:   text
		run:       fn [text] [T](input T, config types.Config) types.Dataset[T] {
			$if T is f32 || T is f64 {
				if math.is_nan(f64(input)) {
					return types.Dataset[T]{
						typed:  false
						value:  input
						issues: [
							types.schema_type_issue('number', text, 'number', 'NaN', 'type'),
						]
					}
				}
			}
			return types.Dataset[T]{
				value: input
			}
		}
	}
}
