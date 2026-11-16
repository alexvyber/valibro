module number

import valibro.internal.text as textops
import math
import math.big

pub fn number_from_string(input string) !f64 {
	s := textops.trim(input, true, true)
	if s == '' { return error('Expected a number') }
	if s in ['Infinity', '+Infinity', '-Infinity'] {
		return math.inf(if s.starts_with('-') { -1 } else { 1 })
	}
	if s.len > 2 && s[..2].to_lower() in ['0x', '0o', '0b'] {
		radix := if s[1] in [`x`, `X`] {
			16
		} else if s[1] in [`o`, `O`] {
			8
		} else {
			2
		}
		for b in s[2..].to_lower().bytes() {
			digit := if b >= `0` && b <= `9` {
				int(b - `0`)
			} else if b >= `a` && b <= `f` {
				int(b - `a`) + 10
			} else {
				-1
			}
			if digit < 0 || digit >= radix { return error('Invalid number') }
		}
		integer := big.integer_from_radix(s[2..], u32(radix))!
		decimal := integer.str()
		return decimal_float(decimal)!
	}
	if !decimal_grammar(s) {
		return error('Invalid number')
	}
	return decimal_float(s)!
}

pub fn bigint_from_string(input string) !big.Integer {
	s := textops.trim(input, true, true)
	if s == '' { return error('Expected an integer') }
	if s.len > 2 && s[..2].to_lower() in ['0x', '0o', '0b'] {
		radix := if s[1] in [`x`, `X`] {
			u32(16)
		} else if s[1] in [`o`, `O`] {
			u32(8)
		} else {
			u32(2)
		}
		return big.integer_from_radix(s[2..], radix)
	}
	if !s.trim_left('+-').bytes().all(it >= `0` && it <= `9`)
		|| s.trim_left('+-') == '' || s.trim_left('+-').len < s.len - 1 {
		return error('Invalid bigint')
	}
	return big.integer_from_string(s)
}
