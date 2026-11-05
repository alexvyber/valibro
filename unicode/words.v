module unicode

// word_boundaries returns rune indices for default UAX #29 boundaries.
// Empty input returns [0]. No locale or dictionary tailoring is applied.
pub fn word_boundaries(input string) []int {
	runes := input.runes()
	mut result := [0]
	for i := 1; i < runes.len; i++ {
		if word_break(runes, i) { result << i }
	}
	if runes.len > 0 { result << runes.len }
	return result
}

// word_count counts default word segments containing a Unicode letter or number.
// Locale/dictionary tailoring is deliberately excluded.
pub fn word_count(input string) int {
	runes := input.runes()
	boundaries := word_boundaries(input)
	mut result := 0
	for i := 0; i + 1 < boundaries.len; i++ {
		for r in runes[boundaries[i]..boundaries[i + 1]] {
			if property(r, wordlike_properties) != 0 {
				result++
				break
			}
		}
	}
	return result
}

fn word_property(r rune) int {
	return property(r, word_properties)
}

fn previous_word(runes []rune, index int) int {
	mut i := index
	for i >= 0 && word_property(runes[i]) in [4, 5, 7] {
		i--
	}
	return i
}

fn next_word(runes []rune, index int) int {
	mut i := index
	for i < runes.len && word_property(runes[i]) in [4, 5, 7] {
		i++
	}
	return i
}

fn ah(p int) bool {
	return p in [9, 10]
}

fn word_break(runes []rune, i int) bool {
	immediate_a := word_property(runes[i - 1])
	b := word_property(runes[i])
	if immediate_a == 1 && b == 2 { return false }
	if immediate_a in [1, 2, 3] || b in [1, 2, 3] { return true }
	if immediate_a == 5 && property(runes[i], extended_pictographic_properties) != 0 { return false }
	if immediate_a == 18 && b == 18 { return false }
	if b in [4, 5, 7] { return false }
	left := previous_word(runes, i - 1)
	if left < 0 { return true }
	a := word_property(runes[left])
	previous := previous_word(runes, left - 1)
	next := next_word(runes, i + 1)
	prev := if previous >= 0 { word_property(runes[previous]) } else { 0 }
	after := if next < runes.len { word_property(runes[next]) } else { 0 }
	if ah(a) && ah(b) { return false }
	if ah(a) && b in [11, 13, 14] && ah(after) { return false }
	if ah(prev) && a in [11, 13, 14] && ah(b) { return false }
	if a == 9 && b == 11 { return false }
	if a == 9 && b == 12 && after == 9 { return false }
	if prev == 9 && a == 12 && b == 9 { return false }
	if a == 16 && b == 16 { return false }
	if (ah(a) && b == 16) || (a == 16 && ah(b)) { return false }
	if prev == 16 && a in [11, 13, 15] && b == 16 { return false }
	if a == 16 && b in [11, 13, 15] && after == 16 { return false }
	if a == 8 && b == 8 { return false }
	if (ah(a) || a in [8, 16, 17]) && b == 17 { return false }
	if a == 17 && (ah(b) || b in [8, 16]) { return false }
	if a == 6 && b == 6 {
		mut count := 0
		mut j := left
		for j >= 0 && word_property(runes[j]) == 6 {
			count++
			j = previous_word(runes, j - 1)
		}
		if count % 2 == 1 { return false }
	}
	return true
}
