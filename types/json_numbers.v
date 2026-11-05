module types

import math
import x.json2

// Compare integer alternatives before any floating conversion. This also keeps
// mixed integer/float membership exact at the signed and unsigned 64-bit limits.
fn json_number_equal(left json2.Any, right json2.Any) bool {
	if left is f32 || left is f64 { return json_float_equal(left.f64(), right) }
	if right is f32 || right is f64 { return json_float_equal(right.f64(), left) }
	left_signed := left is i8 || left is i16 || left is i32 || left is int || left is i64
	right_signed := right is i8 || right is i16 || right is i32 || right is int || right is i64
	if left_signed && right_signed { return left.i64() == right.i64() }
	if !left_signed && !right_signed { return left.u64() == right.u64() }
	signed := if left_signed { left.i64() } else { right.i64() }
	unsigned := if left_signed { right.u64() } else { left.u64() }
	return signed >= 0 && u64(signed) == unsigned
}

fn json_float_equal(value f64, other json2.Any) bool {
	match other {
		f32, f64 {
			other_value := f64(other)
			return value == other_value || (math.is_nan(value) && math.is_nan(other_value))
		}
		i8, i16, i32, int, i64 {
			// The positive endpoint rounds beyond i64.max, so it must be exclusive.
			return value >= -9223372036854775808.0 && value < 9223372036854775808.0
				&& math.trunc(value) == value && i64(value) == i64(other)
		}
		u8, u16, u32, u64 {
			// Check the range before casting: 2^64 is not representable as u64.
			return value >= 0 && value < 18446744073709551616.0 && math.trunc(value) == value
				&& u64(value) == u64(other)
		}
		else {
			return false
		}
	}
}
