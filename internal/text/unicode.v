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
