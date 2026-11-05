module valibro_test

import valibro.tests.support
import valibro as v
import valibro.types

fn test_literal_membership_and_comparisons() {
	for action in [v.includes('bc'), v.excludes('z'), v.value('abc'),
		v.not_value('xyz'), v.values(['abc', 'def']), v.not_values(['xyz']),
		v.min_value('abc'), v.max_value('abc'), v.gt_value('abb'),
		v.lt_value('abd')] {
		assert support.observe(v.pipe(v.string(), action), 'abc').success, action.type_name
	}
	for action in [v.includes('z'), v.excludes('bc'), v.value('xyz'),
		v.not_value('abc'), v.values(['xyz']), v.not_values(['abc']),
		v.min_value('abd'), v.max_value('abb'), v.gt_value('abc'),
		v.lt_value('abc')] {
		result := support.observe(v.pipe(v.string(), action), 'abc')
		assert !result.success, action.type_name
		assert result.issues[0].code == action.type_name
	}
	assert support.observe(v.pipe(v.string(), v.empty()), '').success
	assert !support.observe(v.pipe(v.string(), v.empty()), ' ').success
	assert support.observe(v.pipe(v.string(), v.non_empty()), ' ').success
	assert !support.observe(v.pipe(v.string(), v.non_empty()), '').success
	// Valid UTF-8 strings use native V ordering.
	assert support.observe(v.pipe(v.string(), v.gt_value('\ue000')), '🙂').success
	assert support.observe(v.pipe(v.string(), v.includes('')), '').success
	assert !support.observe(v.pipe(v.string(), v.excludes('')), '').success
}

fn test_regex_search_and_flags() {
	schema := v.pipe(v.string(), v.regex_with_flags(r'[a-z]+[0-9]', 'i'))
	assert support.observe(schema, '--ABC1--').success
	assert !support.observe(schema, '123').success
	unicode := v.pipe(v.string(), v.regex(r'^[а-яё]+$'))
	assert support.observe(unicode, 'ёж').success
	assert !support.observe(unicode, '123').success
	assert !support.observe(v.pipe(v.string(), v.regex('x', 'Missing x')), 'y').success
}

fn test_all_hash_algorithms_and_custom_messages() {
	algorithms := [v.HashType.md4, .md5, .sha1, .sha256, .sha384, .sha512, .ripemd128, .ripemd160,
		.tiger128, .tiger160, .tiger192, .crc32, .crc32b, .adler32]
	lengths := [32, 32, 40, 64, 96, 128, 32, 40, 32, 40, 48, 8, 8, 8]
	for i, algorithm in algorithms {
		schema := v.pipe(v.string(), v.hash([algorithm]))
		assert support.observe(schema, 'a'.repeat(lengths[i])).success
		assert !support.observe(schema, 'a'.repeat(lengths[i] + 1)).success
		assert !support.observe(schema, 'g'.repeat(lengths[i])).success
	}
	assert support.observe(v.pipe(v.string(), v.hash([.md5, .sha256])), 'a'.repeat(64)).success
	assert support.observe(v.pipe(v.string(), v.email('Bad email')), 'x').issues[0].message == 'Bad email'
	assert support.observe(v.pipe(v.string(), v.starts_with('x', 'Bad prefix')), 'y').issues[0].message == 'Bad prefix'
	assert support.observe(v.pipe(v.string(), v.min_code_points(3, 'Too short')), 'a').issues[0].message == 'Too short'
}

fn test_custom_actions_and_fatal_guard() {
	schema := v.pipe(v.string(), v.transform(fn (s string) string {
		return s + '!'
	}), v.raw_transform(fn (s string) types.Dataset[string] {
		return types.Dataset[string]{ value: s + '?' }
	}))
	assert v.parse(schema, 'hi') or { panic(err) } == 'hi!?'
	raw := v.pipe(v.string(), v.raw_check(fn (input string) []types.Issue {
		if input == 'ok' { return []types.Issue{} }
		return [
			types.Issue{
				code:    'custom'
				message: 'Invalid'
				path:    [
					types.PathSegment('field'),
				]
			},
		]
	}))
	assert support.observe(raw, 'ok').success
	assert support.observe(raw, 'bad').issues[0].path.len == 1
	guard := v.pipe(v.string(), v.guard(fn (s string) bool {
		return false
	}, 'Guard failed'), v.check(fn (s string) bool {
		panic('Check ran after guard')
	}, 'Unexpected'))
	result := support.observe(guard, 'x')
	assert result.issues.len == 1
	assert result.issues[0].code == 'guard'
}

fn test_invalid_utf8_fails_before_unicode_transforms() {
	input := [u8(0xff)].bytestr()
	result := support.observe(v.pipe(v.string('Malformed'), v.to_upper_case()), input)
	assert !result.success
	assert result.output == none
	assert result.issues[0].code == 'string'
	assert result.issues[0].message == 'Malformed'
}

fn test_issue_aware_messages_and_default_checks() {
	schema := v.pipe(v.string(), v.min_length(3, v.message_fn(fn (issue v.Issue) string {
		return '${issue.code}: wanted ${issue.expected}, got ${issue.received}'
	})))
	result := support.observe(schema, 'a')
	assert result.issues[0].message == 'min_length: wanted >=3, got 1'
	wrapped := v.pipe(v.string(), v.message(v.email(), v.message_fn(fn (issue v.Issue) string {
		return 'Bad ${issue.code}'
	})))
	assert support.observe(wrapped, 'x').issues[0].message == 'Bad email'
	converted := v.pipe_to(v.string(), v.to_number(v.message_fn(fn (issue v.Issue) string {
		return 'Cannot parse ${issue.received}'
	})))
	assert support.observe(converted, 'oops').issues[0].message == 'Cannot parse NaN'
	checked := v.pipe(v.string(), v.check(fn (s string) bool {
		return s != ''
	}))
	assert !support.observe(checked, '').success
}
