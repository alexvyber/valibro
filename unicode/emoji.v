module unicode

// is_emoji implements the same property-based sequence grammar as Valibot's emoji regex.
pub fn is_emoji(input string) bool {
	runes := input.runes()
	if runes.len == 0 { return false }
	mut i := 0
	for i < runes.len {
		if regional(runes[i]) {
			if i + 1 >= runes.len || !regional(runes[i + 1]) { return false }
			i += 2
			continue
		}
		// Subdivision flags: black flag, two tag letters, one to three alphanumeric tags, cancel tag.
		if runes[i] == 0x1f3f4 {
			mut end := i + 1
			for end < runes.len && runes[end] >= 0xe0061 && runes[end] <= 0xe007a {
				end++
			}
			if end >= i + 3 {
				mut j := i + 3
				for j < runes.len && j < i + 6 && ((runes[j] >= 0xe0030 && runes[j] <= 0xe0039)
					|| (runes[j] >= 0xe0061 && runes[j] <= 0xe007a)) {
					j++
				}
				if j > i + 3 && j < runes.len && runes[j] == 0xe007f {
					i = j + 1
					continue
				}
			}
		}
		end := emoji_atom(runes, i)
		if end == i { return false }
		i = end
		for i < runes.len && runes[i] == 0x200d {
			next := emoji_atom(runes, i + 1)
			if next == i + 1 { return false }
			i = next
		}
	}
	return true
}

fn regional(r rune) bool {
	return r >= 0x1f1e6 && r <= 0x1f1ff
}

fn emoji_atom(runes []rune, i int) int {
	if i >= runes.len { return i }
	r := runes[i]
	if property(r, emoji_properties) != 0 && i + 1 < runes.len && runes[i + 1] == 0xfe0f {
		return if i + 2 < runes.len && runes[i + 2] == 0x20e3 { i + 3 } else { i + 2 }
	}
	if property(r, emoji_modifier_base_properties) != 0 {
		return if i + 1 < runes.len && property(runes[i + 1], emoji_modifier_properties) != 0 {
			i + 2
		} else {
			i + 1
		}
	}
	if !regional(r) && property(r, emoji_presentation_properties) != 0 { return i + 1 }
	return i
}
