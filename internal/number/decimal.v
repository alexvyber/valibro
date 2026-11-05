module number

import math
import math.big

// Parse a validated decimal as an exact rational, then round once to binary64.
// Quotient/remainder rounding handles ties-to-even, subnormals and overflow
// without relying on the host C library or V's approximate decimal parser.
fn decimal_float(input string) !f64 {
	negative := input.starts_with('-')
	unsigned := input.trim_left('+-')
	parts := unsigned.to_lower().split('e')
	mantissa := parts[0]
	mut exponent := 0
	if parts.len > 1 {
		exponent_text := parts[1]
		limit := input.len + 1000
		for digit in exponent_text.trim_left('+-').bytes() {
			exponent = if exponent >= limit / 10 { limit } else { exponent * 10 + int(digit - `0`) }
		}
		if exponent_text.starts_with('-') { exponent = -exponent }
	}
	point := mantissa.index('.') or { mantissa.len }
	fraction := if point < mantissa.len { mantissa.len - point - 1 } else { 0 }
	mut digits := mantissa.replace('.', '').trim_left('0')
	sign := if negative { u64(1) << 63 } else { u64(0) }
	if digits == '' { return math.f64_from_bits(sign) }
	mut scale := exponent - fraction
	for digits.ends_with('0') {
		digits = digits[..digits.len - 1]
		scale++
	}
	adjusted := digits.len - 1 + scale
	if adjusted > 308 { return math.f64_from_bits(sign | (u64(0x7ff) << 52)) }
	if adjusted < -324 { return math.f64_from_bits(sign) }
	mut numerator := big.integer_from_string(digits)!
	mut denominator := big.integer_from_int(1)
	ten := big.integer_from_int(10)
	if scale >= 0 {
		numerator = numerator * ten.pow(u32(scale))
	} else {
		denominator = ten.pow(u32(-scale))
	}
	mut power := numerator.bit_len() - denominator.bit_len()
	below := if power >= 0 {
		numerator < denominator.left_shift(u32(power))
	} else {
		numerator.left_shift(u32(-power)) < denominator
	}
	if below { power-- }
	shift := if power < -1022 { 1074 } else { 52 - power }
	if shift >= 0 {
		numerator = numerator.left_shift(u32(shift))
	} else {
		denominator = denominator.left_shift(u32(-shift))
	}
	quotient, residual := numerator.div_mod(denominator)
	twice := residual.left_shift(1)
	mut significand := quotient.str().u64()
	if twice > denominator || (twice == denominator && significand & 1 != 0) { significand++ }
	if power < -1022 { return math.f64_from_bits(sign | significand) }
	if significand == u64(1) << 53 {
		significand >>= 1
		power++
	}
	if power > 1023 { return math.f64_from_bits(sign | (u64(0x7ff) << 52)) }
	return math.f64_from_bits(sign | (u64(power + 1023) << 52) | (significand & ((u64(1) << 52) - 1)))
}

// Linear grammar validation avoids regex backtracking limits on long decimals.
fn decimal_grammar(text string) bool {
	mut i := 0
	if text.len > 0 && text[0] in [`+`, `-`] { i++ }
	mut digits := 0
	for i < text.len && text[i] >= `0` && text[i] <= `9` {
		i++
		digits++
	}
	if i < text.len && text[i] == `.` {
		i++
		for i < text.len && text[i] >= `0` && text[i] <= `9` {
			i++
			digits++
		}
	}
	if digits == 0 { return false }
	if i < text.len && text[i] in [`e`, `E`] {
		i++
		if i < text.len && text[i] in [`+`, `-`] { i++ }
		start := i
		for i < text.len && text[i] >= `0` && text[i] <= `9` {
			i++
		}
		if i == start { return false }
	}
	return i == text.len
}
