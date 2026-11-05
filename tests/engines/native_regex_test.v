module valibro_test

import valibro as v

fn test_native_regex_search_groups_and_unicode() {
	regexp := v.compile_regex(r'(?P<word>[a-z]+)', '') or { panic(err) }
	found := regexp.find('--hello--') or { panic('missing match') }
	assert found.text == 'hello'
	assert found.start == 2 && found.end == 7
	assert found.groups == ['hello']
	assert v.is_valid(v.pipe(v.string(), v.regex(r'^[а-яё]+$')), 'ёж')
	assert v.is_valid(v.pipe(v.string(), v.regex('^.$')), '🙂')
	assert !v.is_valid(v.pipe(v.string(), v.regex('^..$')), '🙂')
}

fn test_native_regex_flags_and_inline_modifiers() {
	assert v.is_valid(v.pipe(v.string(), v.regex_with_flags('^[a-z]+$', 'i')), 'ABC')
	assert v.is_valid(v.pipe(v.string(), v.regex('(?i)^[a-z]+$')), 'ABC')
	assert v.is_valid(v.pipe(v.string(), v.regex_with_flags('a.b', 's')), 'a\nb')
	assert !v.is_valid(v.pipe(v.string(), v.regex('a.b')), 'a\nb')
	assert v.is_valid(v.pipe(v.string(), v.regex_with_flags('^b$', 'm')), 'a\nb\nc')
}

fn test_native_regex_rejects_unsupported_flags_and_constructs() {
	invalid := [u8(0xff)].bytestr()
	if _ := v.compile_regex(invalid, '') { assert false, 'Invalid UTF-8 pattern accepted'
	 }
	for flags in ['g', 'y', 'u', 'v', 'd', 'z', 'ii', 'mm', 'ss', 'ig'] {
		if _ := v.compile_regex('a', flags) { assert false, flags
		 }
	}
	for pattern in [r'(?=a)', r'(?<=a)b', r'(a)\1', r'\p{Letter}', r'\u{1f600}', '['] {
		if _ := v.compile_regex(pattern, '') { assert false, pattern
		 }
	}
}

fn test_precompiled_native_regex_has_independent_matches() {
	compiled := v.compile_regex('a', '') or { panic(err) }
	first := v.pipe(v.string(), v.regex_object(compiled))
	second := v.pipe(v.string(), v.regex_object(compiled))
	for _ in 0 .. 10 {
		assert v.is_valid(first, 'aba')
		assert v.is_valid(second, 'aba')
		assert !v.is_valid(first, 'bbb')
		assert v.is_valid(first, 'a')
	}
}

fn test_native_regex_strict_anchors_and_messages() {
	schema := v.pipe(v.string(), v.regex('^a$'))
	assert v.is_valid(schema, 'a')
	assert !v.is_valid(schema, 'a\n')
	assert !v.is_valid(schema, 'a\r\n')
	result := v.safe_parse(schema, 'b')
	assert result.issues[0].code == 'regex'
	assert result.issues[0].expected == '/^a$/'
	assert result.issues[0].received == '"b"'
	assert result.issues[0].message == 'Invalid format: Expected /^a$/ but received "b"'
	assert v.safe_parse(v.pipe(v.string(), v.regex('a', 'Custom')), 'b').issues[0].message == 'Custom'
}

fn test_builtin_formats_use_native_predicates_and_ascii_classes() {
	assert v.is_valid(v.pipe(v.string(), v.base64()), 'Zm8=')
	assert !v.is_valid(v.pipe(v.string(), v.base64()), 'dmFſaWJvdA==')
	assert !v.is_valid(v.pipe(v.string(), v.base64()), 'Km8=')
	assert !v.is_valid(v.pipe(v.string(), v.base64()), 'Zm8=\n')
	assert v.is_valid(v.pipe(v.string(), v.bic()), 'DEUTDEFF')
	assert !v.is_valid(v.pipe(v.string(), v.bic()), 'DEUTDE00')
	assert v.is_valid(v.pipe(v.string(), v.domain()), 'example.com')
	assert !v.is_valid(v.pipe(v.string(), v.domain()), 'xn--bcher-kva.example')
	assert !v.is_valid(v.pipe(v.string(), v.domain()), 'example.com\n')
	assert v.is_valid(v.pipe(v.string(), v.emoji()), '👩🏽‍💻')
	assert !v.is_valid(v.pipe(v.string(), v.emoji()), 'hello')
}
