module unicode

pub fn to_upper(input string) string {
	mut output := []string{}
	for r in input.runes() {
		output << upper_mappings[int(r)] or { r.str() }
	}
	return output.join('')
}

pub fn to_lower(input string) string {
	runes := input.runes()
	mut output := []string{}
	for i, r in runes {
		if r == 0x03a3 && final_sigma(runes, i) {
			output << 'ς'
		} else {
			output << lower_mappings[int(r)] or { r.str() }
		}
	}
	return output.join('')
}

fn final_sigma(input []rune, index int) bool {
	mut before := false
	for j := index - 1; j >= 0; j-- {
		if property(input[j], case_ignorable_properties) != 0 { continue
		 }
		before = property(input[j], cased_properties) != 0
		break
	}
	if !before { return false }
	for j := index + 1; j < input.len; j++ {
		if property(input[j], case_ignorable_properties) != 0 { continue
		 }
		return property(input[j], cased_properties) == 0
	}
	return true
}
