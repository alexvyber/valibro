module valibro_test

import valibro.tests.support
import valibro.internal.text as impl_text
import valibro as v

fn test_stdlib_regex_compilation_and_strict_end_anchor() {
	for pattern in [r'\p{Letter}', r'\z', r'(a)\1', r'(?=a)', '['] {
		impl_text.compile_pattern(pattern) or { continue }
		assert false, 'Unsupported regex was accepted: ${pattern}'
	}
	schema := v.pipe(v.string(), v.regex(r'^[a-z]+$'))
	assert support.observe(schema, 'abc').success
	assert !support.observe(schema, 'abc\n').success
	assert !support.observe(schema, 'abc\u0000').success
	// Compiled schema use does not share a previous call's match state.
	assert !support.observe(schema, '123').success
	assert support.observe(schema, 'abc').success
}
