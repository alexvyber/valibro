module text

import valibro.unicode

// Case boundaries follow Valibot's acronym/digit rules with full Unicode casing.
pub fn format_case(input string, separator string, cap_first bool, cap_rest bool) string {
	runes := input.runes()
	mut words := []string{}
	mut start := 0
	mut prev := 0
	mut prev_prev := 0
	for i, r in runes {
		mut kind := 3
		if r in [rune(32), 9, 10, 11, 12, 13, 45, 95] {
			if i > start { words << runes[start..i].string() }
			start = i + 1
			kind = 0
		} else {
			ch := r.str()
			lower := unicode.to_lower(ch)
			upper := unicode.to_upper(ch)
			kind = if lower == upper {
				3
			} else if ch == lower {
				2
			} else {
				1
			}
		}
		if kind == 1 && (prev == 2 || prev == 3) && i > start {
			words << runes[start..i].string()
			start = i
		} else if kind == 2 && prev == 1 && prev_prev == 1 && i - 1 > start {
			words << runes[start..i - 1].string()
			start = i - 1
		}
		prev_prev = prev
		prev = kind
	}
	if runes.len > start { words << runes[start..].string() }
	for i, word in words {
		lower := unicode.to_lower(word)
		if (i == 0 && cap_first) || (i > 0 && cap_rest) {
			chars := lower.runes()
			words[i] = unicode.to_upper(chars[0].str()) + chars[1..].string()
		} else {
			words[i] = lower
		}
	}
	return words.join(separator)
}
