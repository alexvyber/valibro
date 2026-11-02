module valibro_test

import valibro as v
import x.json2

struct EmailTag {}

struct UserTag {}

fn test_annotations_survive_composition_and_conversion() {
	base := v.pipe(v.string(), v.title('Email'), v.description('Contact address'), v.examples([
		'a@example.com',
	]), v.metadata({
		'private': json2.Any(true)
	}), v.email())
	assert v.get_title(base) or { panic('Missing title') } == 'Email'
	assert v.get_description(base) or { panic('Missing description') } == 'Contact address'
	assert v.get_examples(base) or { panic('Missing examples') } == ['a@example.com']
	assert v.get_metadata(base)['private'] or { panic('Missing metadata') } == json2.Any(true)
	changed := v.pipe(base, v.title('Primary email'), v.metadata({
		'label': json2.Any('primary')
	}))
	assert v.get_title(changed) or { panic('Missing title') } == 'Primary email'
	assert v.get_title(base) or { panic('Missing title') } == 'Email'
	assert v.get_metadata(changed).len == 2
	assert v.get_metadata(base).len == 1
	assert v.safe_parse(changed, 'a@example.com').success
	assert !v.safe_parse(changed, 'bad').success
	converted := v.pipe_to(base, v.to_boolean())
	assert v.get_title(converted) or { panic('Missing title') } == 'Email'
	assert v.parse(converted, 'a@example.com') or { panic(err) }
}

fn test_brands_flavors_and_readonly() {
	email := v.pipe_to(v.pipe(v.string(), v.email()), v.brand[EmailTag]())
	value := v.parse(email, 'a@example.com') or { panic(err) }
	assert value.value == 'a@example.com'
	assert !v.safe_parse(email, 'bad').success
	user := v.pipe_to(v.string(), v.flavor[UserTag]())
	flavored := v.parse(user, 'alex') or { panic(err) }
	assert flavored.value == 'alex'
	assert v.parse(v.pipe(v.string(), v.readonly()), 'abc') or { panic(err) } == 'abc'
}
