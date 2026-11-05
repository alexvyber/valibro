module comparison

import math
import valibro.types
import time
import x.json2

pub fn value_equal[T](a T, b T) bool {
	$if T is json2.Any {
		if types.is_json_number(a) && types.is_json_number(b) {
			return types.native_set_equal[json2.Any](a, b)
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
