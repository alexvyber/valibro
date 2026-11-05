module comparison

import math.big
import time

pub fn compare_value[T](input T, requirement T, operator string) bool {
	$if T is string || T is i8 || T is i16 || T is i32 || T is int || T is i64 || T is u8
		|| T is u16 || T is u32 || T is u64 || T is isize || T is usize || T is f32 || T is f64
		|| T is big.Integer || T is time.Time {
		return match operator {
			'min_value' { input >= requirement }
			'max_value' { input <= requirement }
			'gt_value' { input > requirement }
			'lt_value' { input < requirement }
			else { false }
		}
	} $else {
		$compile_error('Value ordering requires strings, numbers, big integers, or dates')
	}
}
