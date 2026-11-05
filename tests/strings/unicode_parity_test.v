module valibro_test

import os
import x.json2
import valibro as v
import valibro.unicode as u

fn test_upstream_full_casing_and_emoji_fixtures() {
	data := os.read_file(os.join_path(@VMODROOT, 'tests', 'fixtures', 'strings/unicode_parity.json')) or {
		panic(err)
	}
	document := (json2.decode[json2.Any](data) or { panic(err) }).as_map()
	rows := (document['rows'] or { panic('rows') }).as_array()
	for row in rows {
		sample := row.as_map()
		input := (sample['input'] or { panic('input') }).str()
		assert u.to_lower(input) == (sample['lower'] or { panic('lower') }).str(), input
		assert u.to_upper(input) == (sample['upper'] or { panic('upper') }).str(), input
		assert u.is_emoji(input) == (sample['emoji'] or { panic('emoji') }).bool(), input
	}
}

fn test_unicode_pipeline_actions() {
	assert v.parse(v.pipe(v.string(), v.normalize(.nfkc)), 'ＡＢＣ ① ﬁ') or { panic(err) } == 'ABC 1 fi'
	assert v.is_valid(v.pipe(v.string(), v.graphemes(1)), '👩🏽‍💻')
	assert v.is_valid(v.pipe(v.string(), v.min_graphemes(1), v.max_graphemes(1), v.not_graphemes(2)),
		'e\u0301')
	assert v.is_valid(v.pipe(v.string(), v.words(2)), "don't stop!")
	assert v.is_valid(v.pipe(v.string(), v.min_words(1), v.max_words(2), v.not_words(3)),
		'hello world')
	assert v.is_valid(v.pipe(v.string(), v.emoji()), '👨‍👩‍👧‍👦')
	assert !v.is_valid(v.pipe(v.string(), v.emoji()), 'hello')
}

fn test_upstream_contextual_case_formats() {
	data := os.read_file(os.join_path(@VMODROOT, 'tests', 'fixtures',
		'strings/case_format_parity.json')) or { panic(err) }
	rows := (json2.decode[json2.Any](data) or { panic(err) }).as_array()
	camel := v.pipe(v.string(), v.to_camel_case())
	pascal := v.pipe(v.string(), v.to_pascal_case())
	kebab := v.pipe(v.string(), v.to_kebab_case())
	snake := v.pipe(v.string(), v.to_snake_case())
	for row in rows {
		sample := row.as_map()
		input := (sample['input'] or { panic('input') }).str()
		assert v.parse(camel, input) or { panic(err) } == (sample['camel'] or { panic('camel') }).str(), input
		assert v.parse(pascal, input) or { panic(err) } == (sample['pascal'] or { panic('pascal') }).str(), input
		assert v.parse(kebab, input) or { panic(err) } == (sample['kebab'] or { panic('kebab') }).str(), input
		assert v.parse(snake, input) or { panic(err) } == (sample['snake'] or { panic('snake') }).str(), input
	}
}
