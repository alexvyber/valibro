module number

import math

pub fn native_number_string(input f64) string {
	if math.is_nan(input) { return 'NaN' }
	if math.is_inf(input, 1) { return 'Infinity' }
	if math.is_inf(input, -1) { return '-Infinity' }
	text := input.str()
	return if text.ends_with('.0') { text[..text.len - 2] } else { text }
}

// Non-generic wrapper keeps V 0.5.2's closure specialization from omitting fmod.
pub fn remainder(input f64, divisor f64) f64 {
	return math.fmod(input, divisor)
}

// Preserve f32's own shortest representation instead of widening it to f64.
pub fn native_f32_string(input f32) string {
	if math.is_nan(f64(input)) { return 'NaN' }
	if math.is_inf(f64(input), 1) { return 'Infinity' }
	if math.is_inf(f64(input), -1) { return '-Infinity' }
	text := input.str()
	return if text.ends_with('.0') { text[..text.len - 2] } else { text }
}
