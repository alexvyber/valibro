module comparison

import math
import valibro.types
import time
import x.json2

pub fn value_equal[T](a T, b T) bool {
	$if T is json2.Any {
		if json_number_value(a) && json_number_value(b) {
			left := a.f64()
			right := b.f64()
			return left == right || (math.is_nan(left) && math.is_nan(right))
		}
		return a == b
	} $else $if T is f32 || T is f64 {
		return a == b || (math.is_nan(f64(a)) && math.is_nan(f64(b)))
	} $else $if T is time.Time {
		return a <= b && a >= b
	} $else {
		return a == b
	}
}

fn json_number_value(value json2.Any) bool {
	return types.is_json_number(value)
}
