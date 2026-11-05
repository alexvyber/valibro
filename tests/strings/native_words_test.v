module valibro_test

import valibro.tests.support
import valibro as v
import valibro.unicode

fn test_native_word_actions() {
	inputs := ['', 'hello world', "don't stop!", 'e.g. example.com', '東京に行きます',
		'ภาษาไทย', '你好世界', 'שלום עולם', 'مرحبا بالعالم',
		'नमस्ते दुनिया', 'Straße 42', '🙂 👩🏽‍💻', 'ёж кот',
		'a_b 123.45', 'e\u0301 cafe\u0301', '123', '___', '\u0301', 'カタカナ', 'a\r\nb']
	counts := [0, 2, 2, 2, 7, 7, 4, 2, 2, 2, 2, 0, 2, 2, 2, 1, 0, 0, 1, 2]
	for i, input in inputs {
		count := counts[i]
		assert unicode.word_count(input) == count, input
		assert support.accepts(v.pipe(v.string(), v.words(count)), input), input
		assert support.accepts(v.pipe(v.string(), v.min_words(count), v.max_words(count), v.not_words(
			count + 1)), input), input
		assert !support.accepts(v.pipe(v.string(), v.words(count + 1)), input)
		assert !support.accepts(v.pipe(v.string(), v.min_words(count + 1)), input)
		assert !support.accepts(v.pipe(v.string(), v.max_words(count - 1)), input)
		assert !support.accepts(v.pipe(v.string(), v.not_words(count)), input)
	}
	issue := support.observe(v.pipe(v.string(), v.words(1)), 'hello world').issues[0]
	assert issue.expected == '1'
	assert issue.received == '2'
	assert issue.message == 'Invalid words: Expected 1 but received 2'
	assert support.observe(v.pipe(v.string(), v.words(1, 'custom words')), 'hello world').issues[0].message == 'custom words'
}

fn test_negative_measurements_are_checks_instead_of_factory_errors() {
	for action in [v.length(-1), v.bytes(-1), v.code_points(-1),
		v.graphemes(-1), v.words(-1)] {
		assert !support.observe(v.pipe(v.string(), action), '').success
	}
	for action in [v.min_length(-1), v.min_bytes(-1), v.min_code_points(-1),
		v.min_graphemes(-1), v.min_words(-1)] {
		assert support.observe(v.pipe(v.string(), action), '').success
	}
}
