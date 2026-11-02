module utils

pub fn ascii_alnum(b u8) bool {
	return (b >= `a` && b <= `z`) || (b >= `A` && b <= `Z`) || (b >= `0` && b <= `9`)
}

// DNS-style ASCII host names; Punycode is configurable for URL hosts.
pub fn valid_hostname(input string, allow_punycode bool) bool {
	if input.len == 0 || input.len > 253 { return false }
	for label in input.split('.') {
		if label.len == 0 || label.len > 63 { return false }
		if !ascii_alnum(label[0]) || !ascii_alnum(label[label.len - 1]) { return false }
		if !allow_punycode && label.to_lower().starts_with('xn--') { return false }
		for b in label.bytes() {
			if !ascii_alnum(b) && b != `-` { return false }
		}
	}
	return true
}

pub fn valid_domain(input string) bool {
	if !valid_hostname(input, false) { return false }
	labels := input.split('.')
	if labels.len < 2 { return false }
	tld := labels[labels.len - 1]
	if tld.len < 2 { return false }
	for b in tld.bytes() {
		if !(b >= `a` && b <= `z`) && !(b >= `A` && b <= `Z`) { return false }
	}
	return true
}

pub fn valid_bic(input string) bool {
	if input.len !in [8, 11] { return false }
	for b in input[..6].bytes() {
		if b < `A` || b > `Z` { return false }
	}
	if input[6..8] == '00' { return false }
	for b in input[6..].bytes() {
		if !(b >= `A` && b <= `Z`) && !(b >= `0` && b <= `9`) { return false }
	}
	return true
}

fn ascii_hex(b u8) bool {
	return (b >= `0` && b <= `9`) || (b >= `a` && b <= `f`) || (b >= `A` && b <= `F`)
}
