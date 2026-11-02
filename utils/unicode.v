module utils

// utf16_length matches JavaScript String.length; astral code points use two units.
pub fn utf16_length(input string) int {
	mut count := 0
	for r in input.runes() {
		count += if r > 0xffff { 2 } else { 1 }
	}
	return count
}

pub fn js_space(r rune) bool {
	return
		r in [rune(9), 10, 11, 12, 13, 32, 0xa0, 0x1680, 0x2028, 0x2029, 0x202f, 0x205f, 0x3000, 0xfeff]
		|| (r >= 0x2000 && r <= 0x200a)
}

pub fn trim(input string, start bool, end bool) string {
	runes := input.runes()
	mut lo := 0
	mut hi := runes.len
	if start {
		for lo < hi && js_space(runes[lo]) {
			lo++
		}
	}
	if end {
		for hi > lo && js_space(runes[hi - 1]) {
			hi--
		}
	}
	return runes[lo..hi].string()
}

pub fn compare_utf16(a string, b string) int {
	// UTF-16 surrogate pairs sort before BMP values >= U+E000.
	mut aa := []int{}
	mut bb := []int{}
	for r in a.runes() {
		if r > 0xffff {
			aa << 0xd800 + ((int(r) - 0x10000) >> 10)
			aa << 0xdc00 + ((int(r) - 0x10000) & 1023)
		} else {
			aa << int(r)
		}
	}
	for r in b.runes() {
		if r > 0xffff {
			bb << 0xd800 + ((int(r) - 0x10000) >> 10)
			bb << 0xdc00 + ((int(r) - 0x10000) & 1023)
		} else {
			bb << int(r)
		}
	}
	limit := if aa.len < bb.len { aa.len } else { bb.len }
	for i in 0 .. limit {
		if aa[i] != bb[i] { return if aa[i] < bb[i] { -1 } else { 1 }
		 }
	}
	return if aa.len < bb.len {
		-1
	} else if aa.len > bb.len {
		1
	} else {
		0
	}
}
