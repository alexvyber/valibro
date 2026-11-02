module utils

pub fn luhn(input string) bool {
	mut sum := 0
	mut double := false
	for i := input.len - 1; i >= 0; i-- {
		if input[i] < `0` || input[i] > `9` { continue
		 }
		mut digit := int(input[i] - `0`)
		if double {
			digit *= 2
			if digit > 9 { digit -= 9 }
		}
		sum += digit
		double = !double
	}
	return sum % 10 == 0
}

pub fn valid_isbn(input string) bool {
	s := input.replace('-', '').replace(' ', '')
	if matches(r'^[0-9]{9}[0-9X]$', s) {
		mut sum := 0
		for i, b in s.bytes() {
			sum += (10 - i) * if b == `X` { 10 } else { int(b - `0`) }
		}
		return sum % 11 == 0
	}
	if matches(r'^[0-9]{13}$', s) {
		mut sum := 0
		for i, b in s.bytes() {
			sum += int(b - `0`) * if i % 2 == 0 { 1 } else { 3 }
		}
		return sum % 10 == 0
	}
	return false
}

pub fn valid_credit_card(input string) bool {
	if !matches(r'^(?:[0-9]{13,19}|[0-9]{4}(?: [0-9]{3,6}){2,4}|[0-9]{4}(?:-[0-9]{3,6}){2,4})$',
		input) {
		return false
	}
	s := input.replace('-', '').replace(' ', '')
	providers := [r'^3[47][0-9]{13}$', r'^3(?:0[0-5]|[68][0-9])[0-9]{11,13}$',
		r'^6(?:011|5[0-9]{2})[0-9]{12,15}$', r'^(?:2131|1800|35[0-9]{3})[0-9]{11}$',
		r'^(?:5[1-5][0-9]{2}|222[0-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}$',
		r'^(?:6[27][0-9]{14,17}|81[0-9]{14,17})$', r'^4[0-9]{12}(?:[0-9]{3,6})?$']
	for pattern in providers {
		if matches(pattern, s) { return luhn(s) }
	}
	return false
}
