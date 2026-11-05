module valibro_test

import valibro.tests.support
import valibro as v
import x.json2

struct EmailTag {}

struct UserTag {}

fn test_annotations_survive_composition_and_conversion() {
	base := v.pipe(v.string(), v.title[string]('Email'), v.description[string]('Contact address'), v.examples([
		'a@example.com',
	]), v.metadata[string]({
		'private': json2.Any(true)
	}), v.email())
	assert v.get_title(base) or { panic('Missing title') } == 'Email'
	assert v.get_description(base) or { panic('Missing description') } == 'Contact address'
	assert v.get_examples(base) or { panic('Missing examples') } == ['a@example.com']
	assert v.get_metadata(base)['private'] or { panic('Missing metadata') } == json2.Any(true)
	changed := v.pipe(base, v.title[string]('Primary email'), v.metadata[string]({
		'label': json2.Any('primary')
	}))
	assert v.get_title(changed) or { panic('Missing title') } == 'Primary email'
	assert v.get_title(base) or { panic('Missing title') } == 'Email'
	assert v.get_metadata(changed).len == 2
	assert v.get_metadata(base).len == 1
	assert support.observe(changed, 'a@example.com').success
	assert !support.observe(changed, 'bad').success
	converted := v.pipe_to(base, v.to_boolean())
	assert v.get_title(converted) or { panic('Missing title') } == 'Email'
	assert !(v.parse(converted, 'a@example.com') or { panic(err) })
}
