module support

import valibro.internal.coercion as impl_coercion
import math
import valibro.json as j
import x.json2

// Oracle-only rendering: compare numeric values against checked-in Valibot
// observations without requiring production code to use JavaScript spelling.
pub fn reference_number_string(input f64) string {
	if math.is_nan(input) { return 'NaN' }
	if math.is_inf(input, 1) { return 'Infinity' }
	if math.is_inf(input, -1) { return '-Infinity' }
	if input == 0 { return '0' }
	raw := math.abs(input).str().to_lower()
	parts := raw.split('e')
	mantissa := parts[0]
	exponent := if parts.len > 1 { parts[1].int() } else { 0 }
	mut position := (mantissa.index('.') or { mantissa.len }) + exponent
	mut digits := mantissa.replace('.', '')
	for digits.len > 1 && digits[0] == `0` {
		digits = digits[1..]
		position--
	}
	for digits.len > 1 && digits.ends_with('0') {
		digits = digits[..digits.len - 1]
	}
	sign := if input < 0 { '-' } else { '' }
	if position > 0 && position <= 21 {
		if position >= digits.len { return sign + digits + '0'.repeat(position - digits.len) }
		return sign + digits[..position] + '.' + digits[position..]
	}
	if position <= 0 && position > -6 { return sign + '0.' + '0'.repeat(-position) + digits }
	power := position - 1
	fraction := if digits.len > 1 { '.' + digits[1..] } else { '' }
	return sign + digits[..1] + fraction + 'e' + (if power >= 0 {
		'+'
	} else {
		''
	}) + power.str()
}

pub fn reference_string[T](input T) string {
	$if T is f32 || T is f64 {
		return reference_number_string(f64(input))
	} $else $if T is json2.Any {
		if input is f64 { return reference_number_string(input) }
		if input is f32 { return reference_number_string(f64(input)) }
		return impl_coercion.json_string(input) or { panic(err) }
	} $else {
		return impl_coercion.native_string[T](input)
	}
}

// JSON object order and numeric spelling are not part of cross-language equality.
pub fn equal_json_text(actual string, expected string) bool {
	if actual == expected { return true }
	a := json2.decode[json2.Any](actual) or { return false }
	b := json2.decode[json2.Any](expected) or { return false }
	return j.equal(a, b)
}

pub fn reference_units(input string) []u16 {
	mut output := []u16{}
	for r in input.runes() {
		if r > 0xffff {
			value := u32(r) - 0x10000
			output << u16(0xd800 + (value >> 10))
			output << u16(0xdc00 + (value & 1023))
		} else {
			output << u16(r)
		}
	}
	return output
}
