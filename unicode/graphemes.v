module unicode

// grapheme_boundaries returns rune offsets, including start and end.
pub fn grapheme_boundaries(input string) []int {
	runes := input.runes()
	mut result := [0]
	for i := 1; i < runes.len; i++ {
		if grapheme_break(runes, i) { result << i }
	}
	if runes.len > 0 { result << runes.len }
	return result
}

pub fn grapheme_count(input string) int {
	return grapheme_boundaries(input).len - 1
}

fn grapheme_break(runes []rune, i int) bool {
	a := property(runes[i - 1], grapheme_properties)
	b := property(runes[i], grapheme_properties)
	if a == 1 && b == 2 { return false } // CR LF
	if a in [1, 2, 3] || b in [1, 2, 3] { return true }
	if a == 9 && b in [9, 10, 12, 13] { return false }
	if a in [10, 12] && b in [10, 11] { return false }
	if a in [11, 13] && b == 11 { return false }
	if b in [4, 5, 8] || a == 7 { return false }
	if property(runes[i], indic_properties) == 1 {
		mut linker := false
		mut j := i - 1
		for j >= 0 && property(runes[j], indic_properties) in [2, 3] {
			linker = linker || property(runes[j], indic_properties) == 3
			j--
		}
		if linker && j >= 0 && property(runes[j], indic_properties) == 1 { return false }
	}
	if a == 5 && property(runes[i], extended_pictographic_properties) != 0 {
		mut j := i - 2
		for j >= 0 && property(runes[j], grapheme_properties) == 4 {
			j--
		}
		if j >= 0 && property(runes[j], extended_pictographic_properties) != 0 { return false }
	}
	if a == 6 && b == 6 {
		mut count := 0
		for j := i - 1; j >= 0 && property(runes[j], grapheme_properties) == 6; j-- {
			count++
		}
		if count % 2 == 1 { return false }
	}
	return true
}
