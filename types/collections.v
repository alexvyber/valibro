module types

import math
import x.json2

pub interface Countable {
	count() int
}

// Set preserves insertion order; floats use SameValueZero (including NaN).
pub struct Set[T] {
pub:
	values []T
}

pub fn new_set[T](values []T) Set[T] {
	mut output := []T{}
	for value in values {
		mut found := false
		for existing in output {
			if native_set_equal[T](value, existing) { found = true }
			if found { break
			 }
		}
		if !found {
			$if T is json2.Any {
				if value is f64 && value == 0 {
					output << json2.Any(0.0)
				} else if value is f32 && value == 0 {
					output << json2.Any(f32(0))
				} else {
					output << value
				}
			} $else $if T is f32 || T is f64 {
				output << if value == 0 { T(0) } else { value }
			} $else {
				output << value
			}
		}
	}
	return Set[T]{
		values: output
	}
}

pub fn (s Set[T]) count() int {
	return s.values.len
}

pub struct Blob {
pub:
	data      []u8
	mime_type string
}

pub fn (b Blob) count() int {
	return b.data.len
}

pub struct File {
pub:
	data          []u8
	mime_type     string
	name          string
	last_modified i64
}

pub fn (f File) count() int {
	return f.data.len
}

pub fn is_json_number(value json2.Any) bool {
	return value is i8 || value is i16 || value is i32 || value is int || value is i64
		|| value is u8 || value is u16 || value is u32 || value is u64 || value is f32
		|| value is f64
}

// Shared by typed collections and boxed partial outputs.
pub fn native_set_equal[T](left T, right T) bool {
	$if T is $pointer {
		// V retains a pointee comparison helper across generic instantiations.
		$if T.pointee_type is $sumtype {
			return left == right
		} $else {
			return left == right
		}
	} $else $if T is json2.Any {
		if is_json_number(left) && is_json_number(right) {
			return json_number_equal(left, right)
		}
		return left == right
	} $else $if T is f32 || T is f64 {
		both_nan := math.is_nan(f64(left)) && math.is_nan(f64(right))
		return left == right || both_nan
	} $else {
		return left == right
	}
}
