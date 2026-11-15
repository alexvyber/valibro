module text

import encoding.utf8

pub fn trim(input string, start bool, end bool) string {
	runes := input.runes()
	mut lo := 0
	mut hi := runes.len
	if start {
		for lo < hi && utf8.is_space(runes[lo]) {
			lo++
		}
	}
	if end {
		for hi > lo && utf8.is_space(runes[hi - 1]) {
			hi--
		}
	}
	return runes[lo..hi].string()
}

// ECMAScript WhiteSpace and LineTerminator sets used by String.trim.
fn js_space(value rune) bool {
	return
		value in [rune(0x0009), 0x000a, 0x000b, 0x000c, 0x000d, 0x0020, 0x00a0, 0x1680, 0x2028, 0x2029, 0x202f, 0x205f, 0x3000, 0xfeff]
		|| (value >= 0x2000 && value <= 0x200a)
}

pub fn utf16_length(input string) int {
	mut length := 0
	for point in input.runes() {
		length += if point > 0xffff { 2 } else { 1 }
	}
	return length
}

pub fn js_trim(input string, start bool, end bool) string {
	points := input.runes()
	mut lo := 0
	mut hi := points.len
	if start {
		for lo < hi && js_space(points[lo]) {
			lo++
		}
	}
	if end {
		for hi > lo && js_space(points[hi - 1]) {
			hi--
		}
	}
	return points[lo..hi].string()
}
