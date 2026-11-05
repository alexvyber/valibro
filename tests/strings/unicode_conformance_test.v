module valibro_test

import valibro.unicode as u
import os
import strconv

fn unicode_sequence(input string) string {
	mut runes := []rune{}
	for cp in input.trim_space().fields() {
		runes << rune(strconv.parse_int(cp, 16, 32) or { panic(err) })
	}
	return runes.string()
}

fn test_unicode_normalization_conformance() {
	data := os.read_file(os.join_path(@VMODROOT, 'tests', 'fixtures', 'unicode',
		'NormalizationTest.txt')) or { panic(err) }
	mut count := 0
	for line in data.split_into_lines() {
		text := line.all_before('#').trim_space()
		if text == '' || text.starts_with('@') { continue
		 }
		fields := text.split(';')
		mut c := []string{}
		for i := 0; i < 5; i++ {
			c << unicode_sequence(fields[i])
		}
		for i := 0; i < 5; i++ {
			assert u.normalize(c[i], .nfc) == if i < 3 {
				c[1]
			} else {
				c[3]
			}, 'NFC ${text}'
			assert u.normalize(c[i], .nfd) == if i < 3 {
				c[2]
			} else {
				c[4]
			}, 'NFD ${text}'
			assert u.normalize(c[i], .nfkc) == c[3], 'NFKC ${text}'
			assert u.normalize(c[i], .nfkd) == c[4], 'NFKD ${text}'
		}
		count++
	}
	assert count > 19000
}

fn check_break_conformance(filename string, graphemes bool) {
	data := os.read_file(os.join_path(@VMODROOT, 'tests', 'fixtures', 'unicode', filename)) or {
		panic(err)
	}
	mut count := 0
	for line in data.split_into_lines() {
		text := line.all_before('#').trim_space()
		if text == '' { continue
		 }
		mut runes := []rune{}
		mut expected := []int{}
		for token in text.fields() {
			if token == '÷' {
				expected << runes.len
			} else if token != '×' {
				runes << rune(strconv.parse_int(token, 16, 32) or { panic(err) })
			}
		}
		actual := if graphemes {
			u.grapheme_boundaries(runes.string())
		} else {
			u.word_boundaries(runes.string())
		}
		assert actual == expected, '${filename}: ${text} got ${actual} expected ${expected}'
		count++
	}
	assert count > 500
}

fn test_unicode_grapheme_conformance() {
	check_break_conformance('auxiliary_GraphemeBreakTest.txt', true)
}

fn test_unicode_word_conformance() {
	check_break_conformance('auxiliary_WordBreakTest.txt', false)
}
