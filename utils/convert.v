module utils

import math
import math.big
import strconv
import time

pub fn number_from_string(input string) !f64 {
	s := trim(input, true, true)
	if s == '' { return 0.0 }
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
		mut value := 0.0
		for b in s[2..].to_lower().bytes() {
			digit := if b >= `0` && b <= `9` {
				int(b - `0`)
			} else if b >= `a` && b <= `f` {
				int(b - `a`) + 10
			} else {
				-1
			}
			if digit < 0 || digit >= radix { return error('Invalid number') }
			value = value * radix + digit
		}
		return value
	}
	if !matches(r'^[+-]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$', s) {
		return error('Invalid number')
	}
	return strconv.atof64(s)
}

pub fn bigint_from_string(input string) !big.Integer {
	s := trim(input, true, true)
	if s == '' { return big.integer_from_int(0) }
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
	if !matches(r'^[+-]?[0-9]+$', s) { return error('Invalid bigint') }
	return big.integer_from_string(s)
}

// ISO 8601 and RFC 2822 are the portable date formats; legacy JS formats vary by runtime.
pub fn date_from_string(input string) !time.Time {
	s := trim(input, true, true)
	if matches(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}(?:[T ].*)?$', s) {
		return time.parse_iso8601(s)
	}
	return time.parse_rfc2822(s)
}
