module unicode

pub enum NormalizeForm {
	nfc
	nfd
	nfkc
	nfkd
}

fn property(r rune, ranges []Range) int {
	mut low := 0
	mut high := ranges.len
	for low < high {
		mid := (low + high) / 2
		range := ranges[mid]
		if int(r) < range.start {
			high = mid
		} else if int(r) > range.end {
			low = mid + 1
		} else {
			return range.value
		}
	}
	return 0
}

pub fn normalize(input string, form NormalizeForm) string {
	compatibility_form := form in [.nfkc, .nfkd]
	mut output := []rune{}
	for r in input.runes() {
		decompose(r, compatibility_form, mut output)
	}
	// Canonical ordering: stable insertion within each combining sequence.
	for i := 1; i < output.len; i++ {
		class := canonical_class[int(output[i])]
		if class == 0 { continue
		 }
		mut j := i
		for j > 0 && canonical_class[int(output[j - 1])] > class {
			output[j], output[j - 1] = output[j - 1], output[j]
			j--
		}
	}
	if form in [.nfc, .nfkc] { output = compose(output) }
	return output.string()
}

fn decompose(r rune, compat bool, mut output []rune) {
	index := int(r) - 0xac00
	if index >= 0 && index < 11172 {
		output << rune(0x1100 + index / 588)
		output << rune(0x1161 + (index % 588) / 28)
		if index % 28 != 0 { output << rune(0x11a7 + index % 28) }
		return
	}
	if decomposition := decompositions[int(r)] {
		if compat || !compatibility[int(r)] {
			for part in decomposition.runes() {
				decompose(part, compat, mut output)
			}
			return
		}
	}
	output << r
}

fn compose(input []rune) []rune {
	if input.len == 0 { return input.clone() }
	mut output := [input[0]]
	mut starter := 0
	mut last_class := canonical_class[int(input[0])]
	for r in input[1..] {
		class := canonical_class[int(r)]
		combined := compose_pair(output[starter], r)
		if combined != 0 && (last_class == 0 || last_class < class) {
			output[starter] = combined
		} else {
			if class == 0 { starter = output.len }
			output << r
			last_class = class
		}
	}
	return output
}

fn compose_pair(a rune, b rune) rune {
	l := int(a) - 0x1100
	v := int(b) - 0x1161
	if l >= 0 && l < 19 && v >= 0 && v < 21 { return rune(0xac00 + (l * 21 + v) * 28) }
	s := int(a) - 0xac00
	t := int(b) - 0x11a7
	if s >= 0 && s < 11172 && s % 28 == 0 && t > 0 && t < 28 { return rune(int(a) + t) }
	return rune(compositions[(u64(a) << 21) | u64(b)])
}
