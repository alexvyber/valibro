module number

import math

pub fn native_number_string(input f64) string {
	if math.is_nan(input) { return 'NaN' }
	if math.is_inf(input, 1) { return 'Infinity' }
	if math.is_inf(input, -1) { return '-Infinity' }
	text := input.str()
	return if text.ends_with('.0') { text[..text.len - 2] } else { text }
}

// V and ECMAScript share shortest round-trip digits but choose different
// fixed/exponential notation thresholds and exponent padding.
pub fn javascript_number_string(input f64) string {
	if input == 0 { return '0' }
	if math.is_nan(input) || math.is_inf(input, 0) { return native_number_string(input) }
	text := input.str().to_lower()
	sign := if text.starts_with('-') { '-' } else { '' }
	unsigned := text.trim_left('-')
	parts := unsigned.split('e')
	mantissa := parts[0]
	exponent := if parts.len == 2 { parts[1].int() } else { 0 }
	point := mantissa.index('.') or { mantissa.len }
	position := point + exponent
	mut digits := mantissa.replace('.', '').trim_right('0')
	if digits == '' { return '0' }
	// Fixed native strings below one may contain leading zeroes.
	mut adjusted_position := position
	for digits.len > 1 && digits[0] == `0` {
		digits = digits[1..]
		adjusted_position--
	}
	if adjusted_position > 0 && adjusted_position <= 21 {
		if digits.len <= adjusted_position {
			return sign + digits + '0'.repeat(adjusted_position - digits.len)
		}
		return sign + digits[..adjusted_position] + '.' + digits[adjusted_position..]
	}
	if adjusted_position <= 0 && adjusted_position > -6 {
		return sign + '0.' + '0'.repeat(-adjusted_position) + digits
	}
	power := adjusted_position - 1
	coefficient := digits[..1] + if digits.len > 1 { '.' + digits[1..] } else { '' }
	return sign + coefficient + 'e' + if power >= 0 {
		'+' + power.str()
	} else {
		power.str()
	}
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
